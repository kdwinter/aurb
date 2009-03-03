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

require 'logger'
require 'aurb/methods'
require 'aurb/options'

module AurB
  extend self

  Name    = 'AurB'
  Version = [0, 6, 1]

  def run!(args=ARGV)
    trap('SIGINT') do
      Log.fatal('Received SIGINT, exiting.')
      exit 0
    end

    begin
      optparse(args)
    rescue OptionParser::InvalidOption => ivo
      STDOUT.puts "WARNING: #{ivo}. Please only use the following:"
      optparse(['-h'])
    rescue OptionParser::AmbiguousOption => amo
      STDOUT.puts "WARNING: #{amo}. Please check argument syntax."
      optparse(['-h'])
    end

    case $options[:command]
    when :download
      $options[:source] ? abs_get($options[:source], args) : aur_get(args)
    when :build
      $options[:source] ? abs_get($options[:source], args) : aur_get(args)
    when :search
      aur_search(args)
    when :info
      aur_info(args)
    else
      STDOUT.puts "WARNING: #{args}: Unrecognized command."
      optparse(['-h'])
    end
  end
end
