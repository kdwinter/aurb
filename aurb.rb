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

['logger', File.dirname(__FILE__) + '/lib/methods',
           File.dirname(__FILE__) + '/lib/options'].each do |lib|
  require lib
end

module AurB
  extend self

  Name    = 'AurB'
  Version = [0, 2, 3]

  Log = Logger.new(STDOUT)
  Log.level = Logger::WARN
  Log.debug('Created logger')

  def run
    Log.debug('Started AurB')

    trap(:INT) { exit 0 }

    begin
      optparse(ARGV)
    rescue OptionParser::InvalidOption => ivo
      Log.warn("#{ivo}. Please only use the following:")
      optparse(['-h'])
    rescue OptionParser::AmbiguousOption => amo
      Log.warn("#{amo}. Please check argument syntax.")
      optparse(['-h'])
    rescue Exception => exp
      Log.fatal('Something bad just happened.')
      Log.fatal(exp)
    end

    case $options[:command]
    when :download
      aur_get(ARGV)
    when :build
      aur_get(ARGV)
    when :search
      aur_search(ARGV)
    when :info
      aur_info(ARGV)
    else
      Log.warn('Unrecognized command.')
      optparse(['-h'])
    end
  end
end

AurB.run #if $0 == __FILE__
