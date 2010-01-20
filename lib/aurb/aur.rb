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
        Aurb.logger.debug list_search_results('aurb').inspect
      end

      private
        # See if +package+ is available in the community repository.
        def in_community?(package)
          Dir["/var/lib/pacman/sync/community/#{package}-*"].any?
        end

        # Shortcut to the +Yajl+ JSON parser.
        def parse_json(json)
          Yajl::Parser.new.parse(open(json).read)
        end

        # Returns a hash of search results for a given +package+.
        def list_search_results(package)
          json = parse_json(Aurb.aur_path(:search, URI.escape(package))).symbolize_keys
          ids  = json[:results].map(&:ID)
          results = []

          ids.each do |id|
            json     = parse_json(Aurb.aur_path(:info, id)).symbolize_keys
            result   = json[:results].symbolize_keys
            results << result unless in_community?(result[:Name])
          end

          results
        end
      # private
    end
  end
end
