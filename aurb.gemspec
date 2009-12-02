# aurb.gemspec

Gem::Specification.new do |s|
  s.name = 'aurb'
  s.version = '0.9.3'
  s.date = %q{2009-12-02}
  s.summary = %q{An AUR (Arch User Repository) script}
  s.email = %q{gigamo@gmail.com}
  s.homepage = %q{http://github.com/gigamo/aurb}
  s.description = s.summary
  s.rubyforge_project = %q{aurb}
  s.executables = ['aurb']
  s.has_rdoc = true
  s.rdoc_options = ['--line-numbers', '--inline-source', '--title', 'Aurb', '--main', 'README.rdoc']
  s.authors = ['Gigamo']
  s.files = ['bin/aurb', 'aurb.gemspec', 'README.rdoc']
  s.add_dependency 'yajl-ruby'
  s.add_dependency 'facets'
end
