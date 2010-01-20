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
      # Search the AUR for given *packages*.
      # Returns an array of results.
      #
      #   search(['aurb']) # => [{:ID => ..., :Name => 'aurb', ...}, {...}]
      def search(packages)
        if packages.is_a?(Array)
          results = packages.map do |package|
            list_search_results(package)
          end.flatten
        elsif packages.is_a?(String) || packages.is_a?(Symbol)
          results = list_search_results(packages)
        else
          raise AurbError, 'Invalid search arguments'
        end

        results
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

        # Returns an array containing a hash of search results
        # for a given +package+.
        def list_search_results(package)
          json = parse_json(Aurb.aur_path(:search, URI.escape(package.to_s)))
          ids  = json.results.map(&:ID)
          results = []

          ids.each do |id|
            json     = parse_json(Aurb.aur_path(:info, id))
            result   = json.results.symbolize_keys
            results << result unless in_community?(result[:Name])
          end

          results
        end
      # private
    end
  end
end
