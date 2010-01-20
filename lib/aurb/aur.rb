#!/usr/bin/env ruby
# encoding: utf-8
#
#--
# Copyright protects this work.
# See LICENSE file for details.
#++

module Aurb
  module Aur
    def self.included(klass)
      klass.class_eval { extend ClassMethods }
    end

    module ClassMethods
      def search(*args)
        puts args
      end

      private
        # See if a package is available in the community repository.
        def in_community?(package)
          Dir["/var/lib/pacman/sync/community/#{package}-*"].any?
        end

        # Shortcut to the +Yajl+ JSON parser.
        def parse_json(json)
          Yajl::Parser.new.parse(open(json).read)
        end
      # private
    end
  end
end
