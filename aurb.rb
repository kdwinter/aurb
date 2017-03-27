#!/usr/bin/env ruby
require "open-uri"
require "json"

$untar = true
begin
  require "zlib"
  require "archive/tar/minitar"
rescue LoadError
  $untar = false
end

module Aurb2
  VERSION = "v2.2.1".freeze

  # saves pkgbuilds to this dir
  SAVE_PATH = ENV["AURB_PATH"] || File.join(ENV["HOME"], "AUR")

  AUR_URL     = "https://aur.archlinux.org"
  AUR_RPC_URL = "#{AUR_URL}/rpc.php?type=%s"

  module Helpers
    COLORS = [:grey, :red, :green, :yellow, :blue, :purple, :cyan, :white]
    def ansi(text, effect)
      if $stdout.tty? && ENV["TERM"]
        return "\033[0;#{30+COLORS.index(effect.to_sym)}m#{text}\033[0m"
      end

      text
    end

    # wrap this so we can gracefully handle connection issues
    def http_response_body(uri)
      open(uri).read
    rescue OpenURI::HTTPError
      $stdout.puts "\n    #{ansi("x", :red)} URI not found (#{uri})"
      exit 1
    rescue SocketError
      $stdout.puts "\n    #{ansi("x", :red)} connection problem."
      exit 1
    end

    def execute_command(*command)
      $stdout.puts "      running `#{command.join(" ")}`"
      system(*command)
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
        $stdout.puts "\n    #{ansi("!", :yellow)} couldn't retrieve attributes for #{name}."
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
        when "--clean-install"
          package = argv.shift or print_help
          install(package, cleanup: true)
        when "-d", "--download", "download"
          package = argv.shift or print_help
          download(package)
        when "-s", "--search", "search"
          term = argv.shift or print_help
          search(term)
        when "-i", "--info", "info"
          package = argv.shift or print_help
          info(package)
        when "-u", "--updates", "updates"
          check_updates
        when "-v", "--version", "version"
          $stdout.puts VERSION
        else
          print_help
        end

        $stdout.puts "\n"
      end
    end

    def print_help
      $stdout.puts "aurb.rb #{VERSION} (Ruby: #{RUBY_VERSION})"
      $stdout.puts
      $stdout.puts "USAGE: #{$0} [action] [arg] ([action2] [arg2]...)"
      $stdout.puts
      $stdout.puts "  where action is one of:"
      $stdout.puts
      $stdout.puts "    -d, --download PKG       download PKG into #{SAVE_PATH}"
      $stdout.puts "        --install PKG        download and install PKG"
      $stdout.puts "        --clean-install PKG  cleanup previous build(s), download and install PKG"
      $stdout.puts "    -s, --search TERM        search for TERM"
      $stdout.puts "    -i, --info PKG           print info about PKG"
      $stdout.puts "    -u, --updates            checks for updates to installed packages"
      $stdout.puts

      exit 1
    end

    def download(package_name)
      if !File.exist?(SAVE_PATH) || !File.directory?(SAVE_PATH)
        $stdout.print ansi("Save path doesn't exist, or is not a directory.", :red)
        return false
      end

      $stdout.print "----> downloading #{ansi(package_name, :cyan)} into #{SAVE_PATH}... "

      package    = Package.new(package_name, attributes: true)
      local_path = File.join(SAVE_PATH, package.name) + ".tar.gz"

      if package.download_url
        tarball    = File.open(local_path, "wb")
        tarball.write(http_response_body(package.download_url))
        tarball.close

        # untar if possible
        if $untar
          File.open(local_path, "rb") do |tarball|
            zlib = Zlib::GzipReader.new(tarball)
            Archive::Tar::Minitar.unpack(zlib, SAVE_PATH)
          end

          File.delete(local_path)
        end

        $stdout.puts "success."
        true
      else
        false
      end
    end

    def install(package_name, cleanup: false)
      unless $untar
        $stdout.puts ansi("Please run `gem install archive-tar-minitar` to enable this functionality.", :red)
        return false
      end

      $stdout.puts "----> installing #{ansi(package_name, :cyan)}... "

      package    = Package.new(package_name)
      local_path = File.join(SAVE_PATH, package.name)

      unless File.exist?(local_path) && File.directory?(local_path)
        download(package_name) or exit 1
      end

      Dir.chdir(local_path) do
        execute_command("rm -rf src/ pkg/") if cleanup

        $stdout.print "      edit PKGBUILD before building (#{ansi("RECOMMENDED", :green)})? [Y/n] "
        answer = $stdin.gets.chomp
        answer = "Y" if answer.empty?
        if answer.upcase == "Y"
          execute_command("#{ENV["EDITOR"] || "vim"} PKGBUILD")
        end

        execute_command("makepkg -sfi")
      end
    rescue Interrupt
      $stdout.puts "\n    #{ansi("x", :red)} Interrupted by user."
    end

    TIME_KEYS = %w(FirstSubmitted LastModified).freeze
    def info(package_name)
      $stdout.print "----> showing information for #{ansi(package_name, :cyan)}:"

      package = Package.new(package_name, attributes: true)
      $stdout.puts "\n\n"
      package.attributes.each do |key, value|
        $stdout.print ansi(key.rjust(20), :white)
        if TIME_KEYS.include?(key)
          value = Time.at(value.to_i).strftime("%d/%m/%Y %H:%M") rescue value
        end
        $stdout.puts " " + value.to_s
      end if package.attributes
    end

    def check_updates
      $stdout.puts "----> checking for updates...\n\n"

      local_aur_packages = `pacman -Qm`.split("\n").delete_if { |p|
        # skip packages that are in community by now
        Dir["/var/lib/pacman/sync/community/#{p.split.join("-")}"].any?
      }.map { |line|
        line = line.split
        Package.new(line[0], attributes: {"Version" => line[1]})
      }

      info_url = AUR_RPC_URL % "multiinfo&arg[]=" + local_aur_packages.map { |package|
        URI.escape(package.name)
      }.join("&arg[]=")
      json = JSON.parse(http_response_body(info_url))

      if json && json["resultcount"] > 0
        local_aur_packages.each do |package|
          latest_package = Package.new(package.name, attributes:
            json["results"].find { |result| result["Name"] == package.name }
          )

          if not (latest_package.attributes && latest_package.attributes.empty?) and package < latest_package
            $stdout.puts "   -> %s has an update available (%s -> %s)\n" % [
              ansi(package.name, :cyan),
              ansi(package.attributes["Version"], :red),
              ansi(latest_package.attributes["Version"], :green)
            ]
          else
            $stdout.puts "      #{ansi(package.name, :cyan)} #{package.attributes["Version"]} is up to date\n"
          end
        end
      end
    end

    def search(term)
      $stdout.print "----> searching for #{ansi(term, :cyan)}... "

      search_url = AUR_RPC_URL % "search&arg=" + URI.escape(term)
      json       = JSON.parse(http_response_body(search_url))

      if json && json["resultcount"] > 0
        $stdout.puts "found #{json["resultcount"]} results:\n\n"

        json["results"].each do |result|
          package = Package.new(result["Name"], attributes: result)

          $stdout.puts "      %s %s (%d)\n          %s" % [
            ansi(package.attributes["Name"], :cyan),
            package.attributes["Version"],
            package.attributes["NumVotes"],
            package.attributes["Description"]
          ]
        end
      else
        $stdout.puts "failed to find any results."
      end
    end
  end
end

cli = Aurb2::CLI.new
cli.optparse!(*ARGV.dup)
