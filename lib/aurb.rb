#!/usr/bin/env ruby
# encoding: utf-8

require 'open-uri'
require 'zlib'
require 'yajl'
require 'archive/tar/minitar'

module Aurb
  autoload :Aur, File.expand_path('../aurb/aur', __FILE__)

  class AurbError < StandardError; end
  class DownloadError < AurbError; end
  class NoResultsError < AurbError
    def initialize
      super('No results found')
    end
  end

  class << self # :nodoc:
    def aur_rpc_path(type, arg)
      "http://aur.archlinux.org/rpc.php?type=#{type}&arg=#{arg}"
    end

    def aur_download_path(pkg)
      "http://aur.archlinux.org/packages/#{pkg}/#{pkg}.tar.gz"
    end

    def aur
      @_aur ||= Aur.new
    end
  end
end

require File.expand_path('../aurb/core_ext', __FILE__)
