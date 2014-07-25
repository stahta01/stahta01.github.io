--[[ "MicroControls.lua"
    Extension Information:
        Name: Micro Controls
        Version: 1.0
        Author: Marcel Hinsch
        Website: http://addons.videolan.org/content/show.php?content=160547
        Description: A small Controll Window to Control your VLC Player. More Features to come.
]]--

--[[
    INSTALLATION:
    Put the file in the VLC subdir /lua/extensions, by default:
    * Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
    * Windows (current user): %APPDATA%\VLC\lua\extensions\
    * Linux (all users): /usr/share/vlc/lua/extensions/
    * Linux (current user): ~/.local/share/vlc/lua/extensions/
    * Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/
    (create directories if they don't exist)
    Restart the VLC.
    USAGE:
    Load some Songs in your Playlist and start a song.
    Then you simply use the extension by going to the "View" menu and selecting it there.
    You can then hide VLC in your taskbar by clicking the little Pylon Symbol in your tray once.
--]]

--[[
    
    Copyright © 2013 Marcel Hinsch (Wolvan)
     
     Authors:  Marcel Hinsch (Wolvan)
     Contact: http://addons.videolan.org/messages/?action=newmessage&username=Wolvan
     
     This program is free software; you can redistribute it and/or modify
     it under the terms of the GNU General Public License as published by
     the Free Software Foundation; either version 2 of the License, or
     (at your option) any later version.
     
     This program is distributed in the hope that it will be useful,
     but WITHOUT ANY WARRANTY; without even the implied warranty of
     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
     GNU General Public License for more details.
     
     You should have received a copy of the GNU General Public License
     along with this program; if not, write to the Free Software
     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
]]--

--[[
    Array that safes all dialog objects for use in the script
]]--
d = {}


--[[
    VLC-Event Functions
]]--
function descriptor()
	return {
        title = "Micro Controls";
        version = "1.0";
        author = "Wolvan";
        url = 'http://addons.videolan.org/content/show.php?content=160547';
        shortdesc = "Small Controls for VLC.";
        description = "<div style=\"background-color:lightgreen;\"><b>Micro Controls</b> is VLC extension that allows you to control VLC using a compact GUI.</div><br><br><b>Usage</b><br>Load some Songs in your Playlist and start a song.<br>Then you simply use the extension by going to the 'View' menu and selecting it there.<br>You can then hide VLC in your taskbar by clicking the little Pylon Symbol in your tray once.";
        capabilities = {"input-listener"}
    }
end
function activate()
    lg("Starting Micro Controls Panel v1.0")
	createMainDialog()
end
function deactivate()
    closeMC()
end
function close()
    closeMC()
end
function input_changed()
    lg("Input changed", 3)
    updateNowPlaying()
end
function meta_changed()
    --stub
end
function playing_changed()
    --stub
end

--[[
    Custom Functions
]]--

function lg(s, t)
    if t == nil then
        t = 0
    end
    
    text = "[Micro Controls]["..os.date("%c").."]"..s
    
    if t == 0 then
        vlc.msg.info(text)
    elseif t == 1 then
        vlc.msg.err(text)
    elseif t == 2 then
        vlc.msg.warn(text)
    elseif t == 3 then
        vlc.msg.dbg(text)
    end
end

function closeMC()
    lg("Stoping Micro Controls Panel v1.0")
    --d.mainDialog:delete()
    vlc.deactivate()
end

function play()
    vlc.playlist.play()
    d.mainDialog:del_widget(d.button_playPause)
    d.button_playPause = d.mainDialog:add_button("Pause", pause, 1, 3)
end

function pause()
    vlc.playlist.pause()
    d.mainDialog:del_widget(d.button_playPause)
    d.button_playPause = d.mainDialog:add_button("Play", play, 1, 3)
end

function stop()
    vlc.playlist.stop()
    d.mainDialog:del_widget(d.button_playPause)
    d.button_playPause = d.mainDialog:add_button("Play", play, 1, 3)
end

function nextItem()
    vlc.playlist.next()
end

function previousItem()
    vlc.playlist.prev()
end

function updateNowPlaying()
    d.label_nowPlaying:set_text("Now Playing: "..vlc.input.item():name())
    d.mainDialog:set_title("Micro Controls v1.0 - "..vlc.input.item():name())
end


function createMainDialog()
    
    d.mainDialog = vlc.dialog("Micro Controls v1.0 - "..vlc.input.item():name())
    local dialog = d.mainDialog
    
    d.label_nowPlaying = dialog:add_label("Now Playing: "..vlc.input.item():name(), 1, 1, 2, 1)
    d.label_controls = dialog:add_label("Player Controls", 1, 2, 2, 1)
    if vlc.playlist.status() == "stopped" or vlc.playlist.status() == "paused" then
        d.button_playPause = dialog:add_button("Play", play, 1, 3)
    else
        d.button_playPause = dialog:add_button("Pause", pause, 1, 3)
    end
    d.button_stop = dialog:add_button("Stop", stop, 2, 3)
    d.button_previous = dialog:add_button("<<", previousItem, 3, 3)
    d.button_next = dialog:add_button(">>", nextItem, 4, 3)
    d.label_playlist = dialog:add_label("Goto Track", 1, 5, 2, 1)
    d.dropDown_playlist = dialog:add_dropdown(1, 6, 2, 1)
    for k,v in pairs(vlc.playlist.get("playlist",false).children) do
        d.dropDown_playlist:add_value(v.name, v.id)
    end
    d.button_goto = dialog:add_button("Goto Track", gotoTrack, 3, 6, 2, 1)
    d.divider_002 = dialog:add_label("", 1, 7, 2, 1)
    d.button_exit = dialog:add_button("Exit", closeMC, 1, 8, 4, 1)
    
    
    dialog:update()
    dialog:show()
    updateNowPlaying()
    
end

function gotoTrack()
    vlc.playlist.goto(d.dropDown_playlist:get_value())
end