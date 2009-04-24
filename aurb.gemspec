Gem::Specification.new do |s|
  s.name = 'aurb'
  s.version = '0.7.2'
  s.date = %q{2009-04-24}
  s.summary = %q{A simple AUR utility}
  s.email = %q{gigamo@gmail.com}
  s.homepage = %q{http://github.com/gigamo/aurb}
  s.description = s.summary
  s.rubyforge_project = %q{aurb}
  s.executables = ['aurb']
  s.has_rdoc = true
  s.rdoc_options = ['--line-numbers', '--inline-source', '--title', 'Aurb', '--main', 'README']
  s.authors = ['Gigamo']
  s.files = ['bin/aurb', 'aurb.gemspec', 'README.rdoc']
  s.add_dependency 'json'
  s.add_dependency 'facets'
  s.add_dependency 'highline'
end
