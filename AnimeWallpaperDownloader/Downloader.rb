#
#  Downloader.rb
#  AnimeWallpaperDownloader
#
#  Created by Dmitry Geurkov on 11/27/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#
require 'thread'
require 'net/http'

class Downloader
  attr_accessor :tags, :size, :number, :saveTo, :thread, :app, :exit

  def initialize(tags, size, number, saveTo, app)
      @tags = tags.sub(' ', '_')
      @size = size == 'Any' ? '' : size.sub('x', '_')
      @number = number
      @saveTo = saveTo
      @app = app
      @exit = false
  end

  def response(url)
    Net::HTTP.get_response(URI.parse(url)).body
  end

  def getIndexPage(page)
    walls = {}

    url = "http://www.theotaku.com/wallpapers/tags/#{tags}/?sort_by=&resolution=#{size}&date_filter=&category=&page=#{page}"

    @app.puts "getting index for page: #{page}"
    @app.puts url

    res = response(url)
    res.each_line do |line|
        f = line.index('wallpapers/view')

        while f != nil
          b = line.rindex('"',f)
          e = line.index('"',b+1)
          u = line[b+1,e-b].gsub('"','')
          walls[u] = u
          line = line.sub(u,'')
          f = line.index('wallpapers/view')
        end
    end

    @app.puts "got #{walls.size} wallpapers"

    return walls.keys
  end

  def downloadWall(url)
    @app.puts "downloading #{url}"
    res = response(url)
    b = res.index('src',res.rindex('wall_holder'))+5
    e = res.index('"',b)
    img = res[b,e-b]

    self.downloadFile(img)
  end

  def downloadFile(url)
    name = url[url.rindex('/')+1, 1000]

    if File.exists?(@saveTo+'/'+name)
      @app.puts "wallpaper already saved #{name}"
      @app.changeImage(@saveTo+'/'+name)
    else
      @app.puts "downloading file #{url}"

      open(@saveTo+'/'+name, 'wb') { |file| file.write(response(url)) }

      @app.puts "wallpaper saved #{name}"
      @app.changeImage(@saveTo+'/'+name)
    end
  end

  def getWallUrl(i, url, size)
    sizes = {}
    i = i+1

    @app.puts "getting #{url} sizes"

    res = response(url)
    res.each_line do |line|
        f = line.index('wallpapers/download')

        while f != nil
          b = line.rindex('\'', f)
          e = line.index('\'', b+1)
          u = line[b+1, e-b]
          u = u.gsub('\'', '')
          sizes[u] = u
          line = line.sub(u, '')
          f = line.index('wallpapers/download')
        end
    end

    sizef = @size.sub('_','-by-')
    sizes = sizes.keys

    if sizef == ''
      maxi, max, i  = 0, 0, 0

      sizes.each do |s|
        f = s.rindex('/')
        l = s[f+1, 100].sub('-by-', ' ').split(' ')

        rs = l[0].to_i * l[1].to_i

        maxi, max = i, rs if rs > max

        i = i+1
      end

      return sizes[maxi]
    else
      sizes.each { |s| return s if s =~ /#{Regexp.escape(sizef)}$/ }
    end

    return sizes[0]
  end

  def start
    @thread = Thread.new do
      @app.puts 'Download started'
      begin
        i, p = 0, 1
        @app.clearStatus

        while i < @number.to_i() and not @exit
          w = self.getIndexPage(p)
          break if w.empty?
          w.each do |w|
            wallu = self.getWallUrl(i, w, self.size)

            unless wallu.nil?
              @app.setStatus(i+1, @number.to_i())
              self.downloadWall(wallu)
              i = i+1
              break if i >= @number.to_i or @exit
            end
          end
          p = p + 1
        end
      @app.puts ""
      @app.setStatusEnd(i)
      rescue => e
        puts e
      end
      @app.stopped
    end
  end

  def stop
    begin
      @app.puts 'Download stopped'
      if @thread.alive?
        if @thread == Thread.current
          Thread.exit(0)
        else
          @exit = true
        end
      end
    rescue => e
      puts e
    end
  end
end
