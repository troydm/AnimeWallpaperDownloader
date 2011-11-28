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
    attr_accessor :tags, :size, :number, :saveTo, :thread
    attr_accessor :app, :exit
    def initialize(tags, size, number, saveTo, app)
        @tags = tags.sub(' ','_')
        @size = size == 'Any' ? '' : size.sub('x','_') 
        @number = number
        @saveTo = saveTo
        @app = app
        @exit = false
    end
    
    def getIndexPage(page)
        
        walls = {}
        
        url = 'http://www.theotaku.com/wallpapers/tags/'+tags+'/?sort_by=&resolution='+size+'&date_filter=&category=&page='+page.to_s()
        
        @app.puts 'getting index for page: '+page.to_s()
        @app.puts url
        
        response = Net::HTTP.get_response(URI.parse(url))
        
        res = response.body
        
        res.each_line { |line|
            f = line.index('wallpapers/view')
            
            while f != nil
                b = line.rindex('"',f)
                e = line.index('"',b+1)
                u = line[b+1,e-b].gsub('"','')
                walls[u] = u
                line = line.sub(u,'')
                f = line.index('wallpapers/view')
            end
        }
        
        @app.puts 'got '+walls.size.to_s()+' wallpapers'
        
        return walls.keys
        
    end
    
    def downloadWall(url)        
        @app.puts 'downloading '+url        
        response = Net::HTTP.get_response(URI.parse(url))        
        res = response.body        
        b = res.index('src',res.rindex('wall_holder'))+5
        e = res.index('"',b)
        img = res[b,e-b]
        self.downloadFile(img)
    end
    
    def downloadFile(url)
        
        name = url[url.rindex('/')+1,1000]
                
        if File.exists?(@saveTo+'/'+name)
            @app.puts 'wallpaper already saved '+name
            @app.changeImage(@saveTo+'/'+name)
        else
        
            @app.puts 'downloading file '+url
        
            response = Net::HTTP.get_response(URI.parse(url))
            open(@saveTo+'/'+name, 'wb') { |file|
                file.write(response.body)
            }
        
            @app.puts 'wallpaper saved '+name
            @app.changeImage(@saveTo+'/'+name)
        end
    end
    
    def getWallUrl(i,url,size)
        
        sizes = {}
        
        i = i+1
        
        @app.puts 'getting '+url+' sizes'
        
        response = Net::HTTP.get_response(URI.parse(url))
        
        res = response.body
        
        res.each_line { |line|
            f = line.index('wallpapers/download')
            while f != nil
                b = line.rindex('\'',f)
                e = line.index('\'',b+1)
                u = line[b+1,e-b]
                u = u.gsub('\'','')
                sizes[u] = u
                line = line.sub(u,'')
                f = line.index('wallpapers/download')
            end
        }
        
        sizef = @size.sub('_','-by-')
        sizes = sizes.keys()
        
        if sizef == ''
            maxi = 0
            max = 0
            i = 0
            sizes.each { |s|
                f = s.rindex('/')
                l = s[f+1,100]
                l = l.sub('-by-',' ')
                l = l.split(' ')
                rs = l[0].to_i()*l[1].to_i()
                if rs > max
                    maxi = i
                    max = rs
                end
                i = i+1
            }
            return sizes[maxi]
        else        
            sizes.each { |s|
                if s =~ /#{Regexp.escape(sizef)}$/
                    return s
                end
            }
        end
        
        return sizes[0]        
    end
    
    def start
        @thread = Thread.new {
            @app.puts "Download started"
            begin
                i = 0
                p = 1
                @app.clearStatus
                while i < @number.to_i() and not @exit
                    w = self.getIndexPage(p)
                    if w.size == 0
                        break
                    end
                    w.each { |w|
                        wallu = self.getWallUrl(i,w,self.size)
                        if wallu != nil
                            @app.setStatus(i+1,@number.to_i())
                            self.downloadWall(wallu)
                            i = i+1
                            if i >= @number.to_i() or @exit
                                break
                            end
                        end
                    }
                    p = p+1
                end
                @app.puts ""
                @app.setStatusEnd(i)
            rescue => e
                puts e
            end
            @app.stopped
        }
    end
    
    def stop
        begin
            @app.puts "Download stopped"
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