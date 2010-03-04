#!/usr/bin/env ruby
# encoding: utf-8

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__))

require 'logger'
require 'open-uri'

require 'zlib'
require 'yajl'
require 'ansi'
require 'archive/tar/minitar'

module Aurb #:nodoc:
  autoload :Aur, 'aurb/aur'

  class AurbError < StandardError
    def self.status_code(code = nil)
      return @code unless code
      @code = code
    end

    def status_code
      self.class.status_code
    end
  end

  class AurbDownloadError < AurbError; status_code(10); end
  class AurbArgumentError < AurbError; status_code(12); end

  class << self
    def logger
      @logger ||= Logger.new(STDOUT)
    end

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

require 'aurb/support'
