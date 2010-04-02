require 'rake'
require 'yard'
require 'yard/rake/yardoc_task'
require File.expand_path('../lib/aurb/version', __FILE__)

task :build do
  system 'gem build aurb.gemspec'
end
 
task :release => :build do
  system "gem push aurb-#{Aurb::VERSION}.gem"
end

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
