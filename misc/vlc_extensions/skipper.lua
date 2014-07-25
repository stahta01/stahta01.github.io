--[[
INSTALLATION:
Put the .lua file in the VLC subdir /lua/extensions, by default:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\VLC\lua\extensions\
* Linux (all users): /usr/lib/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
(create directories if they don't exist)
Restart the VLC.

USAGE:
Then you simply use the extension by going to the "View" menu and selecting it there.
--]]

-- defaults
skip_begin = 0
skip_end = 0
ignore_first = false
is_first = true
mypl = nil

-- Feel free to enter your favourite episodes in the format {"Name",Start,End} and to share those numbers on the addon page http://addons.videolan.org/content/show.php?content=159976.
predefined={{"---",0,0,false},{"Game of Thrones",203,78,false},{"Dexter",106,45,false},{"House of Cards",54,114,true}}



function descriptor()
	return {
		title = "Intro and credits Skipper";
		version = "0.9";
		author = "Bergur Hallgrimsson";
		url = 'http://addons.videolan.org/content/show.php?content=159976';
		shortdesc = "Skip intro";
		description = "Define the length of intro and credits for your favourite episode. Queue them up in the playlist and jump right into the episode and avoid having to see the intro and credits.";
		capabilities = {"input-listener"}
	}
end

function activate()
	vlc.msg.dbg ("[skip intro] activated")
	create_dialog()
	local input = vlc.object.input()
	
	mypl = vlc.playlist.get("playlist", false).children
	if input then
		vlc.var.add_callback(input, "intf-event", input_event_handler, "Hello world!")
	end	
end

function deactivate()
	local input = vlc.object.input()	
	vlc.var.del_callback(input, "intf-event", input_event_handler, "Hello world!")
end

function close()
	vlc.deactivate()
end

function meta_changed()
end

function input_changed()
	vlc.msg.dbg ("[skip intro] input changed")
	local input = vlc.object.input()	
	
	mypl = vlc.playlist.get("playlist", false).children	
	if input then
		if skip() then
			vlc.var.set(input, "time", skip_begin)		
		end
		vlc.var.add_callback(input, "intf-event", input_event_handler, "Hello world!")
	end
end

function input_event_handler(var, old, new, data)
	local input = vlc.object.input()	
	
	duration = vlc.input.item():duration()
	elapsed_time = vlc.var.get(input, "time")
	timetoskip = duration-skip_end	
				
	
--	vlc.msg.dbg("[Skip intro] time-to-skip" .. timetoskip)
--	vlc.msg.dbg("[Skip intro] current-time" .. elapsed_time)
--	vlc.msg.dbg("[Skip intro] playlist-size" .. #mypl)	
--	vlc.msg.dbg("[Skip intro] item id " .. inspect(vlc.playlist.get("playlist", false)))
	
		
	if elapsed_time > timetoskip and #mypl > 1 then
		vlc.playlist.next()
	elseif (elapsed_time > timetoskip) then
		vlc.playlist.stop()
	end
end

function create_dialog()	
	d = vlc.dialog("Skipper")	
	w1 = d:add_label("Skip intro [s]:",1,3,1,1)
	w2 = d:add_text_input(skip_begin,2,3,1,1)
	w3 = d:add_label("Skip credits [s]:",1,4,1,1)
	w4 = d:add_text_input(skip_end,2,4,1,1)	
	w5 = d:add_button("Save and close", click_Save,1,6,2,1)	
	
	w6 = d:add_label("Predefined episodes:",1,1,2,1)	
	w7 = d:add_dropdown(1,2,1,1)
	for i,predefined in pairs(predefined) do
		w7:add_value(predefined[1], i)
	end		
	w8 = d:add_button("Apply", click_Apply,2,2,1,1)
	
	w9 = d:add_check_box("Ignore first episode",ignore_first,1,5,2,1)	
end

function click_Save()
	skip_begin = tonumber(w2:get_text())
	skip_end = tonumber(w4:get_text())
	ignore_first = w9:get_checked()
		
	local input = vlc.object.input()
		
	if input then		
		if skip() then
			vlc.var.set(input, "time", skip_begin)		
		end
	end
	d:delete()
end

function click_Apply()
	local predefined = predefined[w7:get_value()]
	w2:set_text(predefined[2])
	w4:set_text(predefined[3])
	w9:set_checked(predefined[4])
	d:update()
end

function skip()
	if mypl then
		first_id = mypl[1]['id']
		current_id = (vlc.playlist.current() == -1) and first_id or (vlc.playlist.current()-1)
		is_first = (first_id == current_id)
		
		str_isFirst = is_first and "true" or "false"
		str_ignore_first = ignore_first and "true" or "false"
			
		vlc.msg.dbg("[Skip intro] playlist_size " .. #mypl)
		vlc.msg.dbg("[Skip intro] current_id " .. current_id)
		vlc.msg.dbg("[Skip intro] first_id " .. first_id)		
		vlc.msg.dbg("[Skip intro] is_first " .. str_isFirst)
		vlc.msg.dbg("[Skip intro] ignore_first" .. str_ignore_first)				
	end
	return not (ignore_first and is_first)
 end
