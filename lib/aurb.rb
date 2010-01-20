#!/usr/bin/env ruby
# encoding: utf-8
#
#--
# Copyright protects this work.
# See LICENSE file for details.
#++

require 'pathname'
require 'zlib'
require 'open-uri'
require 'yajl'
require 'facets/ansicode'
require 'facets/minitar'
require 'facets/version'

module Aurb
  # Generic Aurb error.
  class AurbError < StandardError; end

  # Make a +Logger+ object available.
  def self.logger
    require 'logger' unless defined?(Logger)
    @logger ||= Logger.new(STDOUT)
  end

  def self.aur_path(type, arg)
    "http://aur.archlinux.org/rpc.php?type=#{type}&arg=#{arg}"
  end
end

$LOAD_PATH.unshift File.dirname(__FILE__)
require 'aurb/support'
require 'aurb/aur'
require 'aurb/version'
