#!/usr/bin/env ruby

if Process.uid == 0
  abort("Please don't run this script as root. The AUR is considered untrustworthy, and by extension so are the operations based upon it.")
end

if `which pacman`.empty?
  abort("Are you running this on Arch Linux? Pacman was not found.")
end

require "open-uri"
require "json"
require "zlib"
require "fileutils"
%w(minitar parseconfig).each do |gem|
  begin
    require gem
  rescue LoadError
    abort "`#{gem}' gem was not found. Please run `gem install #{gem}` to run this script."
  end
end

module Aurb2
  VERSION = "v2.2.2".freeze

  config_path = "#{ENV["HOME"]}/.config/aurb/aurb.conf"
  unless File.exist?(config_path)
    FileUtils.mkdir_p(config_path.split("/")[0..-2].join("/"))
    File.open(config_path, "w+") do |f|
      f.write("# Directory to save to\n" \
              "save_path = #{ENV["HOME"]}/AUR\n" \
              "# Packages to ignore in update checks\n"  \
              "#ignore_pkg = package1 package2\n")
    end
  end
  CONFIG = ParseConfig.new(config_path)

  AUR_URL     = "https://aur.archlinux.org"
  AUR_RPC_URL = "#{AUR_URL}/rpc.php?type=%s"

  module Helpers
    COLORS = [:grey, :red, :green, :yellow, :blue, :purple, :cyan, :white].freeze
    protected def color(text, effect)
      if tty? && ENV["TERM"]
        return "\033[0;#{30+COLORS.index(effect.to_sym)}m#{text}\033[0m"
      end

      text
    end

    # wrap this so we can gracefully handle connection issues
    protected def http_response_body(uri)
      open(uri).read
    rescue OpenURI::HTTPError
      puts "\n#{color("x", :red)} URI not found (#{uri})"
      exit 1
    rescue SocketError
      puts "\n#{color("x", :red)} Connection problem."
      exit 1
    end

    protected def execute_command(*command, use_exec: false)
      puts "   Running `#{command.join(" ")}`"
      use_exec ? exec(*command) : system(*command)
    end
  end

  class Package
    include Comparable
    include Helpers

    attr_reader :name, :attributes

    def initialize(name, attributes: nil)
      @name = name

      if Hash === attributes
        @attributes = attributes
      elsif attributes
        retrieve_attributes
      end
    end

    def download_url
      if Hash(attributes)["URLPath"]
        "#{AUR_URL}#{attributes["URLPath"]}"
      end
    end

    def retrieve_attributes
      info_url = AUR_RPC_URL % "info&arg=" + URI.escape(name)
      json     = JSON.parse(http_response_body(info_url))

      if json && json["resultcount"] > 0
        @attributes = json["results"]
      else
        puts "\n#{color("!", :yellow)} Failed to retrieve attributes for #{name}." \
                     "\n  This usually means the package does not exist."
      end
    end

    def version
      if Hash(attributes)["Version"]
        return attributes["Version"].split(/\D+/).map(&:to_i)
      end

      [0]
    end

    def <=>(other)
      [version.size, other.version.size].max.times do |i|
        cmp = version[i] <=> other.version[i]
        return cmp if cmp != 0
      end
    end
  end

  class CLI
    include Helpers

    def optparse!(*argv)
      print_help if argv.size < 1

      until argv.empty?
        action = argv.shift

        case action
        when "--install", "install"
          package = argv.shift or print_help
          install(package)
        when "--clean-install", "cleaninstall"
          package = argv.shift or print_help
          install(package, clean_install: true)
        when "-d", "--download", "download"
          package = argv.shift or print_help
          download(package)
          puts "\n"
        when "-s", "--search", "search"
          term = argv.shift or print_help
          search(term)
          puts "\n"
        when "-i", "--info", "info"
          package = argv.shift or print_help
          info(package)
          puts "\n"
        when "-u", "--updates", "updates"
          check_updates
          puts "\n"
        when "-uc", "--update-count", "updatecount"
          check_updates(minimal: true)
        when "-v", "--version", "version"
          puts VERSION
        else
          print_help
        end
      end
    end

    def print_help
      puts "aurb.rb #{VERSION} (Ruby: #{RUBY_VERSION})"
      puts
      puts "USAGE: #{$0} [action] [arg] ([action2] [arg2]...)"
      puts
      puts "  where action is one of:"
      puts
      puts "    -d,  --download PKG      download PKG into #{CONFIG["save_path"]}"
      puts "         --install PKG       download, build, and install PKG"
      puts "         --clean-install PKG clean previous build(s), download and install PKG"
      puts "    -s,  --search TERM       search for TERM"
      puts "    -i,  --info PKG          print info about PKG"
      puts "    -u,  --updates           checks for updates to installed AUR packages"
      puts "    -uc, --update-count      simply prints the amount of AUR packages with updates available"
      puts

      exit 1
    end

    def download(package_name)
      if !File.exist?(CONFIG["save_path"]) || !File.directory?(CONFIG["save_path"])
        print color("Save path doesn't exist, or is not a directory.", :red)
        return false
      end

      print "#{color("::", :blue)} Downloading #{color(package_name, :cyan)} into #{CONFIG["save_path"]}... "

      package    = Package.new(package_name, attributes: true)
      local_path = File.join(CONFIG["save_path"], package.name) + ".tar.gz"

      if package.download_url
        File.open(local_path, "wb") do |tarball|
          tarball.write(http_response_body(package.download_url))
        end

        File.open(local_path, "rb") do |tarball|
          Minitar.unpack(Zlib::GzipReader.new(tarball), CONFIG["save_path"])
        end
        # remove the .tar.gz after unpacking
        File.delete(local_path)

        puts "Success."
        true
      else
        false
      end
    end

    def install(package_name, clean_install: false)
      puts "#{color("::", :blue)} Installing #{color(package_name, :cyan)}... "

      package    = Package.new(package_name)
      local_path = File.join(CONFIG["save_path"], package.name)

      if !File.exist?(local_path) || !File.directory?(local_path) || clean_install
        download(package_name) or exit 1
      end

      Dir.chdir(local_path) do
        execute_command("rm", "-rf", "src/ pkg/") if clean_install

        print "  Edit PKGBUILD before building (#{color("RECOMMENDED", :green)})? [Y/n] "
        answer = $stdin.gets.chomp
        answer = "Y" if answer.empty?
        if answer.upcase == "Y"
          execute_command("#{ENV["EDITOR"] || "vim"} PKGBUILD")
        end

        flags = clean_install ? "-sfCi" : "-si"
        execute_command("makepkg", flags, use_exec: true)
      end
    rescue Interrupt
      puts "\n  #{color("x", :red)} Interrupted by user."
    end

    TIME_KEYS = %w(FirstSubmitted LastModified).freeze
    def info(package_name)
      print "#{color("::", :blue)} Showing information for #{color(package_name, :cyan)}:"

      package = Package.new(package_name, attributes: true)
      puts "\n\n"
      package.attributes.each do |key, value|
        print color(key.rjust(16), :white)
        if TIME_KEYS.include?(key)
          value = Time.at(value.to_i).strftime("%d/%m/%Y %H:%M") rescue value
        end
        puts " " + value.to_s
      end if package.attributes
    end

    def check_updates(minimal: false)
      puts "#{color("::", :blue)} Checking for updates...\n\n" unless minimal

      ignore_list = CONFIG["ignore_pkg"].to_s.split(" ")
      local_aur_packages = `pacman -Qm`.split("\n").delete_if { |p|
        # skip packages that are in community by now
        in_community = Dir["/var/lib/pacman/sync/community/#{p.split.join("-")}"].any?
        # skip packages that are ignored through config
        in_ignore_list = ignore_list.include?(p.split[0])

        in_community or in_ignore_list
      }.map { |line|
        package_name, package_version = line.split
        Package.new(package_name, attributes: {"Version" => package_version})
      }

      info_url = AUR_RPC_URL % "multiinfo&arg[]=" + local_aur_packages.map { |package|
        URI.escape(package.name)
      }.join("&arg[]=")
      json = JSON.parse(http_response_body(info_url))

      amount_of_packages_with_updates = 0

      if json && json["resultcount"] > 0
        local_aur_packages.each do |package|
          latest_package = Package.new(package.name, attributes:
            json["results"].find { |result| result["Name"] == package.name }
          )

          if !(latest_package.attributes && latest_package.attributes.empty?) && package < latest_package
            amount_of_packages_with_updates += 1

            puts "> %s has an update available (%s -> %s)\n" % [
              color(package.name, :cyan),
              color(package.attributes["Version"], :red),
              color(latest_package.attributes["Version"], :green)
            ] unless minimal
          else
            puts "  #{color(package.name, :cyan)} #{package.attributes["Version"]} is up to date\n" unless minimal
          end
        end
      end

      print amount_of_packages_with_updates if minimal
    end

    def search(term)
      print "#{color("::", :cyan)} Searching for #{color(term, :cyan)}... "

      search_url = AUR_RPC_URL % "search&arg=" + URI.escape(term)
      json       = JSON.parse(http_response_body(search_url))

      if json && json["resultcount"] > 0
        puts "Found #{json["resultcount"]} results:\n\n"

        json["results"].each do |result|
          package = Package.new(result["Name"], attributes: result)

          puts "  %s %s (%d)\n    %s" % [
            color(package.attributes["Name"], :cyan),
            color(package.attributes["Version"], :green),
            package.attributes["NumVotes"],
            package.attributes["Description"]
          ]
        end
      else
        puts "Failed to find any results."
      end
    end
  end
end

cli = Aurb2::CLI.new
cli.optparse!(*ARGV.dup)
