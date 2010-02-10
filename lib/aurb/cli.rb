#!/usr/bin/env ruby
# encoding: utf-8

require 'thor'
require File.expand_path(File.dirname(__FILE__) + '/../aurb')

module Aurb
  class CLI < Thor
    ARGV   = ::ARGV.dup

    map '-d' => :download
    map '-s' => :search
    map '-u' => :upgrade

    desc 'download "PACKAGES"', 'Download packages'
    method_option :path,
                  :type    => :string,
                  :default => File.join(ENV[:HOME], 'abs'),
                  :banner  => 'Specify the path to download to'
    def download(pkgs)
      pkgs = Aurb.aur.download(pkgs.split)

      puts 'No downloadable packages found' and return if pkgs.blank?

      opts = options.dup
      path = opts[:path][0] == '/' ? opts[:path] : File.join(Dir.pwd, opts[:path])
      if File.exist?(path)
        path = File.expand_path(path)
      else
        raise AurbDownloadError, "'#{path}' is not a valid path"
      end

      pkgs.each_with_index do |package, index|
        local = package.split('/')[-1]

        Dir.chdir path do
          open package do |remote|
            File.open local, 'wb' do |local|
              local.write remote.read
            end
          end
          Archive::Tar::Minitar.unpack(
            Zlib::GzipReader.new(File.open(local, 'rb')), Dir.pwd
          )
          File.delete local
        end

        puts "(#{index+1}/#{pkgs.size}) downloaded #{local}"
      end
    end

    desc 'search "PACKAGES"', 'Search for packages'
    def search(pkgs)
      pkgs = Aurb.aur.search(pkgs.split)

      puts 'No results found' and return if pkgs.blank?

      pkgs.each do |package|
        status = package.OutOfDate == '1' ? '✘'.colorize(:red) : '✔'.colorize(:green)
        name, version, description = package.Name.colorize(:yellow),
                                     package.Version,
                                     package.Description

        puts "[#{status}] #{name} (#{version})\n    #{description}"
      end
    end

    desc 'upgrade', 'Search for upgrades to installed packages'
    def upgrade
      list = `pacman -Qm`.split(/\n/)
      pkgs = Aurb.aur.upgrade(list)

      puts 'Nothing to upgrade' and return if pkgs.blank?

      pkgs.each do |package|
        puts "#{package.colorize(:yellow)} has an upgrade available"
      end
    end
  end
end
