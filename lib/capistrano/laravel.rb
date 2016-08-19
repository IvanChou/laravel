require "capistrano/composer"
require "capistrano/file-permissions"

Dir[File.expand_path('../tasks/*.rake', __FILE__)].each { |file| load file }