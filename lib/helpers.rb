#!/usr/bin/env ruby

['rubygems', 'facets/ansicode', 'logger'].each do |lib|
  require lib
end

module AurB
  $logger = Logger.new($stdout)
  $logger.level = Logger::DEBUG
  $logger.debug('Created logger')

  def self.colorize(string, *effects)
    colored = ' '
    effects.each do |effect|
      colored << ANSICode.send(effect)
    end
    colored << string << ANSICode.clear
    colored[1..-1]
  end
end
