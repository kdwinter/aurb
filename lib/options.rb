#!/usr/bin/env ruby

require 'optparse'

module AurB
  extend self

  $options = {}

  def optparse(args)
    $logger.debug('Parsing options')
    opts = OptionParser.new do |opts|
      opts.banner = "#{colorize(Name, :yellow)} v#{Version.join('.')}, a Ruby AUR utility."
      opts.separator "Usage: #{colorize($0, :yellow)} [options] <command>"

      opts.separator ""
      opts.separator "where <command> is one of:"

      opts.on('-D', '--download', 'Install the package specified') do
        $options[:command] ||= :download
      end
      opts.on('-S', '--search', 'Search for the package specified') do
        $options[:command] ||= :search
      end
      opts.on('-I', '--info', 'Retrieve information for the package specified') do
        $options[:command] ||= :info
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
end
