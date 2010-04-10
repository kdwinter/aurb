#!/usr/bin/env ruby
# encoding: utf-8

module Aurb
  module CoreExt
    module String
      COLORS = [:gray, :red, :green, :yellow, :blue, :purple, :cyan, :white]

      # Colors a string with +color+.
      #
      #   "Hello".colorize(:blue)
      def colorize(effect)
        if STDOUT.tty? && ENV['TERM']
          "\033[0;#{30+COLORS.index(effect.to_sym)}m#{self}\033[0m"
        else
          self
        end
      rescue
        self
      end
    end
  end
end

String.send :include, Aurb::CoreExt::String
