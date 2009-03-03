#!/usr/bin/env ruby

# AurB is a Ruby AUR utility, heavily inspired by `arson' and `yaourt'.
# Author: Gigamo <gigamo@gmail.com>
# License: WTFPL <http://sam.zoy.org/wtfpl/>
#
#   This program is free software. It comes without any warranty, to
#   the extent permitted by applicable law. You can redistribute it
#   and/or modify it under the terms of the Do What The Fuck You Want
#   To Public License, Version 2, as published by Sam Hocevar. See
#   http://sam.zoy.org/wtfpl/COPYING for more details.

require 'rubygems'
require 'zlib'
require 'facets/version'
require 'facets/minitar'
require 'facets/ansicode'
require 'json'
require 'cgi'
require 'open-uri'
require 'fileutils'

module AurB
  extend self

  Aur_Domain   = 'http://aur.archlinux.org'
  Aur_Search   = "#{Aur_Domain}/rpc.php?type=search&arg=%s"
  Aur_Info     = "#{Aur_Domain}/rpc.php?type=info&arg=%s"
  Abs_Domain   = 'http://archlinux.org/packages/search/?category=all&limit=99000'
  Pacman_Sync  = '/var/lib/pacman/sync/%s'
  Pacman_Cache = '/var/lib/pacman/local'

  def colorize(string, *effects)
    colored = ' '
    effects.each do |effect|
      colored << ANSICode.send(effect)
    end
    colored << string << ANSICode.clear
    colored[1..-1]
  end

  def in_pacman_sync?(name, repo)
    repo = Pacman_Sync % repo
    true if Dir["#{repo}/#{name}-*"].first
  end

  def in_pacman_cache?(name, version, cached=Pacman_Cache)
    if File.exists?("#{cached}/#{name}-#{version}")
      return 'Installed'
    else
      Dir.chdir(cached) do
        installed = Dir["#{name}-*"].first
        if installed
          installed_version = VersionNumber.new(installed[name.length+1..-1])
          remote_version = VersionNumber.new(version)
          if installed_version > remote_version
            return 'Installed'
          elsif remote_version > installed_version
            return 'Upgradable'
          end
        else
          return 'Not installed'
        end
      end
    end
  end

  def aur_list(name)
    json = JSON.parse(open(Aur_Search % CGI::escape(name)).read)
    list = []

    if json['type'] == 'error'
      STDOUT.puts "ERROR: JSON: #{json['results']}"
      exit 1
    end
    json['results'].each do |aurp|
      list << [aurp['Name'], aurp['ID']]
    end
    list.sort
  end

  def aur_search(keywords)
    list = aur_list(keywords.join(' '))
    count = 0
    threads = []
    list.each do |values|
      threads << Thread.new(values) do
        info = JSON.parse(open(Aur_Info % values[1]).read)
        unless info['type'] == 'error'
          info = info['results']
          next if in_pacman_sync?(info['Name'], 'community')
          if keywords.any? do |keyword|
              info['Name'].include?(keyword) or info['Description'].include?(keyword)
            end
            count += 1
            puts colorize("aur/#{info['Name']} #{info['Version']}", :yellow)
            puts colorize("    #{info['Description']}", (info['OutOfDate'] == '1' ? :red : :bold))
          end
        else
          STDOUT.puts "WARNING: #{info['results']} for package #{values[0]}"
        end
      end
    end
    threads.each { |t| t.join }
    puts "\nFound #{colorize(count.to_s, :magenta)} results"
  end

  def aur_get(packages, depend=false)
    unless $options[:download_dir]
      STDOUT.puts 'WARNING: No download directory given, falling back to default (current)'
      $options[:download_dir] = Pathname.new(Dir.pwd).realpath
    end
    no_pkg = true
    packages.each do |pkg|
      unless File.exists?(File.join($options[:download_dir], pkg))
        list = aur_list(pkg)
        list.each do |names|
          if names[0] == pkg
            info = JSON.parse(open(Aur_Info % names[1]).read)['results']
            puts "WARNING: #{colorize(pkg, :bold)} is #{colorize('out of date', :magenta)}!" if info['OutOfDate'] == '1'
            FileUtils.chdir($options[:download_dir]) do |dir|
              begin
                no_pkg = false
                if in_pacman_sync?(pkg, 'community')
                  puts "Found package #{colorize(pkg, :bold)} in the community repository. Handing this to pacman.."
                  exec "sudo pacman -S #{pkg}"
                else
                  puts "Found #{depend ? 'dependency' : 'package'} #{colorize(pkg, :bold)}! Downloading.."
                  open("#{Aur_Domain}/#{info['URLPath']}") do |tar|
                    File.open("#{dir}/#{pkg}.tar.gz", 'wb') do |file|
                      file.write(tar.read)
                    end
                  end
                end
              rescue OpenURI::HTTPError => e
                if e.message.include?('404')
                  begin
                    no_pkg = false
                    open("#{Aur_Domain}/packages/#{pkg}/#{pkg}.tar.gz") do |tar|
                      File.open("#{dir}/#{pkg}.tar.gz", 'wb') do |file|
                        file.write(tar.read)
                      end
                    end
                  rescue OpenURI::HTTPError => e
                    no_pkg = false
                    STDOUT.puts "ERROR downloading #{pkg}: #{e.message}"
                    exit 1
                  end
                else
                  no_pkg = false
                  STDOUT.puts "ERROR downloading #{pkg}: #{e.message}"
                  exit 1
                end
              end
              tgz = Zlib::GzipReader.new(File.open("#{pkg}.tar.gz", 'rb'))
              Archive::Tar::Minitar.unpack(tgz, Dir.pwd)

              FileUtils.rm("#{pkg}.tar.gz") if File.exists?("#{pkg}.tar.gz")
            end
            if $options[:command] == :build
              FileUtils.chdir("#{$options[:download_dir]}/#{pkg}")
              puts "Building #{colorize(pkg, :bold)} with makepkg.."
              exec 'makepkg'
            end
          end
        end
        if no_pkg and not depend
          STDOUT.puts "ERROR: package #{pkg} not found."
          exit 1
        end
      else
        STDOUT.puts "ERROR: #{$options[:download_dir]}/#{pkg} already exists."
        exit 1
      end
    end
  end

  def abs_get(repo, pkg)
    unless `which rsync`.strip == ''
      Dir.chdir($options[:download_dir]) if $options[:download_dir]
      `/usr/bin/rsync -mrt --no-motd --delete-after rsync.archlinux.org::abs/i686/#{repo}/#{pkg} .`
      if $options[:command] == :build
        FileUtils.chdir("#{$options[:download_dir]}/#{pkg}")
        puts "Building #{colorize(pkg, :bold)} with makepkg.."
        exec 'makepkg'
      end
    else
      STDOUT.puts "ERROR: rsync is not installed"
    end
  end

  def aur_info(names)
    threads = []
    names.each do |name|
      threads << Thread.new(name) do
        aur_list(name).each do |pkg|
          if pkg[0] == name
            json = JSON.parse(open(Aur_Info % pkg[1]).read)['results']
            ood_check = (json['OutOfDate'] == '0' ? 'is not' : colorize('is', :red))
            status_check = "is #{colorize('not installed', :green)}" if in_pacman_cache?(json['Name'], json['Version']) == 'Not installed'
            status_check = "is #{colorize('installed', :green)}" if in_pacman_cache?(json['Name'], json['Version']) == 'Installed'
            status_check = "has an #{colorize('upgrade', :blue)} available" if in_pacman_cache?(json['Name'], json['Version']) == 'Upgradable'

            puts <<EOINFO
       #{colorize('Name:', :white)} #{json['Name']}
    #{colorize('Version:', :white)} #{json['Version']}
#{colorize('Description:', :white)} #{json['Description']}
   #{colorize('Homepage:', :white)} #{json['URL']}
    #{colorize('License:', :white)} #{json['License']}
      #{colorize('Votes:', :white)} #{json['NumVotes']}
     #{colorize('Status:', :white)} It #{status_check} and #{ood_check} out of date.

EOINFO
          end
        end
      end
    end
    threads.each { |t| t.join }
  end
end
