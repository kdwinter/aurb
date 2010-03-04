#!/usr/bin/env ruby
# encoding: utf-8

module Aurb
  module CoreExt
    module Object
      # An object is blank if it's false, empty or a whitespace string.
      def blank?
        respond_to?(:empty?) ? empty? : !self
      end
    end
  end
end

Object.send :include, Aurb::CoreExt::Object
