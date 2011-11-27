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
    attr_accessor :downloader
    
    def applicationDidFinishLaunching(a_notification)
        @startButton.setEnabled(false)
        @saveInto.stringValue = NSHomeDirectory()+"/Pictures"
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
            @output.setString('')
            @downloader = Downloader.new(@tags.stringValue,@size.selectedItem.title,@number.stringValue,@saveInto.stringValue,self)
            @downloader.start
            @startButton.setTitle("Stop Download")
        else
            @downloader.stop
            @downloader = nil
            @startButton.setTitle("Start Download")
        end
    end
    
    def puts(val)
        $stdout.puts "adding to log"
        storage = @output.textStorage
        
        storage.beginEditing
        storage.appendAttributedString(NSAttributedString.alloc.initWithString(val+"\n"))
        storage.endEditing
        
        $stdout.puts "added to log"
    end
    
    def stopped
        @startButton.setTitle("Start Download")
        down = @downloader
        @downloader = nil
        down.stop
    end
end

