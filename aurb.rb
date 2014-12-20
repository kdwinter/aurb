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
  VERSION = "v2.1.0".freeze

  module Config
    # saves pkgbuilds to this dir
    SAVE_PATH = File.join(ENV["HOME"], "pkgbuilds")

    # rpc endpoint
    RPC_URL = "https://aur.archlinux.org/rpc.php?type=%s"

    # download endpoint
    DOWNLOAD_URL = "https://aur.archlinux.org/packages/%s/%s/%s.tar.gz"
  end

  module Helpers
    COLORS = [:grey, :red, :green, :yellow, :blue, :purple, :cyan, :white]
    def ansi(text, effect)
      if $stdout.tty? && ENV["TERM"]
        return "\033[0;#{30+COLORS.index(effect.to_sym)}m#{text}\033[0m"
      end
      return text
    end

    # wrap this so we can gracefully handle connection issues
    def GET(uri)
      return open(uri)
    rescue OpenURI::HTTPError
      $stderr.puts "\n\n    " + ansi("!", :red) + " URI not found (#{uri})"
      exit 1
    rescue SocketError
      $stderr.puts "\n\n    " + ansi("!", :red) + " connection problem."
      exit 1
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
      return Config::DOWNLOAD_URL % [name[0..1], name, name]
    end

    def retrieve_attributes
      info_url = Config::RPC_URL % "info&arg=" + URI.escape(name)
      json     = JSON.parse(GET(info_url).read)

      if json && json["resultcount"] > 0
        @attributes = json["results"]
      else
        $stderr.puts "    #{ansi("!", :yellow)} couldn't retrieve attributes for #{name}."
      end
    end

    def version
      return 0 if !attributes
      return attributes["Version"].split(/\D+/).map(&:to_i)
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

        $stdout.puts "\n\n"
      end
    end

    def print_help
      $stdout.puts "aurb.rb #{VERSION}"
      $stdout.puts
      $stdout.puts "USAGE: #{$0} [action] [arg] ([action2] [arg2]...)"
      $stdout.puts
      $stdout.puts "  where action is one of:"
      $stdout.puts
      $stdout.puts "    -d, --download PKG       download PKG into #{Config::SAVE_PATH}"
      $stdout.puts "    -s, --search TERM        search for TERM"
      $stdout.puts "    -i, --info PKG           print info about PKG"
      $stdout.puts "    -u, --updates            checks for updates to installed packages"

      exit 1
    end

    def download(package_name)
      $stdout.print "----> downloading #{package_name} into #{Config::SAVE_PATH}... "

      package    = Package.new(package_name)
      local_path = File.join(Config::SAVE_PATH, package.name) + ".tar.gz"
      tarball    = File.open(local_path, "wb")
      tarball.write(GET(package.download_url).read)
      tarball.close

      # untar if possible
      if $untar
        File.open(local_path, "rb") do |tarball|
          zliball = Zlib::GzipReader.new(tarball)
          Archive::Tar::Minitar.unpack(zliball, Config::SAVE_PATH)
        end

        File.delete(local_path)
      end

      $stdout.puts "success."
    end

    def info(package_name)
      $stdout.puts "----> printing information for #{package_name}:\n\n"

      package = Package.new(package_name, attributes: true)
      package.attributes.each do |key, value|
        $stdout.print key.rjust(20)
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

      info_url = Config::RPC_URL % "multiinfo&arg[]=" + local_aur_packages.map { |package|
        URI.escape(package.name)
      }.join("&arg[]=")
      json     = JSON.parse(GET(info_url).read)

      if json && json["resultcount"] > 0
        local_aur_packages.each do |package|
          latest_package = Package.new(package.name, attributes:
            json["results"].find { |result| result["Name"] == package.name }
          )

          if not (latest_package.attributes && latest_package.attributes.empty?) and package < latest_package
            $stdout.puts "   #{ansi("->", :cyan)} %s has an update available (%s -> %s)\n" % [
              package.name,
              ansi(package.attributes["Version"], :red),
              ansi(latest_package.attributes["Version"], :green)
            ]
          else
            $stdout.puts "      #{package.name} is up to date\n"
          end
        end
      end
    end

    def search(term)
      $stdout.print "----> searching for #{term}... "

      search_url = Config::RPC_URL % "search&arg=" + URI.escape(term)
      json       = JSON.parse(GET(search_url).read)

      if json && json["resultcount"] > 0
        $stdout.puts "found #{json["resultcount"]} results:\n\n"

        json["results"].each do |result|
          package = Package.new(result["Name"], attributes: result)

          $stdout.puts "      %s %s (%d)\n          %s" % [
            package.attributes["Name"],
            package.attributes["Version"],
            package.attributes["NumVotes"],
            package.attributes["Description"]
          ]
        end
      else
        $stderr.puts "failed to find any results for #{term}."
      end
    end
  end
end

cli = Aurb2::CLI.new
cli.optparse!(*ARGV.dup)
