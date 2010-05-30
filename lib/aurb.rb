#!/usr/bin/env ruby
# encoding: utf-8

$LOAD_PATH.unshift File.expand_path(__FILE__)

require 'open-uri'

require 'zlib'
require 'yajl'
require 'archive/tar/minitar'

module Aurb # :nodoc:
  autoload :Aur, 'aurb/aur'

  class AurbError < StandardError; end
  class DownloadError < AurbError; end
  class NoResultsError < AurbError
    def initialize(message = 'No results found'); end
  end

  class << self
    def aur_rpc_path(type, arg)
      "http://aur.archlinux.org/rpc.php?type=#{type}&arg=#{arg}"
    end

    def aur_download_path(pkg)
      "http://aur.archlinux.org/packages/#{pkg}/#{pkg}.tar.gz"
    end

    def aur
      @aur ||= Aur.new
    end
  end
end

require 'aurb/core_ext'
