#!/usr/bin/env ruby
# encoding: utf-8

module Aurb
  module CoreExt
    module String
      # Colors a string with +color+.
      # Uses the ANSICode library provided by +facets+.
      #
      #   "Hello".colorize(:blue) # => "\e[34mHello\e[0m"
      #
      # For more information on available effects, see
      # http://facets.rubyforge.org/apidoc/api/more/classes/ANSICode.html
      def colorize(effect)
        ANSI::Code.send(effect.to_sym) << self << ANSI::Code.clear
      rescue
        self
      end
    end
  end
end

String.send :include, Aurb::CoreExt::String
