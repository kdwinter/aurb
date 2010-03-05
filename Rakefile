require 'rake'
require 'jeweler'
require 'yard'
require 'yard/rake/yardoc_task'
 
Jeweler::Tasks.new do |gem|
  gem.name = 'aurb'
  gem.summary = %Q{An AUR (Arch User Repository) utility}
  gem.email = 'gigamo@gmail.com'
  gem.homepage = 'http://github.com/gigamo/aurb'
  gem.authors = ['Gigamo']
  
  gem.add_dependency('yajl-ruby')
  gem.add_dependency('thor')
  gem.add_dependency('ansi')
  gem.add_dependency('archive-tar-minitar')
  
  gem.add_development_dependency('shoulda')
end
 
Jeweler::GemcutterTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.ruby_opts << '-rubygems'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end
 
namespace :test do
  Rake::TestTask.new(:units) do |test|
    test.libs << 'test'
    test.ruby_opts << '-rubygems'
    test.pattern = 'test/unit/**/*_test.rb'
    test.verbose = true
  end
end
 
task :default => :test
task :test => :check_dependencies

YARD::Rake::YardocTask.new(:doc) do |t|
  t.options = ['--legacy'] if RUBY_VERSION < '1.9.0'
end 
