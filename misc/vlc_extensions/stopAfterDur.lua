-- playlistduration.lua -- VLC extension --
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
Then you simply use the extension by going to the "View" menu and selecting it.
--]]


--[[
CHANGELOG:
1.0 : init
1.1 : corrects a major bug which occurred when the track changed
--]]

-- defaults
duration = "00:30:00"
callback=false
input_lost = false
input_id = 0

function descriptor()
	return { title = "stop after duration" ;
		version = "1.1" ;
		author = "Timothée Lhuillier" ;
		url = '';
		shortdesc = "stop after duration";
		description = "Stop the playing after a time" ;
	}
end

function activate()
	w = vlc.dialog("Player Duration")
	w:add_label("Total time:", 1, 1, 1, 2)
	w:add_label(playlist_duration(), 2, 1, 1, 2)
	w:add_label("Elapsed time:", 1, 3, 1, 2)
	playdur = w:add_text_input(duration,2, 3, 1, 2)
	w:add_button("Start", start, 1, 5, 1, 1)
	w:add_button("Stop", stop, 2, 5, 1, 1)
	w:show()
end

function deactivate()
	input_callback("del")
end

function close()
	vlc.deactivate()
end

function meta_changed()
	if (input_lost or input_id ~= vlc.playlist.current()) and vlc.object.input() then
		vlc.msg.dbg("restart callback")
		input_callback("del")
		input_callback("add")
		input_lost = false
	elseif not vlc.object.input() then
		input_lost = true
	end
	if vlc.object.input() then
		input_id = vlc.playlist.current()
	end
end

-----------------------------------
-- part that stop after duration --
-----------------------------------

function start()
	duration = playdur:get_text()
	secDuration = toTimestamp(duration)
	remaining = secDuration
	startTime = getTimestamp()
	play()
	input_callback("add")
end

function stop()
	input_callback("del")
	pause()
end

function input_callback(action)  -- action=add/del/toggle
	if (action=="toggle" and callback==false) then action="add"
	elseif (action=="toggle" and callback==true) then action="del" end

	local input = vlc.object.input()
	if input and callback==false and action=="add" then
		callback=true
		vlc.var.add_callback(input, "intf-event", input_events_handler, "stop-after-duration")
	elseif input and callback==true and action=="del" then
		callback=false
		vlc.var.del_callback(input, "intf-event", input_events_handler, "stop-after-duration")
	end
end

function input_events_handler(var, old, new, data)
	if vlc.playlist.status()=="playing" then
		remaining = secDuration - (getTimestamp() - startTime)
		if remaining >= 0 then
			playdur:set_text(dur_to_str(remaining))
			w:update()
		end
		if remaining <= 0 then
			stop()
		end
	else
		secDuration = remaining
		startTime = getTimestamp()
	end
end

----------------------------------------------
-- end of the part that stop after duration --
----------------------------------------------

------------------------------------------
-- calculation of the playlist duration --
------------------------------------------

function playlist_duration()
	local sum = 0
	local play_list = vlc.playlist.get("playlist",false)
	for k, item in pairs(play_list.children) do
		if item.duration ~= -1 then
			sum = sum + item.duration
		end
	end
	return dur_to_str(sum)
end

-----------------------------------------------------
-- end of the calculation of the playlist duration --
-----------------------------------------------------

---------
-- lib --
---------

function split(s, delimiter)
	local result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end

-- t=table, i=start, j=end
function reverse(t, i, j)
	while i < j do
		t[i], t[j] = t[j], t[i]
		i, j = i+1, j-1
	end
end

function dur_to_str(duration)
	local h, m, s = dur_to_time(duration)
	return tostring(string.format("%02d:%02d:%02d", h, m, s))
end

function dur_to_time(duration)
	if duration>0 then
		local durationHour = math.floor(duration / 3600)
		local durationMinute = math.floor((duration % 3600) / 60)
		local durationSecond = math.floor(duration % 60)
		return durationHour, durationMinute, durationSecond
	else
		return 0, 0, 0
	end
end

function toTimestamp(inTime)
	local splitInTime = split(inTime, ":")
	reverse(splitInTime, 1, table.getn(splitInTime))
	local outTimestamp = 0
	if table.getn(splitInTime)>=3 then
		outTimestamp = outTimestamp + (splitInTime[3] * 3600)
	end
	if table.getn(splitInTime)>=2 then
		outTimestamp = outTimestamp + (splitInTime[2] * 60)
	end
	if table.getn(splitInTime)>=1 then
		outTimestamp = outTimestamp + splitInTime[1]
	end
	return outTimestamp
end

function getTimestamp()
	local secondsPassed = os ~= nil and os.time() or tick()
	return secondsPassed
end

-- compensation of a bug that the lecture is not detected when it's launch by vlc.playlist.start()
function play()
	if vlc.playlist.status()~="playing" then
		vlc.playlist.pause()
	end
end

function pause()
	if vlc.playlist.status()~="paused" then
		vlc.playlist.pause()
	end
end
----------------
-- end of lib --
----------------
