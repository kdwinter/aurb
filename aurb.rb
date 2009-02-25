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

['optparse', 'pathname', 'rubygems', 'facets/ansicode', 'logger', File.dirname(__FILE__) + '/lib/methods'].each do |lib|
  require lib
end

module AurB
  extend self

  Name         = 'AurB'
  Version      = [0, 0, 1]

  $logger = Logger.new($stdout)
  $logger.level = Logger::DEBUG
  $logger.debug('Created logger')

  def colorize(string, *effects)
    colored = ' '
    effects.each do |effect|
      colored << ANSICode.send(effect)
    end
    colored << string << ANSICode.clear
    colored[1..-1]
  end

  $options = {}

  def optparse(args)
    $logger.debug('Parsing options')
    opts = OptionParser.new do |opts|
      opts.banner = "#{colorize(Name, :yellow)} v#{Version.join('.')}, a Ruby AUR utility."
      opts.separator "Usage: #{colorize($0, :yellow)} [options] <command>"

      opts.separator ""
      opts.separator "where <command> is one of:"

      opts.on('-D', '--download', 'Install the package specified') do |s|
        $options[:command] ||= :download
      end

      opts.separator ""
      opts.separator "where [options] is one of:"

      opts.on('--save-to [PATH]', 'Directory to save to', 'Default: current directory') do |h|
        h = (h[0...1] == '/' ? h : "#{Dir.pwd}/#{h}")
        if File.exists?(h)
          $options[:download_dir] = Pathname.new(h).realpath
        else
          $logger.fatal("Error: #{h} doesn't exist. Please choose an existing directory.")
          puts "Error: #{h} doesn't exist. Please choose an existing directory."
          exit 1
        end
      end

      opts.separator ""
      opts.separator "other:"

      opts.on_tail('-h', '--help', 'Show this message') do
        $logger.debug('Showing help')
        puts opts
        puts <<EOMHELP
dependencies:
  - package: rubygems
  - gems: facets, json
EOMHELP
        exit
      end
    end.parse!(args)

    unless $options[:download_dir]
      $logger.warn('No download directory given, falling back to default')
      $options[:download_dir] = Pathname.new(Dir.pwd).realpath
    end
  end

  def run
    $logger.debug('Started AurB')
    trap(:INT) { exit 0 }

    begin
      optparse(ARGV)
    rescue OptionParser::InvalidOption => e
      $logger.debug('Invalid Option')
      puts colorize("#{e.to_s.capitalize}. Please use only the following:", :red)
      optparse(['-h'])
    rescue OptionParser::AmbiguousOption => e
      $logger.debug('AmbigiousOption')
      puts colorize("#{e.to_s.capitalize}. Please make sure that you have only one short argument, regardless of case.", :red)
      optparse(['-h'])
    end

    if $options[:command] == :download
      AurB.aur_download(ARGV)
    end
  end
end

AurB.run if $0 == __FILE__
