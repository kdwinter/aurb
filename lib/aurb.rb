#!/usr/bin/env ruby
# encoding: utf-8

require 'open-uri'
require 'zlib'
require 'yajl'
require 'archive/tar/minitar'

libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require 'aurb/base'
require 'aurb/core_ext'
