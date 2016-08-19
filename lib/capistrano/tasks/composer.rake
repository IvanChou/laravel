namespace :composer do
  desc 'Change the packagist repo to speed composer up'
  task :set_repo do
    unless fetch(:packagist_repo, '').empty?
      invoke 'composer:run', :config, '-g', 'repo.packagist', :composer, fetch(:packagist_repo)
    end
  end

end
