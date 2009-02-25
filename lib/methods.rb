#!/usr/bin/env ruby
=begin

AurB is a Ruby AUR utility, heavily inspired by `arson' and `yaourt'.
Author: Gigamo <gigamo@gmail.com>
License: WTFPL <http://sam.zoy.org/wtfpl/>

  This program is free software. It comes without any warranty, to
  the extent permitted by applicable law. You can redistribute it
  and/or modify it under the terms of the Do What The Fuck You Want
  To Public License, Version 2, as published by Sam Hocevar. See
  http://sam.zoy.org/wtfpl/COPYING for more details.

=end

['rubygems', 'zlib', 'facets/version', 'facets/minitar', 'facets/ansicode', 'json', 'cgi', 'open-uri', 'fileutils'].each do |lib|
  require lib
end

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

  def pacman_cache_check(name, version, cached=Pacman_Cache)
    $logger.debug("Checking installation status of #{name} #{version}")
    if File.exists?("#{cached}/#{name}-#{version}")
      return 'Installed'
    else
      Dir.chdir(cached) do
        installed = Dir["#{name}-*"].first
        if installed
          iv = VersionNumber.new(installed[name.length+1..-1])
          pccv = VersionNumber.new(version)
          if iv > pccv
            return 'Installed'
          elsif pccv > iv
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
      $logger.fatal("JSON error: #{json['results']}")
      exit 1
    end
    json['results'].each do |aurp|
      list << [aurp['Name'], aurp['ID']]
    end
    list.sort
  end

  def aur_search(keywords)
    $logger.debug("Searching for #{keywords.join(' & ')}")
    list = aur_list(keywords.join(' '))
    count = 0
    list.each do |values|
      info = JSON.parse(open(Aur_Info % values[1]).read)
      unless info['type'] == 'error'
        info = info['results']
        next if in_pacman_sync?(info['Name'], 'community')
        if keywords.any? do |keyword|
            info['Name'].include?(keyword) or info['Description'].include?(keyword)
          end
          $logger.debug('Succesful match')
          count += 1
          puts colorize("aur/#{info['Name']} #{info['Version']}", :yellow)
          puts colorize("   #{info['Description']}", (info['OutOfDate'] == '1' ? :red : :bold))
        end
      else
        $logger.warn("Error: #{info['results']} for package #{values[0]}")
      end
    end
    puts "\nFound #{colorize(count.to_s, :magenta)} results"
  end

  def aur_download(packages, depend=false)
    no_pkg = true
    packages.each do |pkg|
      unless File.exists?(File.join($options[:download_dir], pkg))
        list = aur_list(pkg)
        list.each do |names|
          if names[0] == pkg
            info = JSON.parse(open(Aur_Info % names[1]).read)['results']
            puts "#{colorize('Warning', :red, :bold)}: you are about to download #{colorize(pkg, :bold)}, which has been flagged #{colorize('out of date', :magenta)}!" if info['OutOfDate'] == '1'
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
                    $logger.debug("404 Error downloading #{pkg}, trying pattern")
                    open("#{Aur_Domain}/packages/#{pkg}/#{pkg}.tar.gz") do |tar|
                      File.open("#{dir}/#{pkg}.tar.gz", 'wb') do |file|
                        file.write(tar.read)
                      end
                    end
                  rescue OpenURI::HTTPError => e
                    $logger.fatal("Error downloading #{pkg}: #{e.message}")
                    no_pkg = false
                    exit 1
                  end
                else
                  $logger.fatal("Error downloading #{pkg}: #{e.message}")
                  no_pkg = false
                  exit 1
                end
              end
              $logger.debug("Extracting #{pkg}.tar.gz")
              tgz = Zlib::GzipReader.new(File.open("#{pkg}.tar.gz", 'rb'))
              Archive::Tar::Minitar.unpack(tgz, Dir.pwd)

              FileUtils.rm("#{pkg}.tar.gz") if File.exists?("#{pkg}.tar.gz")
            end
          end
        end
        if no_pkg and not depend
          $logger.fatal("Error: #{pkg} not found.")
          exit 1
        end
      else
        $logger.fatal("Error: #{$options[:download_dir]}/#{pkg} already exists.")
        exit 1
      end
    end
  end

  def aur_info(names)
    names.each do |name|
      $logger.debug("Retrieving package information for #{name}")
      aur_list(name).each do |pkg|
        if pkg[0] == name
          json = JSON.parse(open(Aur_Info % pkg[1]).read)['results']
          not_ood = (json['OutOfDate'] == '0' ? 'is not' : colorize('is', :red))
          inst_upg_info = "is #{colorize('not installed', :green)}" if pacman_cache_check(json['Name'], json['Version']) == 'Not installed'
          inst_upg_info = "is #{colorize('installed', :green)}" if pacman_cache_check(json['Name'], json['Version']) == 'Installed'
          inst_upg_info = "has an #{colorize('upgrade', :blue)} available" if pacman_cache_check(json['Name'], json['Version']) == 'Upgradable'

          puts <<EOINFO
Name:        #{colorize("#{json['Name']} #{json['Version']}" , :yellow)}
Description: #{json['Description']}
Homepage:    #{json['URL']}
License:     #{json['License']}
Votes:       #{colorize(json['NumVotes'], :green)}
OOD:         It #{not_ood} out of date.
Status:      #{json['Name']} #{inst_upg_info}
EOINFO
        end
      end
    end
  end
end
