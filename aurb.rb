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

['pathname', 'logger', File.dirname(__FILE__) + '/lib/methods', File.dirname(__FILE__) + '/lib/options'].each do |lib|
  require lib
end

module AurB
  extend self

  Name    = 'AurB'
  Version = [0, 1, 1]

  $logger = Logger.new($stdout)
  $logger.level = Logger::DEBUG
  $logger.debug('Created logger')

  def run
    $logger.debug('Started AurB')

    trap(:INT) { exit 0 }

    optparse(ARGV)

    case $options[:command]
    when :download
      aur_download(ARGV)
    when :search
      aur_search(ARGV)
    when :info
      aur_info(ARGV)
    else
      $logger.fatal('Unrecognized command. See --help for info.')
    end
  end
end

AurB.run if $0 == __FILE__
