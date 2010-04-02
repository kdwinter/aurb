# encoding: utf-8
require File.expand_path('../lib/aurb/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'aurb'
  gem.version     = Aurb::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ['Gigamo']
  gem.email       = ['gigamo@gmail.com']
  gem.homepage    = 'http://github.com/gigamo/aurb'
  gem.summary     = 'An AUR (Arch User Repository) utility'
  gem.description = gem.summary

  gem.rubyforge_project  = 'aurb'

  gem.require_paths      = ['lib']
  gem.executables        = ['aurb']
  gem.default_executable = 'aurb'

  gem.files      = Dir['{bin,lib,test,performance}/**/*', 'LICENSE', 'README.md'] & `git ls-files -z`.split("\0")

  gem.add_runtime_dependency 'yajl-ruby'
  gem.add_runtime_dependency 'thor'
  gem.add_runtime_dependency 'ansi'
  gem.add_runtime_dependency 'archive-tar-minitar'
  gem.add_development_dependency 'shoulda'

  gem.required_rubygems_version = '>= 1.3.6'
end
