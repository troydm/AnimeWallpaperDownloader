#
#  AppDelegate.rb
#  AnimeWallpaperDownloader
#
#  Created by Dmitry Geurkov on 11/27/11.
#  Copyright 2011 __MyCompanyName__. All rights reserved.
#

class AppDelegate
    attr_accessor :window
    attr_accessor :tags
    attr_accessor :size
    attr_accessor :number
    attr_accessor :saveInto
    attr_accessor :startButton
    attr_accessor :output
    attr_accessor :downprogress
    attr_accessor :downloader
    attr_accessor :img
    
    def applicationDidFinishLaunching(a_notification)        
        @startButton.setEnabled(false)
        @downprogress.setStringValue('')
        @output.setStringValue('')
        @saveInto.stringValue = NSHomeDirectory()+"/Pictures"
    end
    
    def windowWillClose(a_notification)
        NSApp.terminate(self)
    end
    
    def controlTextDidChange(notification)
        sender = notification.object
        if sender == tags
            @startButton.setEnabled(@tags.stringValue.size > 0)
        elsif sender == number
            begin
                @number.setIntValue(@number.intValue)
                if @number.intValue < 0
                    @number.setIntValue(-@number.intValue)
                elsif @number.intValue == 0
                    @number.setIntValue(20)
                end
            rescue
                @number.setIntValue(20)
            end            
        end
    end
    
    def browse(sender)
        dialog = NSOpenPanel.openPanel
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.allowsMultipleSelection = false
        
        if dialog.runModalForDirectory(nil, file:nil) == NSOKButton
            @saveInto.stringValue = dialog.filenames.first
        end
    end
    
    def startStop(sender)
        if @downloader == nil
            @downloader = Downloader.new(@tags.stringValue,@size.selectedItem.title,@number.stringValue,@saveInto.stringValue,self)
            @downloader.start
            @startButton.setTitle("Stop Download")
        else
            @downloader.stop
            @downloader = nil
            @startButton.setTitle("Start Download")
        end
    end
    
    def changeImage(file)
        @img.setImage(NSImage.alloc.initByReferencingFile(file))
    end
    
    def clearStatus
        @downprogress.setStringValue('')
    end
    
    def setStatus(i,m)
        @downprogress.setStringValue("Downloading "+i.to_s()+" of "+m.to_s())
    end
    
    def setStatusEnd(i)
        @downprogress.setStringValue("Downloaded "+i.to_s()+" wallpapers")
    end
    
    def puts(val)
        $stdout.puts val      
        @output.setStringValue(val)
    end
    
    def stopped
        @startButton.setTitle("Start Download")
        down = @downloader
        @downloader = nil
        down.stop
    end
end

