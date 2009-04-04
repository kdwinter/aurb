require 'rake/clean'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = 'aurb'
  s.version = '0.1.1'
  s.date = '2009-04-04'
  s.summary = 'A very simple AUR utility'
  s.email = 'gigamo@gmail.com'
  s.homepage = 'http://github.com/gigamo/aurb'
  s.description = s.summary
  s.rubyforge_project = 'aurb'
  s.has_rdoc = true
  s.authors = ['Gigamo']
  s.files = ['README.rdoc', 'aurb.gemspec', 'bin/aurb.rb']
  s.rdoc_options = ['--main', 'README.rdoc']
  s.extra_rdoc_files = ['README.rdoc']
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
