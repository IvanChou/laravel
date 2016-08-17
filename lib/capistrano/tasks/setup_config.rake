namespace :load do
  task :defaults do
    set :server_name, 'localhost'
    set :nginx_user, 'nginx'
    set :bind, "unix:/run/php/#{fetch(:php_fpm, 'php5-fpm')}.sock"
  end
end

namespace :deploy do
  
  def render_template(file)    
      StringIO.new(ERB.new(File.read(file)).result(binding))
  end
  
  def upload_shared
    local_shared_path = 'config/deploy/shared'
    
    files = Dir.entries local_shared_path
    files.shift(2)
    
    files.each do |name|
      local = File.join(local_shared_path, name)
      target = File.join(shared_path, name)
    
      if File.file? local
        if local[-4,4] == '.erb'
          local = render_template local 
          target = target.gsub('.erb', '')
        end
        upload! local, target
        info "copying: #{name} to: #{target}"
        
      elsif File.directory? local
        target = shared_path
        upload! local, target, recursive: true
        info "copying: #{name} to: #{target}"
        
      else
        error "error #{local} not found"
      end
    end
  end

  def upload_config(conf, path)
    if File.exist? "config/templates/#{conf}.erb"
      conf_file = render_template "config/templates/#{conf}.erb"
    elsif File.exist? "config/templates/#{conf}"
      conf_file = "config/templates/#{conf}"
    else
      conf_file = render_template File.expand_path("../../templates/#{conf}.erb", __FILE__)
    end

    tmp_target = "/tmp/#{fetch(:application)}/#{fetch(:full_app_name)}.#{conf}"
    target = File.join(path, "#{fetch(:full_app_name)}.conf")
    upload! conf_file, tmp_target
    execute :sudo, :mv, "-n #{tmp_target} #{target}"
    info "Compile & upload #{conf} to: #{target}"
  end

  desc 'setup config to prepare deploying project.'
  task :setup_config do
    on release_roles :all do
      execute :mkdir, "-p #{shared_path}"

      # compile & upload all the config files
      upload_shared if File.exist? 'config/deploy/shared'

      # Compile & upload nginx config
      upload_config 'nginx.conf', fetch(:nginx_server_path) unless fetch(:nginx_server_path).to_s.empty?

      # Compile & upload php-fpm config
      upload_config 'fpm.conf', fetch(:fpm_pool_path) unless fetch(:fpm_pool_path).to_s.empty?

      # Upload dotenv file to shared path
      if fetch(:laravel_version) >= 5
        unless fetch(:laravel_dotenv_file).empty?
          upload! fetch(:laravel_dotenv_file), "#{shared_path}/.env"
        end
      end

    end
  end
end
