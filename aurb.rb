#!/usr/bin/env ruby
# frozen_string_literal: true

if Process.uid == 0
  abort "Please don't run this script as root. The AUR is considered untrustworthy, and by extension so are the operations run upon it."
end

if RUBY_VERSION < "2.1.0"
  abort "aurb requires Ruby >= 2.1.0."
end

if not `which pacman`
  abort "Are you running this on Arch Linux? Pacman was not found."
end

require "open-uri"
require "json"
require "zlib"
require "fileutils"
%w(minitar parseconfig).each do |gem|
  begin
    require gem
  rescue LoadError
    abort "`#{gem}' gem was not found. Please run `gem install #{gem}` to run aurb."
  end
end

config_path = "#{ENV["HOME"]}/.config/aurb/aurb.conf"
if !File.exist?(config_path)
  # create a default config
  FileUtils.mkdir_p(File.dirname(config_path))
  File.open(config_path, "w+") do |config_file|
    config_file.write(<<-CONFIG.gsub(/^ {6}/, "").strip)
      # Directory to save to
      save_path = #{ENV["HOME"]}/AUR
      # Packages to ignore in update checks
      #ignore_pkg = package1 package2
    CONFIG
  end
end

VERSION      = "v2.3.4".freeze
CONFIG       = ParseConfig.new(config_path) rescue {"save_path" => "#{ENV["HOME"]}/AUR"}
AUR_URL      = "https://aur.archlinux.org"
RPC_ENDPOINT = "#{AUR_URL}/rpc/?v=5&type=%s"

unless File.exist?(CONFIG["save_path"]) && File.writable?(CONFIG["save_path"])
  warn("WARNING: Save path `#{CONFIG["save_path"]}' is not writable. Some actions, " \
       "such as downloading, will not work. You can modify this in the config file.\n\n")
end

module Helpers
  COLORS = %i(grey red green yellow blue purple cyan white).freeze
  protected def color(text, effect)
    if $stdout.tty? && ENV["TERM"]
      return "\033[0;#{30 + COLORS.index(effect.to_sym)}m#{text}\033[0m"
    end
    text
  end

  # wrap this so we can gracefully handle connection issues
  protected def GET(uri)
    open(uri).read
  rescue OpenURI::HTTPError
    puts "\n#{color("x", :red)} URI not found (#{uri})"
    exit 1
  rescue SocketError
    puts "\n#{color("x", :red)} Connection problem."
    exit 1
  end

  protected def exec_cmd(*command)
    puts color("  -> Running `#{command.join(" ")}`", :grey)
    system(*command)
  end

  protected def prompt(question)
    print "   #{question} [Y/n] "

    answer = $stdin.gets.chomp
    answer = "Y" if answer.empty?
    answer.upcase == "Y"
  end
end

class Package
  include Comparable
  include Helpers

  NUM_VOTES   = "NumVotes".freeze
  URL_PATH    = "URLPath".freeze
  NAME        = "Name".freeze
  VERSION     = "Version".freeze
  DESCRIPTION = "Description".freeze
  DEPENDS     = "Depends".freeze

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
    if Hash(attributes)[URL_PATH]
      "#{AUR_URL}#{attributes[URL_PATH]}"
    end
  end

  def retrieve_attributes
    info_url = RPC_ENDPOINT % "info&arg=" + URI.escape(name)
    json = JSON.parse(GET(info_url))

    if json && json["resultcount"] > 0
      @attributes = Array(json["results"])[0]
      @attributes.each_key(&:freeze)
    else
      puts "\n#{color("!", :yellow)} Failed to retrieve attributes for #{name}. " \
           "This usually means the package does not exist."
    end
  end

  def version
    if Hash(attributes)[VERSION]
      return attributes[VERSION].split(/\D+/).map(&:to_i)
    end

    [0]
  end

  def dependencies
    Array(Hash(attributes)[DEPENDS])
  end

  def <=>(other)
    [version.size, other.version.size].max.times do |i|
      cmp = version[i].to_i <=> other.version[i].to_i
      return cmp if cmp != 0
    end

    0
  end
end

class App
  include Helpers

  def optparse!(*argv)
    print_help if argv.size < 1

    case argv.shift
    when "--install", "install"
      if argv.any?
        argv.each { |package| install(package) }
      else print_help
      end
    when "--clean-install", "cleaninstall"
      if argv.any?
        argv.each { |package| install(package, clean_install: true) }
      else print_help
      end
    when "-d", "--download", "download"
      if argv.any?
        argv.each { |package| download(package) }
      else print_help
      end
    when "-s", "--search", "search"
      if argv.any?
        search(argv.join(" "))
      else print_help
      end
    when "-i", "--info", "info"
      if argv.any?
        argv.each { |package| info(package) }
      else print_help
      end
    when "-u", "--updates", "updates"
      check_updates
    when "-v", "--version", "version"
      puts VERSION
    else
      print_help
    end
  end

  def print_help
    puts <<-HELP.gsub(/^ {6}/, "").strip
      aurb.rb #{VERSION} (Ruby: #{RUBY_VERSION})

      USAGE: #{$0} [action] [arg] ([action2] [arg2]...)

        where action is one of:

          -d,  --download PKG       download PKG into #{CONFIG["save_path"]}
               --install PKG        download, build, and install PKG
               --clean-install PKG  clean previous build(s), download and install PKG
          -s,  --search TERM        search for TERM
          -i,  --info PKG           print info about PKG
          -u,  --updates            checks for updates to installed AUR packages
    HELP

    exit 1
  end

  def download(package_name)
    if !File.exist?(CONFIG["save_path"]) || !File.directory?(CONFIG["save_path"])
      puts color("Save path doesn't exist, or is not a directory.", :red)
      return false
    end

    print "#{color("::", :blue)} Downloading #{color(package_name, :cyan)} into #{CONFIG["save_path"]}... "

    package = Package.new(package_name, attributes: true)
    if package.download_url
      tarball = StringIO.new(GET(package.download_url))
      Minitar.unpack(Zlib::GzipReader.new(tarball), CONFIG["save_path"])
      puts color("Success.", :green)

      true
    else
      false
    end
  end

  def install(package_name, clean_install: false)
    puts "#{color("::", :blue)} Installing #{color(package_name, :cyan)}... "

    package = Package.new(package_name, attributes: true)
    local_path = File.join(CONFIG["save_path"], package.name)

    if clean_install
      begin
        FileUtils.remove_entry_secure(File.join(local_path, "*"))
      rescue Errno::ENOENT
        # Directories don't exist.
      end
    end

    if !File.exist?(local_path) || !File.directory?(local_path) || clean_install
      if package.dependencies.any?
        packages_in_repos  = `pacman -Sl`
        aur_packages_installed = `pacman -Qm`.split("\n").map { |l| l.split[0] }

        # Select only packages that aren't in official repo's, and install them first.
        deps_in_aur = package.dependencies.reject { |d| !!packages_in_repos[d] }
        if deps_in_aur.any?
          puts "#{color("==>", :green)} Found #{color(deps_in_aur.size, :blue)} AUR " \
            "dependencies of #{color(package_name, :cyan)}: #{deps_in_aur.join(", ")}"

          (deps_in_aur - aur_packages_installed).each do |dependency|
            install(dependency)
          end
        end
      end

      download(package_name) or exit 1
    end

    Dir.chdir(local_path) do
      if prompt("Edit PKGBUILD before building (#{color("RECOMMENDED", :green)})?")
        exec_cmd("#{ENV["EDITOR"] || "vim"} PKGBUILD")
      end

      Dir["*.install"].each do |install_file|
        if prompt("Edit #{File.basename(install_file)} before building (#{color("RECOMMENDED", :green)})?")
          exec_cmd("#{ENV["EDITOR"] || "vim"} #{install_file}")
        end
      end

      exec_cmd("makepkg", clean_install ? "-sfCi" : "-si")
    end
  rescue Interrupt
    puts "\n  #{color("x", :red)} Interrupted by user."
  end

  TIME_KEYS = %w(FirstSubmitted LastModified OutOfDate).freeze.map(&:freeze)
  TIME_FORMAT = "%d/%m/%Y %H:%M".freeze
  def info(package_name)
    print "#{color("::", :blue)} Showing information for #{color(package_name, :cyan)}:"

    package = Package.new(package_name, attributes: true)
    puts "\n\n"
    package.attributes.each do |key, value|
      print color(key.rjust(16), :white)

      if TIME_KEYS.include?(key)
        value = Time.at(value.to_i).strftime(TIME_FORMAT) rescue value
      end

      value = value.join(", ") if value.is_a?(Array)

      puts " " + value.to_s
    end if package.attributes
  end

  def check_updates
    puts "#{color("::", :blue)} Checking for updates...\n\n"

    ignore_list = CONFIG["ignore_pkg"].to_s.split(" ")
    local_aur_packages = `pacman -Qm`.split("\n").map(&:split).delete_if { |package_info|
      name, version  = package_info

      # skip packages that are in community by now
      in_community   = Dir["/var/lib/pacman/sync/community/#{name}-#{version}"].any?
      # skip packages that are ignored through config
      in_ignore_list = ignore_list.include?(name)

      in_community or in_ignore_list
    }.map { |package_info|
      name, version = package_info
      Package.new(name, attributes: {Package::VERSION => version})
    }

    info_url = RPC_ENDPOINT % "multiinfo&arg[]=" + local_aur_packages.map { |package|
      URI.escape(package.name)
    }.join("&arg[]=")
    json = JSON.parse(GET(info_url))

    if json && json["resultcount"] > 0
      local_aur_packages.each do |package|
        latest_package = Package.new(package.name, attributes:
          json["results"].find { |result| result[Package::NAME] == package.name }
        )

        if !(latest_package.attributes && latest_package.attributes.empty?) && package < latest_package
          puts "#{color(">", :yellow)} %s has an update available (%s -> %s)\n" % [
            color(package.name, :cyan),
            color(package.attributes[Package::VERSION], :red),
            color(latest_package.attributes[Package::VERSION], :green)
          ]
        else
          puts "  #{color(package.name, :cyan)} #{package.attributes[Package::VERSION]} is up to date\n"
        end
      end
    end
  end

  def search(term)
    print "#{color("::", :cyan)} Searching for #{color(term, :cyan)}... "

    search_url = RPC_ENDPOINT % "search&arg=" + URI.escape(term)
    json = JSON.parse(GET(search_url))

    if json && json["resultcount"] > 0
      puts "Found #{json["resultcount"]} results:\n\n"

      json["results"].sort { |a, b|
        b[Package::NUM_VOTES] <=> a[Package::NUM_VOTES]
      }.each do |result|
        package = Package.new(result[Package::NAME], attributes: result)

        begin
          puts "  %s %s (%d)\n    %s" % [
            color(package.attributes[Package::NAME], :cyan),
            color(package.attributes[Package::VERSION], :green),
            package.attributes[Package::NUM_VOTES],
            package.attributes[Package::DESCRIPTION]
          ]
        rescue Errno::EPIPE
        end
      end
    else
      puts "Failed to find any results."
    end
  end
end

App.new.optparse!(*ARGV.dup)
