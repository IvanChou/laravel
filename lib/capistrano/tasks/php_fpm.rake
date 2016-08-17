namespace :php_fpm do
  %w(start stop status restart reload force-reload).each do |command|
    desc "Commands for #{command} php_fpm"
    task command.to_sym do
      if (fpm = fetch(:php_fpm, 'php5-fpm')).empty?
        warn 'miss setting :php_fpm.'
      else
        on roles(:app), in: :sequence, wait: 1 do
          execute :sudo, "service #{fpm} #{command}"
        end
      end
    end
  end

end
