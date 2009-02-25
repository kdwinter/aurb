#!/usr/bin/env ruby

['rubygems', 'zlib', 'facets/version', 'facets/minitar', 'json', 'cgi', 'open-uri', 'fileutils'].each do |lib|
  require lib
end

module AurB
  extend self

  Aur_Domain   = 'http://aur.archlinux.org'
  Aur_Search   = "#{Aur_Domain}/rpc.php?type=search&arg=%s"
  Aur_Info     = "#{Aur_Domain}/rpc.php?type=info&arg=%s"
  Abs_Domain   = 'http://archlinux.org/packages/search/?category=all&limit=99000'
  Pacman_Sync  = '/var/lib/pacman/sync/%s'
  Pacman_Cache = '/var/lib/pacman/local'
  Pacman_Conf  = '/etc/pacman.conf'

  def json_open(url)
    $logger.debug('Opening JSON url')
    JSON.parse(open(url).read)
  end

  def in_pacman_sync?(name, repo)
    repo = Pacman_Sync % repo
    true if Dir["#{repo}/#{name}-*"].first
  end

  def aur_list(name)
    json = json_open(Aur_Search % CGI::escape(name))
    list = []

    if json['type'] == 'error'
      $logger.fatal('JSON error')
      puts colorize("Error: #{json['results']}", :red)
      exit 1
    end
    json['results'].each do |aurp|
      list << [aurp['Name'], aurp['ID']]
    end
    list.sort
  end

  def aur_download(packages, depend=false)
    no_pkg = true
    packages.each do |pkg|
      unless File.exists?(File.join($options[:download_dir], pkg))
        list = aur_list(pkg)
        list.each do |names|
          if names[0] == pkg
            info = json_open(Aur_Info % names[1])['results']
            puts "#{colorize('Warning', :red, :bold)}: you are about to download #{colorize(pkg, :bold)}, which has been flagged #{colorize('out of date', :magenta)}!" if info['OutOfDate'] == '1'
            FileUtils.chdir($options[:download_dir]) do |dir|
              begin
                no_pkg = false
                if in_pacman_sync?(pkg, 'community')
                  $logger.debug("Found package #{pkg} in the community repository. Handing this to pacman..")
                  puts "Found package #{colorize(pkg, :bold)} in the community repository. Handing this to pacman.."
                  exec "sudo pacman -S #{pkg}"
                else
                  $logger.debug("Found #{depend ? 'dependency' : 'package'} #{pkg}! Downloading..")
                  puts "Found #{depend ? 'dependency' : 'package'} #{colorize(pkg, :bold)}! Downloading.."
                  open("#{Aur_Domain}/#{info['URLPath']}") do |tar|
                    File.open("#{dir}/#{pkg}.tar.gz", 'wb') do |file|
                      file.write(tar.read)
                    end
                  end
                end
              rescue OpenURI::HTTPError => e
                if e.message.include?('404')
                  begin
                    no_pkg = false
                    $logger.debug("404 Error downloading #{pkg}, trying pattern")
                    open("#{Aur_Domain}/packages/#{pkg}/#{pkg}.tar.gz") do |tar|
                      File.open("#{dir}/#{pkg}.tar.gz", 'wb') do |file|
                        file.write(tar.read)
                      end
                    end
                  rescue OpenURI::HTTPError => e
                    $logger.fatal("Error downloading #{pkg}: #{e.message}")
                    puts colorize("Error downloading #{pkg}: #{e.message}", :red)
                    no_pkg = false
                    exit 1
                  end
                else
                  $logger.fatal("Error downloading #{pkg}: #{e.message}")
                  puts colorize("Error downloading #{pkg}: #{e.message}", :red)
                  no_pkg = false
                  exit 1
                end
              end
              $logger.debug("Extracting #{pkg}.tar.gz")
              tgz = Zlib::GzipReader.new(File.open("#{pkg}.tar.gz", 'rb'))
              Archive::Tar::Minitar.unpack(tgz, Dir.pwd)

              FileUtils.rm("#{pkg}.tar.gz") if File.exists?("#{pkg}.tar.gz")
            end
          end
        end
        if no_pkg and not depend
          $logger.fatal("Error: #{pkg} not found.")
          puts colorize("Error: #{pkg} not found.", :red)
        end
      else
        $logger.fatal("Error: #{$options[:download_dir]}/#{pkg} already exists.")
        puts colorize("Error: #{$options[:download_dir]}/#{pkg} already exists.", :red)
      end
    end
  end
end
