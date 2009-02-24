#!/usr/bin/env ruby
=begin

AurB is a Ruby AUR utility.
Author: Gigamo <gigamo@gmail.com>
License: WTFPL <http://sam.zoy.org/wtfpl/>

=end

['optparse', 'pathname', 'lib/methods', 'lib/helpers'].each do |lib|
  require lib
end

module AurB
  Name         = 'AurB'
  Version      = [0, 0, 1]
  Aur_Domain   = 'http://aur.archlinux.org'
  Aur_Search   = "#{Aur_Domain}/rpc.php?type=search&arg=%s"
  Aur_Info     = "#{Aur_Domain}/rpc.php?type=info&arg=%s"
  Abs_Domain   = 'http://archlinux.org/packages/search/?category=all&limit=99000'

  class Opts
    $options = {}

    def self.parse(args)
      $logger.debug('Parsing options')
      opts = OptionParser.new do |opts|
        opts.banner = "#{AurB.colorize(Name, :yellow)} v#{Version.join('.')}, a Ruby AUR utility."
        opts.separator "Usage: #{AurB.colorize($0, :yellow)} <options>"
        opts.separator 'where <options> is one of:'
        opts.on('-D', '--download', 'Install the package specified') do |s|
          $options[:command] ||= :download
          $options[:package] ||= s
        end
        # opts.on('-Q', '--query', 'Retrieve information for the package specified') do |q|
        # end
        # opts.on('-R', '--remove', 'Remove the package specified') do |r|
        # end
        # opts.on('-U', '--upgrade', 'Install local *.pkg.tar.gz specified') do |u|
        # end
        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
      end
      opts.parse!(args)
    end

    unless $options[:download_dir]
      $logger.warn('No download directory given, falling back')
      $options[:download_dir] = Pathname.new(Dir.pwd).realpath
    end
  end

  def self.run
    $logger.debug('Started AurB')
    trap(:INT) { exit 0 }

    begin
      Opts.parse(ARGV)
    rescue OptionParser::InvalidOption => e
      $logger.debug('Invalid Option')
      puts AurB.colorize("#{e.to_s.capitalize}. Please use only the following:", :red)
      Opts.parse(['-h'])
    rescue OptionParser::AmbiguousOption => e
      $logger.debug('AmbigiousOption')
      puts AurB.colorize("#{e.to_s.capitalize}. Please make sure that you have only one short argument, regardless of case.", :red)
      Opts.parse(['-h'])
    end

    if $options[:command] == :download
      AurB.aur_download($options[:package])
    end
  end
end

AurB.run if $0 == __FILE__
