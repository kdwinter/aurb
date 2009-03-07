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
  Version = [0, 5, 3]

  def run!(args=ARGV)
    STDOUT.puts "#{Util.colorize('WARNING', :black, :on_yellow)}: Running as root is dangerous." if ENV['USER'] == 'root'

    trap('SIGINT') do
      STDOUT.puts "#{Util.colorize('ERROR', :on_red)}: Received SIGINT, exiting."
      exit 0
    end

    begin
      Opts.parse(args)
    rescue OptionParser::InvalidOption => ivo
      STDOUT.puts "#{Util.colorize('WARNING', :black, :on_yellow)}: #{ivo}. Please only use the following:"
      Opts.parse(['-h'])
    rescue OptionParser::AmbiguousOption => amo
      STDOUT.puts "#{Util.colorize('WARNING', :black, :on_yellow)}: #{amo}. Please check argument syntax."
      Opts.parse(['-h'])
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
      STDOUT.puts "#{Util.colorize('WARNING', :black, :on_yellow)}: #{args}: Unrecognized command."
      Opts.parse(['-h'])
    end
  end
end
