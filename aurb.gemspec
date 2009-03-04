Gem::Specification.new do |s|
  s.name = 'aurb'
  s.version = '0.5.3'
  s.summary = 'A Ruby AUR utility'
  s.files = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.executables = ['aurb']
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.rdoc']
  s.rdoc_options << '--main' << 'README.rdoc' <<
                    '--charset' << 'utf-8' <<
                    '--inline-source' << '--line-numbers' <<
                    '--webcvs' << 'http://github.com/gigamo/aurb/tree/master/%s' <<
                    '--title' << 'aurb api'
  s.author = 'Gigamo'
  s.email = 'gigamo@gmail.com'
  s.homepage = 'http://github.com/gigamo/aurb/tree/master'
  s.rubyforge_project = ''
end
