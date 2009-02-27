#!/usr/bin/env ruby
=begin

  Description: AurB is a Ruby AUR utility, heavily inspired by `arson'
               and `yaourt'.
  Author: Gigamo <gigamo@gmail.com>
  License: WTFPL <http://sam.zoy.org/wtfpl/>

    This program is free software. It comes without any warranty, to
    the extent permitted by applicable law. You can redistribute it
    and/or modify it under the terms of the Do What The Fuck You Want
    To Public License, Version 2, as published by Sam Hocevar. See
    http://sam.zoy.org/wtfpl/COPYING for more details.

=end

['pathname', 'optparse'].each do |lib|
  require lib
end

module AurB
  extend self

  $options = {}

  def optparse(args)
    Log.debug('Parsing options')
    opts = OptionParser.new do |opts|
      opts.banner = "#{colorize(Name, :yellow)} v#{Version.join('.')}, a Ruby AUR utility."
      opts.separator "Usage: #{colorize($0, :yellow)} [options] <command>"

      opts.separator ""
      opts.separator "where <command> is one of:"

      opts.on('-D', '--download', 'Download the package specified') do
        $options[:command] ||= :download
      end
      opts.on('-B', '--build', 'Download and build the package specified') do
        $options[:command] ||= :build
      end
      opts.on('-S', '--search', 'Search for the package specified') do
        $options[:command] ||= :search
      end
      opts.on('-Q', '--query', 'Retrieve information for the package specified') do
        $options[:command] ||= :info
      end

      opts.separator ""
      opts.separator "where [options] is one of:"

      opts.on('--save-to [PATH]', 'Directory to save to') do |h|
        h = (h[0...1] == '/' ? h : "#{Dir.pwd}/#{h}")
        if File.exists?(h)
          $options[:download_dir] = Pathname.new(h).realpath
        else
          Log.fatal("#{h} doesn't exist. Please choose an existing directory.")
          exit 1
        end
      end

      opts.separator ""
      opts.separator "other:"

      opts.on_tail('-v', '--version', 'Show AurB version') do
        puts "#{colorize(Name, :yellow)} v#{Version.join('.')}"
        exit
      end
      opts.on_tail('-h', '--help', 'Show this message') do
        Log.debug('Showing help')
        puts opts
        puts <<EOMHELP
dependencies:
    package: rubygems
    gems: facets, json
EOMHELP
        exit
      end
    end.parse!(args)

    unless $options[:download_dir]
      Log.warn('No download directory given, falling back to default')
      $options[:download_dir] = Pathname.new(Dir.pwd).realpath
    end
  end
end
