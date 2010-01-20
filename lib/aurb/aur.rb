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
      # Search the AUR for given +packages+.
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
          raise AurbArgumentError
        end

        results
      end

      # Download +packages+ from the AUR.
      # Returns an array of downloadable packages.
      #
      #   download(['aurb']) # => ['http://.../aurb.tar.gz']
      def download(packages)
        if packages.is_a?(Array)
          url = ->(p) {"http://aur.archlinux.org/packages/#{p}/#{p}.tar.gz"}

          downloadables = packages.map do |package|
            url.call(package)
          end.select do |package|
            downloadable?(package)
          end
        else
          raise AurbArgumentError
        end

        downloadables
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

        # Check if +package+ is available for download.
        def downloadable?(package)
          open package rescue false
        end

        # Compare version of local +package+ with the one on the AUR.
        def upgrade_available?(package, version)
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