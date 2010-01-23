#!/usr/bin/env ruby
# encoding: utf-8
#
#--
# Copyright protects this work.
# See LICENSE file for details.
#++

module Aurb
  module Version
    MAJOR = '1'
    MINOR = '0'
    TINY  = '1'

    def self.to_s
      [MAJOR, MINOR, TINY].join('.').freeze
    end
  end
end
