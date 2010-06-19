#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems' if RUBY_DESCRIPTION =~ /rubinius/i
require 'thor'
require File.expand_path('../../aurb', __FILE__)

module Aurb
  class CLI < Thor
    ARGV = ::ARGV.dup

    map %w[-d --download] => :download,
        %w[-s --search]   => :search,
        %w[-u --upgrade]  => :upgrade,
        %w[-v --version]  => :version

    desc 'download PACKAGES', 'Download packages'
    method_option :path,
                  :type    => :string,
                  :default => File.join(ENV['HOME'], 'abs'),
                  :banner  => 'Specify the path to download to'
    method_option :keep,
                  :type    => :boolean,
                  :banner  => 'Keep the tarball after downloading'
    def download(*pkgs)
      pkgs = Aurb.aur.download(*pkgs)
      raise Aurb::NoResultsError if pkgs.blank?

      path = options.path.start_with?('/') ? options.path : File.join(Dir.pwd, options.path)

      if File.exist?(path)
        path = File.expand_path(path)
      else
        raise Aurb::DownloadError, "'#{path}' is not a valid path"
      end

      pkgs.each_with_index do |package, index|
        local = package.split('/')[-1]

        Dir.chdir path do
          open package do |remote|
            File.open local, 'wb' do |local|
              local.write remote.read
            end
          end

          Archive::Tar::Minitar.
            unpack Zlib::GzipReader.new(File.open(local, 'rb')), Dir.pwd
          File.delete local unless options.keep?
        end

        puts "(#{index+1}/#{pkgs.size}) downloaded #{local}"
      end
    end

    desc 'search PACKAGES', 'Search for packages'
    def search(*pkgs)
      pkgs = Aurb.aur.search(*pkgs)
      raise Aurb::NoResultsError if pkgs.blank?

      pkgs.each do |package|
        status = package.OutOfDate == '1' ? '✘'.colorize(:red) : '✔'.colorize(:green)
        name, version, description, votes =
          package.Name.colorize(:yellow), package.Version, package.Description, package.NumVotes.colorize(:blue)

        puts "[#{status}] #{name} #{version} (#{votes})\n    #{description}"
      end
    end

    desc 'info PACKAGE', 'List all available information for a given package'
    def info(pkg)
      info = Aurb.aur.info(pkg)
      raise Aurb::NoResultsError if info.blank?

      info.each do |key, value|
        (key.size..10).each { print ' ' }
        print key.colorize(:yellow) + ' '
        puts value
      end
    end

    desc 'upgrade', 'Search for upgrades to installed packages'
    def upgrade
      list = `pacman -Qm`.split(/\n/)
      pkgs = Aurb.aur.upgrade(*list)
      raise Aurb::NoResultsError if pkgs.blank?

      pkgs.each do |package|
        puts "#{package.to_s.colorize(:yellow)} has an upgrade available"
      end
    end

    desc 'version', 'Show version and exit'
    def version
      require 'aurb/version'
      require 'thor/version'
      puts "Aurb v#{Aurb::VERSION} - Thor v#{Thor::VERSION}"
      puts 'Copyright (c) 2009-2010 Gigamo <gigamo@gmail.com>'
    end
  end
end
