#!/usr/bin/env ruby
# encoding: utf-8

module Aurb
  class Aur
    # Compare package versions.
    #
    #   Version.new('1.0.0') < Version.new('2.0.0') # => true
    #   Version.new('1.1-1') < Version.new('1.0-6') # => false
    class Version
      include Comparable

      attr_reader :version

      def initialize(*args)
        @version = args.join('.').split(/\W+/).map(&:to_i)
      end

      def <=>(other)
        [self.version.size, other.version.size].max.times do |i|
          c = self.version[i] <=> other.version[i]
          return c if c != 0
        end
      end
    end

    # Search the AUR for given +packages+.
    # Returns an array of results.
    #
    #   search('aurb') # => [{:ID => ..., :Name => 'aurb', ...}, {...}]
    def search(*packages)
      packages.map do |package|
        list_search_results(package)
      end.flatten.delete_if(&:blank?)
    end

    # Download +packages+ from the AUR.
    # Returns an array of downloadable package urls.
    #
    #   download('aurb') # => ['http://.../aurb.tar.gz']
    def download(*packages)
      packages.map do |package|
        Aurb.aur_download_path URI.escape(package.to_s)
      end.select do |package|
        !!(open package rescue false)
      end.delete_if(&:blank?)
    end

    # Returns a +list+ of names of packages that have an upgrade
    # available to them, which could then in turn be passed on to
    # the +download+ method.
    #
    #   # With Aurb on the AUR as version 1.1.2-1
    #   upgrade('aurb 0.0.0-0', 'aurb 0.9.9-9') # => [:aurb]
    def upgrade(*list)
      upgradables = []
      list.inject([]) do |ary, line|
        ary << Thread.new do
          name, version = line.split
          next if Dir["/var/lib/pacman/sync/community/#{name}-#{version}"].any?
          upgradables << name.to_sym if upgradable?(name, version)
        end
      end.each(&:join)
      upgradables.delete_if(&:blank?)
    end

  protected

    # Compare version of local +package+ with the one on the AUR.
    def upgradable?(package, version)
      local_version  = Version.new(version)
      remote_version = nil
      parse_json Aurb.aur_rpc_path(:info, package.to_s) do |json|
        return if json.type =~ /error/
        remote_version = Version.new(json.results.Version)
      end
      remote_version && local_version < remote_version
    end

    # Returns an array containing a hash of search results
    # for a given +package+.
    def list_search_results(package)
      json = parse_json(Aurb.aur_rpc_path(:search, URI.escape(package.to_s)))
      return [] if json.type =~ /error/
      ids = json.results.map(&:ID)
      results = []
      ids.inject([]) do |ary, id|
        ary << Thread.new do
          parse_json Aurb.aur_rpc_path(:info, id) do |json|
            next if json.type =~ /error/
            results << json.results.symbolize_keys
          end
        end
      end.each(&:join)
      results
    end

  private

    # Shortcut to the +Yajl+ JSON parser.
    def parse_json(json)
      json = Yajl::Parser.new.parse(open(json).read)
      yield json rescue json
    end
  end
end
