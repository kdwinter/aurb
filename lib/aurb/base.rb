#!/usr/bin/env ruby
# encoding: utf-8

module Aurb
  # Generic Aurb error class.
  class Error < StandardError; end

  # Raised when a download location wasn't found.
  class DownloadError < Error; end

  # Raised when a search returns no results.
  class NoResultsError < Error
    def initialize
      super('No results found')
    end
  end

  # The path to save downloaded packages to.
  SavePath = '~/abs'

  # The URL to retrieve package info from.
  SearchPath = lambda {|t, a| "http://aur.archlinux.org/rpc.php?type=#{t}&arg=#{a}"}

  # The URL to retrieve packages from.
  DownloadPath = lambda {|p| "http://aur.archlinux.org/packages/#{p}/#{p}.tar.gz"}

  # Main Aurb class, interacting with the AUR.
  module Base
    extend self

    # Compare package versions.
    #
    #   Version.new('1.0.0') < Version.new('2.0.0') # => true
    #   Version.new('1.1-1') < Version.new('1.0-6') # => false
    class Version
      include Comparable

      attr_reader :version

      def initialize(*args)
        @version = args.join('.').split(/\W+/).map &:to_i
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
      results = []

      packages.inject([]) { |ary, package|
        ary << Thread.new do
          package = URI.escape(package.to_s)

          parse_json Aurb::SearchPath[:search, package] do |json|
            next if json.type =~ /error/
            results << json.results
          end
        end
      }.each &:join

      results.flatten.delete_if &:blank?
    end

    # Download +packages+ from the AUR.
    # Returns an array of downloadable package urls.
    #
    #   download('aurb') # => ['http://.../aurb.tar.gz']
    def download(*packages)
      packages.map { |package|
        Aurb::DownloadPath[URI.escape(package.to_s)]
      }.select { |package|
        !!(open package rescue false)
      }.delete_if &:blank?
    end

    # Returns all available info for a given package name.
    #
    #   info('aurb') # => {:ID => ..., :Name => 'aurb', ...}
    def info(package)
      package = URI.escape(package.to_s)

      parse_json Aurb::SearchPath[:info, package] do |json|
        return if json.type =~ /error/
        json.results
      end
    end

    # Returns a +list+ of names of packages that have an upgrade
    # available to them, which could then in turn be passed on to
    # the +download+ method.
    #
    #   # With Aurb on the AUR as version 1.1.2-1
    #   upgrade('aurb 0.0.0-0', 'aurb 9.9.9-9') # => [:aurb]
    def upgrade(*list)
      upgradables = []

      list.inject([]) { |ary, line|
        ary << Thread.new do
          name, version = line.split

          next if Dir["/var/lib/pacman/sync/community/#{name}-#{version}"].any?
          upgradables << name.to_sym if upgradable?(name, version)
        end
      }.each &:join

      upgradables.delete_if &:blank?
    end

  protected

    # Shortcut to the +Yajl+ JSON parser.
    def parse_json(json)
      json = Yajl::Parser.new.parse(open(json).read)
      block_given? ? yield(json) : json
    end

  private

    # Compare version of local +package+ with the one on the AUR.
    def upgradable?(package, version)
      package        = URI.escape(package.to_s)
      local_version  = Version.new(version)
      remote_version = nil

      parse_json Aurb::SearchPath[:info, package] do |json|
        return if json.type =~ /error/
        remote_version = Version.new(json.results.Version)
      end

      remote_version and local_version < remote_version
    end
  end

  # Check if +Base+ responds to this unknown method and delegate the method to
  # +Base+ if so.
  def self.method_missing(method, args, &block)
    if Base.respond_to?(method)
      Base.send method, *args, &block
    else
      super
    end
  end
end
