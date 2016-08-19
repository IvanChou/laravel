namespace :test do

  desc 'Check syntax error with PHPLint.'
  task :phplint do
    on release_roles :all do
      within release_path do
        next unless fetch(:enable_phplint, false)

        if test('[ -f ./vendor/bin/phplint ]')
          phplint_exec = './vendor/bin/phplint'
        elsif test('[ -f ~/.composer/vendor/bin/phplint ]')
          phplint_exec = '~/.composer/vendor/bin/phplint'
        else
          warn 'command not found: phplint, please install phplint first'
          info '  How to install phplint:'
          info '  composer [global] require overtrue/phplint'
          next
        end

        execute phplint_exec, './', '--exclude=vendor'
      end
    end
  end

  before 'deploy:updated', 'test:phplint'
end