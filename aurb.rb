#!/usr/bin/env ruby

if Process.uid == 0
  abort("Please don't run this script as root. The AUR is considered untrustworthy, and by extension so are the operations based upon it.")
end

if `which pacman`.empty?
  abort("Are you running this on Arch Linux? Pacman was not found.")
end

require "open-uri"
require "json"

$untar = true
begin
  require "zlib"
  require "minitar"
rescue LoadError
  $untar = false
end

module Aurb2
  VERSION = "v2.2.2".freeze

  # saves pkgbuilds to this dir
  SAVE_PATH = ENV["AURB_PATH"] || File.join(ENV["HOME"], "AUR")

  AUR_URL     = "https://aur.archlinux.org"
  AUR_RPC_URL = "#{AUR_URL}/rpc.php?type=%s"

  module Helpers
    COLORS = [:grey, :red, :green, :yellow, :blue, :purple, :cyan, :white].freeze
    protected def color(text, effect)
      if $stdout.tty? && ENV["TERM"]
        return "\033[0;#{30+COLORS.index(effect.to_sym)}m#{text}\033[0m"
      end

      text
    end

    # wrap this so we can gracefully handle connection issues
    protected def http_response_body(uri)
      open(uri).read
    rescue OpenURI::HTTPError
      $stdout.puts "\n#{color("x", :red)} URI not found (#{uri})"
      exit 1
    rescue SocketError
      $stdout.puts "\n#{color("x", :red)} Connection problem."
      exit 1
    end

    protected def execute_command(*command, use_exec: false)
      $stdout.puts "   Running `#{command.join(" ")}`"
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
        $stdout.puts "\n#{color("!", :yellow)} Failed to retrieve attributes for #{name}." \
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
          $stdout.puts "\n"
        when "-s", "--search", "search"
          term = argv.shift or print_help
          search(term)
          $stdout.puts "\n"
        when "-i", "--info", "info"
          package = argv.shift or print_help
          info(package)
          $stdout.puts "\n"
        when "-u", "--updates", "updates"
          check_updates
          $stdout.puts "\n"
        when "-uc", "--update-count", "updatecount"
          check_updates(minimal: true)
        when "-v", "--version", "version"
          $stdout.puts VERSION
        else
          print_help
        end
      end
    end

    def print_help
      $stdout.puts "aurb.rb #{VERSION} (Ruby: #{RUBY_VERSION}, minitar: #{$untar ? "yes" : "no"})"
      $stdout.puts
      $stdout.puts "USAGE: #{$0} [action] [arg] ([action2] [arg2]...)"
      $stdout.puts
      $stdout.puts "  where action is one of:"
      $stdout.puts
      $stdout.puts "    -d,  --download PKG      download PKG into #{SAVE_PATH}"
      $stdout.puts "         --install PKG       download, build, and install PKG"
      $stdout.puts "         --clean-install PKG clean previous build(s), download and install PKG"
      $stdout.puts "    -s,  --search TERM       search for TERM"
      $stdout.puts "    -i,  --info PKG          print info about PKG"
      $stdout.puts "    -u,  --updates           checks for updates to installed AUR packages"
      $stdout.puts "    -uc, --update-count      simply prints the amount of AUR packages with updates available"
      $stdout.puts

      exit 1
    end

    def download(package_name)
      if !File.exist?(SAVE_PATH) || !File.directory?(SAVE_PATH)
        $stdout.print color("Save path doesn't exist, or is not a directory.", :red)
        return false
      end

      $stdout.print "#{color("::", :blue)} Downloading #{color(package_name, :cyan)} into #{SAVE_PATH}... "

      package    = Package.new(package_name, attributes: true)
      local_path = File.join(SAVE_PATH, package.name) + ".tar.gz"

      if package.download_url
        File.open(local_path, "wb") do |tarball|
          tarball.write(http_response_body(package.download_url))
        end

        # untar if possible
        if $untar
          File.open(local_path, "rb") do |tarball|
            Minitar.unpack(Zlib::GzipReader.new(tarball), SAVE_PATH)
          end
          # remove the .tar.gz after unpacking
          File.delete(local_path)
        end

        $stdout.puts "Success."
        true
      else
        false
      end
    end

    def install(package_name, clean_install: false)
      unless $untar
        $stdout.puts color("Please run `gem install minitar` to enable this functionality.", :red)
        return false
      end

      $stdout.puts "#{color("::", :blue)} Installing #{color(package_name, :cyan)}... "

      package    = Package.new(package_name)
      local_path = File.join(SAVE_PATH, package.name)

      if !File.exist?(local_path) || !File.directory?(local_path) || clean_install
        download(package_name) or exit 1
      end

      Dir.chdir(local_path) do
        execute_command("rm", "-rf", "src/ pkg/") if clean_install

        $stdout.print "  Edit PKGBUILD before building (#{color("RECOMMENDED", :green)})? [Y/n] "
        answer = $stdin.gets.chomp
        answer = "Y" if answer.empty?
        if answer.upcase == "Y"
          execute_command("#{ENV["EDITOR"] || "vim"} PKGBUILD")
        end

        execute_command("makepkg", "-sfi", use_exec: true)
      end
    rescue Interrupt
      $stdout.puts "\n  #{color("x", :red)} Interrupted by user."
    end

    TIME_KEYS = %w(FirstSubmitted LastModified).freeze
    def info(package_name)
      $stdout.print "#{color("::", :blue)} Showing information for #{color(package_name, :cyan)}:"

      package = Package.new(package_name, attributes: true)
      $stdout.puts "\n\n"
      package.attributes.each do |key, value|
        $stdout.print color(key.rjust(16), :white)
        if TIME_KEYS.include?(key)
          value = Time.at(value.to_i).strftime("%d/%m/%Y %H:%M") rescue value
        end
        $stdout.puts " " + value.to_s
      end if package.attributes
    end

    def check_updates(minimal: false)
      $stdout.puts "#{color("::", :blue)} Checking for updates...\n\n" unless minimal

      local_aur_packages = `pacman -Qm`.split("\n").delete_if { |p|
        # skip packages that are in community by now
        Dir["/var/lib/pacman/sync/community/#{p.split.join("-")}"].any?
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

            $stdout.puts "> %s has an update available (%s -> %s)\n" % [
              color(package.name, :cyan),
              color(package.attributes["Version"], :red),
              color(latest_package.attributes["Version"], :green)
            ] unless minimal
          else
            $stdout.puts "  #{color(package.name, :cyan)} #{package.attributes["Version"]} is up to date\n" unless minimal
          end
        end
      end

      $stdout.puts amount_of_packages_with_updates if minimal
    end

    def search(term)
      $stdout.print "#{color("::", :cyan)} Searching for #{color(term, :cyan)}... "

      search_url = AUR_RPC_URL % "search&arg=" + URI.escape(term)
      json       = JSON.parse(http_response_body(search_url))

      if json && json["resultcount"] > 0
        $stdout.puts "Found #{json["resultcount"]} results:\n\n"

        json["results"].each do |result|
          package = Package.new(result["Name"], attributes: result)

          $stdout.puts "  %s %s (%d)\n    %s" % [
            color(package.attributes["Name"], :cyan),
            color(package.attributes["Version"], :green),
            package.attributes["NumVotes"],
            package.attributes["Description"]
          ]
        end
      else
        $stdout.puts "Failed to find any results."
      end
    end
  end
end

cli = Aurb2::CLI.new
cli.optparse!(*ARGV.dup)
