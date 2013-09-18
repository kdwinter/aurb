#!/usr/bin/env ruby
require "open-uri"

$untar = true
begin
  require "zlib"
  require "archive/tar/minitar"
rescue LoadError
  $untar = false
end

$yajl = true
begin
  require "yajl"
rescue LoadError
  $yajl = false
  require "json"
end

$threads = []

module Aurb2
  VERSION = "v2.0.0".freeze

  # saves pkgbuilds to this dir
  SAVE_PATH = File.join(ENV["HOME"], "pkgbuilds")

  # rpc endpoint
  RPC_URL = "https://aur.archlinux.org/rpc.php?type=%s&arg=%s"

  # download endpoint
  DOWNLOAD_URL = "https://aur.archlinux.org/packages/%s/%s/%s.tar.gz"

  # amount of threads for update check
  THREAD_AMOUNT = 4

  module Helpers
    def parse_json(json)
      if $yajl
        return Yajl::Parser.new.parse(json)
      else
        return JSON.parse(json)
      end
    end

    def in_thread
      $threads << Thread.new(&Proc.new)
    end

    def join_threads!
      $threads.each(&:join)
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
      return DOWNLOAD_URL % [name[0..1], name, name]
    end

    def retrieve_attributes
      info_url = RPC_URL % ["info", URI.escape(name)]
      uri      = open(info_url)
      json     = parse_json(uri.read)

      if json && json["resultcount"] > 0
        @attributes = json["results"]
      else
        puts "couldn't retrieve attributes for #{name}."
      end
    end

    def version
      return attributes["Version"].split(/\W+/).map(&:to_i)
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
        when "-D", "--download"
          package = argv.shift or print_help
          download(package)
        when "-S", "--search"
          term = argv.shift or print_help
          search(term)
        when "-I", "--info"
          package = argv.shift or print_help
          info(package)
        when "-U", "--updates"
          check_updates
        when "-v", "--version"
          $stdout.puts VERSION
        else
          print_help
        end

        $stdout.puts "\n\n"
      end
    end

    def print_help
      $stdout.puts "aurb2 #{VERSION}"
      $stdout.puts
      $stdout.puts "USAGE: #{$0} [action] [arg] ([action2] [arg2]...)"
      $stdout.puts
      $stdout.puts "  where action is one of:"
      $stdout.puts
      $stdout.puts "    -D, --download PKG       download PKG into #{SAVE_PATH}"
      $stdout.puts "    -S, --search TERM        search for TERM"
      $stdout.puts "    -I, --info PKG           print info about PKG"
      $stdout.puts "    -U, --updates            checks for updates to installed packages"

      exit 1
    end

    def download(package_name)
      $stdout.print "downloading #{package_name} into #{SAVE_PATH}... "

      package    = Package.new(package_name)
      local_path = File.join(SAVE_PATH, package.name) + ".tar.gz"
      tarball    = File.open(local_path, "wb")
      uri        = open(package.download_url)
      tarball.write(uri.read)
      tarball.close

      # untar if possible
      if $untar
        File.open(local_path, "rb") do |tarball|
          zliball = Zlib::GzipReader.new(tarball)
          Archive::Tar::Minitar.unpack(zliball, SAVE_PATH)
        end

        File.delete(local_path)
      end

      $stdout.puts "success."
    end

    def info(package_name)
      $stdout.puts "printing information for #{package_name}:\n\n"

      package = Package.new(package_name, attributes: true)
      package.attributes.each do |key, value|
        $stdout.print key.rjust(15)
        $stdout.puts " " + value.to_s
      end
    end

    def check_updates
      $stdout.puts "checking for updates...\n\n"

      aur_packages = `pacman -Qm`.split("\n")
      batch_size = aur_packages.size / THREAD_AMOUNT
      aur_packages.each_slice(batch_size) do |lines|
        lines.each do |line|
          name, version = line.split

          # don't do anything if this package is in community by now
          next if Dir["/var/lib/pacman/sync/community/#{name}-#{version}"].any?

          in_thread do
            old_package = Package.new(name, attributes: {'Version' => version})
            new_package = Package.new(name, attributes: true)

            if not new_package.attributes.empty? and old_package < new_package
              $stdout.puts "%s has an update available (%s -> %s}" % [
                name, old_package.attributes['Version'], new_package.attributes['Version']
              ]
            else
              $stdout.puts "#{name} is up to date"
            end
          end
        end

        join_threads!
      end
    end

    def search(term)
      $stdout.print "searching for #{term}... "

      search_url = RPC_URL % ["search", term]
      uri        = open(search_url)
      json       = parse_json(uri.read)

      if json && json["resultcount"] > 0
        $stdout.puts "found #{json["resultcount"]} results:\n\n"

        json["results"].each do |result|
          package = Package.new(result["Name"], attributes: result)

          $stdout.puts "[%s] %s %s (%d)\n    %s" % [
            package.attributes["OutOfDate"] == 1 ? "x" : "v",
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
