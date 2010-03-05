# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{aurb}
  s.version = "1.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gigamo"]
  s.date = %q{2010-03-05}
  s.default_executable = %q{aurb}
  s.email = %q{gigamo@gmail.com}
  s.executables = ["aurb"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.md"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.md",
     "Rakefile",
     "VERSION",
     "aurb.gemspec",
     "bin/aurb",
     "lib/aurb.rb",
     "lib/aurb/aur.rb",
     "lib/aurb/cli.rb",
     "lib/aurb/core_ext.rb",
     "lib/aurb/core_ext/hash.rb",
     "lib/aurb/core_ext/object.rb",
     "lib/aurb/core_ext/string.rb",
     "lib/aurb/version.rb",
     "performance/aur.rb",
     "test/test_helper.rb",
     "test/unit/aur_test.rb",
     "test/unit/support_test.rb"
  ]
  s.homepage = %q{http://github.com/gigamo/aurb}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{An AUR (Arch User Repository) utility}
  s.test_files = [
    "test/unit/aur_test.rb",
     "test/unit/support_test.rb",
     "test/test_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_runtime_dependency(%q<thor>, [">= 0"])
      s.add_runtime_dependency(%q<ansi>, [">= 0"])
      s.add_runtime_dependency(%q<archive-tar-minitar>, [">= 0"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
    else
      s.add_dependency(%q<yajl-ruby>, [">= 0"])
      s.add_dependency(%q<thor>, [">= 0"])
      s.add_dependency(%q<ansi>, [">= 0"])
      s.add_dependency(%q<archive-tar-minitar>, [">= 0"])
      s.add_dependency(%q<shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<yajl-ruby>, [">= 0"])
    s.add_dependency(%q<thor>, [">= 0"])
    s.add_dependency(%q<ansi>, [">= 0"])
    s.add_dependency(%q<archive-tar-minitar>, [">= 0"])
    s.add_dependency(%q<shoulda>, [">= 0"])
  end
end

