require 'capistrano/laravel/helpers'

include Comparable
include Capistrano::Laravel::Helpers

namespace :load do
  task :defaults do
    set :laravel_roles, :all
    set :laravel_migrate_roles, :all
    set :laravel_version, 5.1
    set :laravel_dotenv_file, './.env'
    set :laravel_artisan_flags, '--env=production'
    set :laravel_artisan_migrate_flags, '--env=production'
    set :laravel_set_linked_dirs, true
    set :laravel_set_acl_paths, true
    set :laravel_create_linked_acl_paths, true
    set :laravel_server_user, 'www-data'

    # Folders to link between releases
    set :laravel_4_linked_dirs, [
      'app/storage'
    ]
    set :laravel_5_linked_dirs, [
      'storage'
    ]
    set :laravel_5_1_linked_dirs, [
      'storage'
    ]

    # Folders to set permissions on based on laravel version
    set :laravel_4_acl_paths, [
      'app/storage',
      'app/storage/cache',
      'app/storage/logs',
      'app/storage/meta',
      'app/storage/sessions',
      'app/storage/views'
    ]
    set :laravel_5_acl_paths, [
      'storage',
      'storage/app',
      'storage/framework',
      'storage/framework/cache',
      'storage/framework/sessions',
      'storage/framework/views',
      'storage/logs'
    ]
    set :laravel_5_1_acl_paths, [
      'bootstrap/cache',
      'storage',
      'storage/app',
      'storage/framework',
      'storage/framework/cache',
      'storage/framework/sessions',
      'storage/framework/views',
      'storage/logs'
    ]
  end
end

namespace :laravel do
  desc 'Set the ACL for the web user based on Laravel version.'
  task :configure_folders do
    laravel_version = fetch(:laravel_version)
    laravel_linked_dirs = []
    laravel_acl_paths = []
    if laravel_version < 5 # Laravel 4
      laravel_linked_dirs = fetch(:laravel_4_linked_dirs)
      laravel_acl_paths   = fetch(:laravel_4_acl_paths)
    elsif laravel_version < 5.1 # Laravel 5
      laravel_linked_dirs = fetch(:laravel_5_linked_dirs)
      laravel_acl_paths   = fetch(:laravel_5_acl_paths)
    else # Laravel 5.1 or greater
      laravel_linked_dirs = fetch(:laravel_5_1_linked_dirs)
      laravel_acl_paths   = fetch(:laravel_5_1_acl_paths)
    end

    if fetch(:laravel_set_linked_dirs)
      set :linked_dirs, fetch(:linked_dirs, []).push(*laravel_linked_dirs)
    end

    if fetch(:laravel_set_acl_paths)
      set :file_permissions_paths, fetch(:file_permissions_paths, []).push(*laravel_acl_paths)
      set :file_permissions_users, [fetch(:laravel_server_user)]
    end
  end

  desc 'Create missing directories.'
  task :create_linked_acl_paths do
    if fetch(:laravel_create_linked_acl_paths)
      if fetch(:laravel_version) < 5
        laravel_acl_paths = fetch(:laravel_4_acl_paths)
      elsif fetch(:laravel_version) < 5.1
        laravel_acl_paths = fetch(:laravel_5_acl_paths)
      else
        laravel_acl_paths = fetch(:laravel_5_1_acl_paths)
      end

      on roles fetch(:laravel_roles) do
        laravel_acl_paths.each do |path|
          acl_path = release_path.join(path)
          if test("[ ! -e '#{acl_path}' ]")
            execute :mkdir, '-vp', acl_path
          else
            info "#{acl_path} already exists."
          end
        end
      end
    end
  end

  desc 'Upload dotenv file for release.'
  task :upload_dotenv_file do
    if fetch(:laravel_version) >= 5
      on roles fetch(:laravel_roles) do
        unless fetch(:laravel_dotenv_file).empty?
          upload! fetch(:laravel_dotenv_file), "#{release_path}/.env"
        end
      end
    end
  end

  desc 'Execute a provided artisan command'
  task :artisan, :command_name do |_t, args|
    # ask only runs if argument is not provided
    ask(:cmd, 'list')
    command = args[:command_name] || fetch(:cmd)

    on roles fetch(:laravel_roles) do
      within release_path do
        execute :php, :artisan, command, *args.extras, fetch(:laravel_artisan_flags)
      end
    end
    
    # enable task artisan to be ran twice
    Rake::Task['laravel:artisan'].reenable
  end

  desc 'Optimize the configuration'
  task :optimize_config do
    invoke 'laravel:artisan', 'config:cache' if fetch(:laravel_version) >= 5
  end

  desc 'Optimize the routing file'
  task :optimize_route do
    invoke 'laravel:artisan', 'route:cache' if fetch(:laravel_version) >= 5
  end

  desc 'Optimize a Laravel installation for optimimum performance in production.'
  task :optimize_release do
    invoke 'laravel:artisan', :optimize, :'--force'
  end

  desc 'Run migrations against the database using Artisan.'
  task :migrate_db do |_t, args|
    on roles fetch(:laravel_migrate_roles) do
      within release_path do
        execute :php, :artisan, :migrate, *args.extras, fetch(:laravel_artisan_migrate_flags)
      end
    end
  end

  desc 'Rollback migrations against the database using Artisan.'
  task :rollback_db do
    on roles fetch(:laravel_roles) do
      within release_path do
        execute :php, :artisan, 'migrate:rollback', *args.extras, fetch(:laravel_artisan_migrate_flags)
      end
    end
  end

  before 'deploy:starting', 'laravel:configure_folders'
  after 'deploy:symlink:shared', 'laravel:create_linked_acl_paths'
  after 'deploy:symlink:shared', 'deploy:set_permissions:acl'
  after 'deploy:symlink:shared', 'laravel:upload_dotenv_file'
  before 'deploy:updated', 'laravel:optimize_release'
end
