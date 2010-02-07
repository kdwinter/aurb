#!/usr/bin/env ruby
# encoding: utf-8
#
#--
# Copyright protects this work.
# See LICENSE file for details.
#++

module Aurb
  class Aur
    # Search the AUR for given +packages+.
    # Returns an array of results.
    #
    #   search(['aurb']) # => [{:ID => ..., :Name => 'aurb', ...}, {...}]
    def search(packages)
      packages.map do |package|
        list_search_results(package)
      end.flatten.delete_if(&:blank?)
    end

    # Download +packages+ from the AUR.
    # Returns an array of downloadable package urls.
    #
    #   download(['aurb']) # => ['http://.../aurb.tar.gz']
    def download(packages)
      url = lambda {|p| "http://aur.archlinux.org/packages/#{p}/#{p}.tar.gz"}

      packages.map do |package|
        url.call(URI.escape(package.to_s))
      end.select do |package|
        downloadable?(package)
      end.delete_if(&:blank?)
    end

    # Returns a +list+ of names of packages that have an upgrade
    # available to them, which could then in turn be passed on to
    # the +download+ method.
    #
    #   # With Aurb on the AUR as version [0, 8, 2, 1]
    #   upgrade(['aurb 0.0.0.0', 'aurb 0.9.9.9']) # => [:aurb]
    def upgrade(list)
      upgradables = []

      list.each do |line|
        name, version = line.split
        next if in_community?(name)
        upgradables << name.to_sym if upgradable?(name, version)
      end

      upgradables
    end

    protected

    # See if +package+ is available in the community repository.
    def in_community?(package)
      Dir["/var/lib/pacman/sync/community/#{package}-*"].any?
    end

    # Check if +package+ is available for download.
    def downloadable?(package)
      open package rescue false
    end

    # Compare version of local +package+ with the one on the AUR.
    def upgradable?(package, version)
      json = parse_json(Aurb.aur_path(:info, package.to_s))
      return if json.type =~ /error/
      remote_package = json.results

      local_version  = VersionNumber.new(version)
      remote_version = VersionNumber.new(remote_package.Version)

      local_version < remote_version
    end

    # Returns an array containing a hash of search results
    # for a given +package+.
    def list_search_results(package)
      json = parse_json(Aurb.aur_path(:search, URI.escape(package.to_s)))
      return if json.type =~ /error/
      ids  = json.results.map(&:ID)
      results = []

      ids.each do |id|
        json     = parse_json(Aurb.aur_path(:info, id))
        next if json.type =~ /error/
        result   = json.results.symbolize_keys
        results << result unless in_community?(result[:Name])
      end

      results
    end

    private

    # Shortcut to the +Yajl+ JSON parser.
    def parse_json(json)
      Yajl::Parser.new.parse(open(json).read)
    end
  end
end
