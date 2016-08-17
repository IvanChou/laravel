require "capistrano/composer"
require "capistrano/file-permissions"

load File.expand_path("../tasks/laravel.rake", __FILE__)
load File.expand_path("../tasks/php_fpm.rake", __FILE__)
load File.expand_path("../tasks/setup_config.rake", __FILE__)
