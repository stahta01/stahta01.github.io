-- clipper.lua -- VLC extension
--[[
INSTALLATION:
Put the file in the VLC subdir /lua/extensions, by default:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\VLC\lua\extensions\
* Linux (all users): /usr/share/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/
(create directories if they don't exist)
Restart the VLC or in the VLC "Tools | Plugins and Extensions" item,
select "Reload Extensions"

USAGE:
	Go to the "View" menu and select "Clipper".
	Click the "Help" button for detailed instructions.

TESTED SUCCESSFULLY ON:
	VLC 2.1.2 on Windows 8.1
	VLC 2.0.8 on Kubuntu 12.04

LICENSE:
	GNU General Public License version 2
--]]

-- globals:
clipper_items = {}
no_time = "--:--"
frame_rate = nil

time_steps = { -- values to increment/decrement show time
	{"1 sec.", 1},
	 -- actual time step for frames will be calculated from media's FramesPerSecond
	{"1 frame", 0.03333},
	{"10 sec.", 10},
	{"1 min.", 60}
	}

active=false

function descriptor()
	return {
		title = "Clipper";
		version = "1.0";
		author = "Brian Courts";
		url = 'to be determined';
		shortdesc = "Read, modify and write M3U playlists for portions (clips) of files.";
		description = "Clipper is a VLC extension (extension script \"clipper.lua\") to read, modify and write M3U playlists for portions (clips) of files.";
		capabilities = {"input-listener"}
	}
end

function activate()

	dir_sep = package.config:sub(1,1) or '/'
	create_dialog()

	-- vlc.playlist.current() gives playlist item's id + ID_OFFSET
	-- We need to determine the value of ID_OFFSET to adjust (or not) the
	-- value returned by vlc.playlist.current().
	-- In early version of VLC the ID_OFFSET was 1
	-- In those early versions, Lua extensions could access vlc.misc
	-- In later versions, ID_OFFSET is 0, and extensions cannot access vlc.misc
	-- I don't know whether the correlation is perfect, but it works on
	-- 2.08 (ID_OFFSET = 1) and 2.12 (ID_OFFSET = 0)

	if vlc.misc then
		ID_OFFSET = 1
	else
		ID_OFFSET = 0
	end

	input_active("add")
end

function deactivate()
	input_active("del")
end

function close()
	vlc.deactivate()
end

function input_changed()
	input_active("toggle")
end

function meta_changed()
end

function input_active(action)  -- action=add/del/toggle

	if (action=="toggle" and active==false) then action="add"
	elseif (action=="toggle" and active==true) then action="del" end

	local input = vlc.object.input()
	if input and active==false and action=="add" then
		active=true
		show_init()
	elseif input and active==true and action=="del" then
		active=false
	end
end

function get_frame_rate(input_item)

	local info = input_item:info()
	for k, v in pairs(info) do
		for k2, v2 in pairs(v) do
			if (k2 == "Frame rate") then
				frame_rate = tonumber(v2)
				return frame_rate
			end
		end
	end
	frame_rate = nil
	return frame_rate
end

function show_init()
	local curr_id = current_id()
	if (curr_id < 0) then
		return
	end

	local cl_item = get_clipper_item(curr_id)
	-- some items in the playlist may have start and and
	-- stop times, so show them
	local start_t = cl_item.start
	local curr_item = vlc.playlist.get(curr_id)
	get_frame_rate(vlc.input.item())
	item_name_fld:set_text(cl_item.name or curr_item.name)
	start_time_lbl:set_text(string_from_seconds(start_t))
	stop_time_lbl:set_text(string_from_seconds(cl_item.stop))
	set_time("show_init", (start_t or 0))
	--show_duration()
end

function show_time()
	local show_t = 0
	local show_str = show_time_fld:get_text()
	if (not show_str) or (show_str == no_time) or (show_str == "") then
		show_t = current_time()
	else
		show_t  = seconds_from_string(show_str)
		if (not show_t) then
			local time_err = "'"..show_str.."' not valid time"
			show_time_fld:set_text(time_err)
			error(time_err)
			return
		end
		local duration = get_duration()
		if (show_t < 0) then
			-- negative show_t means go back from end of the clip
			show_t = duration + show_t
			if (show_t < 0) then
				-- don't go too far back
				show_t = 0
			end
		elseif (show_t > duration) then
			show_t = duration
		end
	end
	show_time_fld:set_text(string_from_seconds(show_t))
	return show_t
end

function set_time_show()

	local curr_id = current_id()
	if (curr_id < 0) then
		return
	end

	local show_t = show_time()
	set_time("show", show_t)
end

function get_time_step()
	local step_num, step_dat, time_step, step_name
	step_num = time_step_drop:get_value()

	step_dat = time_steps[step_num]

	step_name = step_dat[1]
	if frame_rate and (step_name == "1 frame") then
		if (frame_rate > 100) then
			-- assume this is a bogus or unknown frame rate
			-- try a workable frame rate
			time_step = 1 / 24
		else
			time_step = 1/ frame_rate
		end
	else
		time_step = step_dat[2]
	end

	return time_step
end

	--[[
	We decrement or increment the time here relative to the current media time.
	Some time passes while the time is set and the image shown, so the
	time shifts will not be exactly the time specified.
	For 1-frame shifts the video is paused to allow the user to see the small
	jumps, and the jumps are relative to the time in the "Show" text entry box,
	which is set by the preceding jump. By this means, the 1-frame jumps should
	be exactly 1 frame.
	]]

function show_dec()
	show_jump("dec")
end

function show_inc()
	show_jump("inc")
end

function show_jump(which)
	local curr_id = current_id()
	if (curr_id < 0) then
		return
	end
	local show_t

	local step = get_time_step()
	if (step < 1) then
		if (vlc.playlist.status() == 'playing') then
			-- first call of series with step < 1 (1-frame jump)
			-- pause the video so the user can see the small jumps
			pause_playlist()
			show_t = set_show_curr()
		else
			show_t = show_time()
		end
	else
		show_t = set_show_curr()
	end

	if (which == "dec") then
		show_t = show_t - step
		if (show_t < 0) then
			show_t = 0
		end
	elseif (which == "inc") then
		show_t = show_t + step
		local duration = get_duration()
		if (duration > 0) and (show_t > duration) then
			show_t = duration
		end
	else
		-- invalid call
		return
	end

	set_time(which, show_t)
end

function get_duration()
	local input_item = vlc.input.item()
	return input_item:duration()
end

function set_time(which, when)
	if (not when) or (when == no_time) then
		return
	end

	local input=vlc.object.input()
	if not input then
		return
	end

	if (type(when) == "string") then
		when = seconds_from_string(when)
	elseif (type(when) ~= "number") then
		when = 0
	end

	local duration = get_duration()
	local curr_id = current_id()

	if (when < 0) then
		when = 0
	else
		if (when > duration) then
			when = duration
		end
	end

	vlc.var.set(input, "time", when)
	show_time_fld:set_text(string_from_seconds(when))
end

function set_item_name()

	local curr_id = current_id()
	if (curr_id < 0) then
		return
	end

	local cl_item = get_clipper_item(curr_id)
	cl_item.name = item_name_fld:get_text()
	regen_playlist(curr_id, "set_name")
end

function create_dialog()

	-- setting the row for each set of widgets allows one to more easily
	-- add and rearrange widgets

	local row = 0
	dlg = vlc.dialog("Clipper")

	row = row + 1
	item_name_btn = dlg:add_button("Item Name =", set_item_name,1,row,1,1)
	item_name_fld = dlg:add_text_input("", 2,row,2,1)

	row = row + 1
	show_btn = dlg:add_button("Show", set_time_show, 1,row,1,1)
	show_time_fld = dlg:add_text_input(no_time, 2,row,1,1)
	show_cur_btn = dlg:add_button("Show = Curr.", set_show_curr, 3,row,1,1)

	row = row + 1
	time_step_drop = dlg:add_dropdown(1,row,1,1)
	for i, step in pairs(time_steps) do
		time_step_drop:add_value(step[1], i)
	end
	show_dec_btn = dlg:add_button("<<", show_dec, 2,row,1,1)
	show_inc_btn = dlg:add_button(">>", show_inc, 3,row,1,1)

	row = row + 1
	start_lbl = dlg:add_label("Start", 1,row,1,1)
	start_time_lbl = dlg:add_label(no_time, 2,row,1,1)
	pause_play_btn = dlg:add_button("Pause / Play", pause_or_play, 3,row,1,1)

	row = row + 1
	start_curr_btn = dlg:add_button("Start = Curr.", set_start_curr, 1,row,1,1)
	start_show_btn = dlg:add_button("Start = Show", set_start_show, 2,row,1,1)
	start_begin_btn = dlg:add_button("Start = Begin", set_start_begin, 3,row,1,1)

	row = row + 1
	stop_lbl = dlg:add_label("Stop", 1,row,1,1)
	stop_time_lbl = dlg:add_label(no_time, 2,row,1,1)
	split_btn = dlg:add_button("Split @ Curr.", split_item, 3,row,1,1)

	row = row + 1
	stop_curr_btn = dlg:add_button("Stop = Curr.", set_stop_curr, 1,row,1,1)
	stop_Show_btn = dlg:add_button("Stop = Show", set_stop_show, 2,row,1,1)
	stop_end_btn = dlg:add_button("Stop = End", set_stop_end, 3,row,1,1)

	row = row + 1
	playlist_dir_lbl = dlg:add_label("Playlist directory", 1,row,1,1)
	playlist_dir_fld = dlg:add_text_input(vlc.config.homedir(), 2,row,2,1)

	row = row + 1
	playlist_name_lbl = dlg:add_label("Playlist name", 1,row,1,1)
	playlist_name_fld = dlg:add_text_input("mylist", 2,row,1,1)
	playlist_ext_lbl = dlg:add_label(".m3u", 3,row,1,1)

	row = row + 1
	load_playlist_btn = dlg:add_button("Load Playlist", load_playlist,1,row,1,1)
	save_abs_btn = dlg:add_button("Save Absolute", save_playlist_abs,2,row,1,1)
	save_abs_btn = dlg:add_button("Save Relative", save_playlist_rel,3,row,1,1)

	row = row + 1
	help_row = row
	help_col = 3
	duration_btn = dlg:add_button("Total Duration", show_duration,1,row,1,1)
	duration_lbl = dlg:add_label("", 2,row,1,1)
	help_btn = dlg:add_button("HELP", click_HELP,help_col,row,1,1)

	dlg:update()
end

function pause_or_play()
	local input = vlc.object.input()
	if (not input) then
		return
	else
		local status = vlc.playlist.status()
		if (status == 'stopped') or (status == 'paused') then
			play_playlist()
		else
			pause_playlist()
		end
	end
end

function pause_playlist()
	vlc.playlist.pause()
end

function play_playlist()
	vlc.playlist.play()
end

function playlist_from_fields()
	local playlist_path = playlist_dir_fld:get_text()..dir_sep..playlist_name_fld:get_text()..playlist_ext_lbl:get_text()
	return playlist_path
end

function save_playlist_abs()
	save_playlist("abs")
end

function save_playlist_rel()
	save_playlist("rel")
end

function get_rel_path(rel_to, this_path, dir_sep)
	local match_pat = rel_to .. dir_sep .. "(.+)"
	local rel_path = string.match(this_path, match_pat)
	return rel_path
end

function save_playlist(mode)

	local playlist_dir = playlist_dir_fld:get_text()
	if (dir_sep ~= "/") then
	-- replace this system's path separator with the standard '/'
		playlist_dir = string.gsub(playlist_dir, dir_sep, "/")
	end

	local playlist_path = playlist_from_fields()
	io.output(playlist_path)
	local play_list = vlc.playlist.get("normal", false)
	local items = play_list.children

	local id
	local path, rel_path
	local duration
	local name
	local cl_item

	io.write("#EXTM3U\n\n")
	for key, item in pairs(items) do
		id = item.id
		local playlist_item = vlc.playlist.get(id)
		cl_item = get_clipper_item(id)

		if cl_item.start then
			io.write("#EXTVLCOPT:start-time=" .. tostring(cl_item.start) .. "\n")
		end
		if cl_item.stop then
			io.write("#EXTVLCOPT:stop-time=" .. tostring(cl_item.stop) .. "\n")
		end

		name = cl_item.name or item.name
		if name then
			if item.duration then
				duration = tostring(item.duration)
			else
				duration = ""
			end
			io.write("#EXTINF:" .. duration .."," .. name .. "\n")
		end

		if (dir_sep ~= "/") then
			-- assume this is a Windows path like "file:///D:/videos/my_video.mp4"
			path = string.match(item.path, "file:///(.*)")
		else
			path = string.match(item.path, "file://(.*)")
		end
		if not path then
			-- maybe this was an http: path
			path = item.path
		end

		-- If the playlist is going to be used by programs other than VLC, we
		-- need to decode the (URI) path, because VLC knows how to load
		-- a filename like "name%20with%20spaces.mp4"
		-- but other programs need it to be "name with spaces.mp4"
		path = vlc.strings.decode_uri(path)

		rel_path = nil
		if mode == "rel" then
			rel_path = get_rel_path(playlist_dir, path, "/")
		end

		if rel_path then
			path = rel_path
		elseif (dir_sep ~= "/") then
		-- replace standard '/' path separator with the one for this system
			path = string.gsub(path, "/", dir_sep)
		end

		io.write(tostring(path) .. "\n\n")
	end
	io.close()
end

function load_playlist()
	local playlist_path = playlist_from_fields()
	local playlist_dir = playlist_dir_fld:get_text()
	if (dir_sep ~= "/") then
		-- replace this directory separator with standard '/'
		playlist_dir = string.gsub(playlist_dir, dir_sep, "/")
	end

	local start_t = nil
	local stop_t = nil
	local name = nil
	local duration
	local directive
	local fname
	local path
	local play_list
	local cl_item = {}

	-- I'll assume a well formed input file for now
	-- TODO: add error checking
	for line in io.lines(playlist_path) do

		if not (string.match(line, "^%s*$")) then
			-- this is not a blank line, so process it
			-- handle comments and directives
			-- skip file_type line
			directive = string.match(line, "^#(.*)" )
			if directive then
				if string.match(directive, "EXTM3U:") then
					-- skip file type header
				elseif string.match(directive, "EXTINF:") then
					duration, name = string.match(directive, "EXTINF:(.*),(.*)")
					cl_item.name = name
				elseif string.match(directive, "^EXTVLCOPT:start%-time=") then
					-- '%-' required in match pattern so '-' not a magic character
					cl_item.start = tonumber(string.match(directive, "^EXTVLCOPT:start%-time=(.*)"))
				elseif string.match(directive, "^EXTVLCOPT:stop%-time=") then
					-- '%-' required in match pattern so '-' not a magic character
					cl_item.stop = tonumber(string.match(directive, "^EXTVLCOPT:stop%-time=(.*)"))
				end
				-- otherwise, assume this was a comment and skip it
			else
				path = line
				-- assume we have found a media path
				if not string.match(path, "^http") then
					if (dir_sep == "\\") then
						-- the below works for Windows file names
						-- other methods might be required for other non-*nix systems

						-- replace this directory separator with standard '/'
						path = string.gsub(line, dir_sep, "/")
						if (string.find(path, ":", 1, true)) then
							-- this is an absolute path (has drive letter, like D:)
							path = "file:///" .. path
						else
							-- this is a relative path
							-- VLC Windows needs the absolute path
							path = "file:///" .. playlist_dir .."/" .. path
						end
					else
						if (string.sub(path, 1, 1) == "/")then
							-- this is an absolute path
							path = "file://" .. path
						else
							-- this is a relative path
							path = "file://" .. playlist_dir .."/" .. path
						end
					end
				end

				cl_item.path = path
				add_playlist_item(cl_item)
				cl_item = {}

			end
		end
	end
	show_duration()
	play_list = vlc.playlist.get("normal", false)

end

function last_added_id()

	-- get the id of the just-added playlist item
	local id, just_added
	local play_list = vlc.playlist.get("normal", false)
	local items = play_list.children

	-- maximum id of playlist's children will be the one just added
	-- position in playlist may change, but the id will not
	just_added = -1
	for key, val in pairs(items) do
		id = val.id
		if id > just_added then
			just_added = id
		end
	end
	return just_added
end

function show_duration()

	local play_list = vlc.playlist.get("normal", false)
	local items = play_list.children
	local id
	local cl_item
	local duration, clipped_duration
	local total_duration = 0
	local total_clipped = 0
	local start, stop

	for key, item in pairs(items) do
		id = item.id
		cl_item = get_clipper_item(id)

		duration = item.duration
		start = cl_item.start or 0
		if (duration > 0) then
			total_duration = total_duration + duration
			stop = cl_item.stop or duration
			clipped_duration = stop - start
			total_clipped = total_clipped + clipped_duration
		else
			if cl_item.stop then
				clipped_duration = cl_item.stop - start
				total_clipped = total_clipped + clipped_duration
			end
		end
	end

	duration_lbl:set_text(string_from_seconds(total_clipped).." / "..string_from_seconds(total_duration))
end

function get_clipper_item(id)
	local cl_item = clipper_items[id]
	if (not cl_item) then
		-- this item was not added to the playlist by clipper, so clipper has no data on it.
		-- we'll add a new item, and populate it with name and path.
		local item
		cl_item = {}
		item = vlc.playlist.get(id)
		cl_item.path = item.path
		cl_item.name = item.name
		clipper_items[id] = cl_item
	end

	return cl_item
end

function get_item_ids()

	local play_list = vlc.playlist.get("normal", false)
	local items = play_list.children
	local item_ids = {}
	local i = 1
	local id

	for key, item in pairs(items) do
		id = item.id
		item_ids[i] = id
		i = i + 1
	end

	return item_ids

end

function add_playlist_item(cl_item)

	local play_list
	local playlist_item = {}

	playlist_item.path = cl_item.path
	if cl_item.name then
		playlist_item.name = cl_item.name
	end

	if cl_item.start then
		playlist_item.options = {"start-time="..cl_item.start}
	end

	if cl_item.stop then
		if (not playlist_item.options) then
			playlist_item.options = {}
		end
		table.insert(playlist_item.options, "stop-time="..cl_item.stop)
	end

	-- add the item to the playlist
	-- need to do vlc.playlist.enqueue or vlc.playlist.add() to get item into vlc's playlist
	vlc.playlist.enqueue( {playlist_item} )
	--vlc.playlist.add( {playlist_item} )

-- NOTE: after item added to playlist, it
-- does not have an accessible options field for start time and stop time
-- so we need to save that information elsewhere

	just_added = last_added_id()

	clipper_items[just_added] = cl_item
	return just_added

end

function split_item()
	local curr_id = current_id()
	if (curr_id < 0) then
		return
	end
	local curr_t = current_time()
	if (not curr_t) then
		return
	end
	local cl_item = get_clipper_item(curr_id)
	if (not cl_item) then
		return
	end
	cl_item.split = curr_t
	regen_playlist(curr_id, "split")
end

function current_id()
	local curr = vlc.playlist.current()
	if (curr < 0) then
		return curr
	end
	return curr - ID_OFFSET
end

function set_show_curr()
	local curr_t = current_time()
	if (curr_t == no_time) then
		return
	else
		show_time_fld:set_text(string_from_seconds(curr_t))
	end
	return curr_t
end

function set_start_show()
	set_start(show_time())
end

function set_start_curr()
	set_start("curr")
end

function set_start_begin()
	set_start(nil)
end

function set_start(when)

	local input = vlc.object.input()
	if (not input) then
		start_time_lbl:set_text(string_from_seconds(nil))
		return
	end

	local time = parse_time(when)
	if (time == no_time) then
		return
	end

	local curr_id = current_id()
	if (curr_id < 0) then
		return
	end
	local cl_item = get_clipper_item(curr_id)

	local stop_t = cl_item.stop
	if (stop_t and time and (stop_t > 0) and (stop_t <= time)) then
		error("Start time "..time.." must be before stop time "..stop_t)
	else
		cl_item.start = time
		start_time_lbl:set_text(string_from_seconds(time))
	end
	show_duration()
end

function set_stop_show()
	set_stop(show_time())
end

function set_stop_curr()
	set_stop("curr")
end

function set_stop_end()
	set_stop(nil)
end

function set_stop(when)
	local input = vlc.object.input()
	if not input then
		return
	end

	local time = parse_time(when)
	if (time == no_time) then
		return
	end

	local curr_id = current_id()
	local cl_item = get_clipper_item(curr_id)

	local start_t = cl_item.start
	if (start_t and time and (start_t >= time)) then
		error("Stop time "..time.." must be after start time "..start_t)
	else
		cl_item.stop = time
		stop_time_lbl:set_text(string_from_seconds(time))

		regen_playlist(curr_id, "set_stop")
	end
end

function regen_playlist(curr_id, why)
	--[[
	Some changes to playlist items are not reflected in VLC's Playlist window.
	Here we save the necessary information for each item, clear the playlist,
	then regenerate it.
	This brute force method ensures that the changes do appear.
	It should be possible to just delete one item, add one new one and move it
	into place, but the Playlist window does not seem to stay in sync with those changes.
	]]

	local restart_t = nil
	local duration

	if (why == "set_stop") then
		restart_t = current_time()
		duration = get_duration()
	end

	local play_list = vlc.playlist.get("normal", false)
	local item_ids = get_item_ids()
	-- we must get the ids in playlist order.
	-- if we loop through clipper_items directly, they may not be
	-- in playlist order

	local regen_items = {}
	local item, cl_item
	for i, id in pairs(item_ids) do
		-- Get a regen_item for each of the items in VLC's playlist.
		-- We'll need them later to regenerate the playlist
		cl_item = clipper_items[id]
		if (not cl_item) then
			-- this item was not added to the playlist by clipper, so clipper has no data on it.
			-- we'll add a new item, and populate it with name and path.
			cl_item = {}
			item = vlc.playlist.get(id)
			cl_item.path = item.path
			cl_item.name = item.name
		end
		regen_items[id] = cl_item
	end

	-- We can now start out with an empty clipper_items table.
	-- It will be filled as items are added to the playlist.
	clipper_items = {}

	local playlist_status = vlc.playlist.status()

	vlc.playlist.clear()
	local just_added
	local play_next = false
	local play_id = nil
	local cl_item
	local split_item

	for i, id in pairs(item_ids) do
		cl_item = regen_items[id]
		if (cl_item.split) then
			split_item = {}
			split_item.start = cl_item.split
			split_item.stop = cl_item.stop
			cl_item.stop = cl_item.split
			cl_item.split = nil
			split_item.path = cl_item.path
			split_item.name = cl_item.name.."(2)"
			add_playlist_item(cl_item)
			play_id = add_playlist_item(split_item)
		else
			just_added = add_playlist_item(cl_item)
		end

		if play_next then
			play_id = just_added
			play_next = false
		end

		if (id == curr_id) then
			if (why == "set_stop") then
				if (not cl_item.stop) or (restart_t < cl_item.stop) then
					-- keep playing the one where we set the stop
					play_id = just_added
				else
					play_next = true
				end
			elseif (why == "set_name") then
				play_id = just_added
			end
		end

	end

	play_list = vlc.playlist.get("normal", false)
	if (play_id) then
		vlc.playlist.goto(play_id)

		--[[
		-- it would be nice to restart the playlist as it was when we
		-- made the change (playing or paused, at the same time in the file),
		-- but the steps below do not achieve that goal.
		-- After the vlc.playlist.pause() call, the media does not pause,
		-- and plays from the beginning, even after the
		-- vlc.var.set(input, "time", restart_t) call
		]]
		--[[local input=vlc.object.input()
		if restart_t then
			vlc.var.set(input, "time", restart_t)
		end
		if (playlist_status == 'playing') then
			vlc.playlist.play()
		elseif (playlist_status == 'paused') then
			vlc.playlist.pause()
		end
		]]
	end

	show_duration()
end

function click_HELP()
	local help_text=
	[[
<style type="text/css">
body {background-color:white;}
.hello{font-family:"Arial black";font-size:48px;color:red;background-color:lime}
#header{background-color:#B7FCB7;}
.marker_red{background-color:#FFBFDA;}
.marker_green{background-color:#B7FCB7;}
.input{background-color:lightblue;}
.button{background-color:#E8E8E8;}
.tip{background-color:#FFFF7F;}
#footer{background-color:#D6ECF2;}
</style>

<body>
<div id=header><b>Clipper</b> is a VLC Extension that allows you to create, modify, load
and save playlists of clips (portions) of files</b>
</div>
<hr />

<center><b><a class=marker_red>&nbsp;Instructions&nbsp;</a></b></center>
<b>In brief:</b>
<ul>
<li>Load items into the playlist.</li>
<li>Set start and/or stop times as desired.</li>
<li>Play the clipped items.</li>
<li>Save the playlist for future enjoyment or to share.</li>
</ul>
<div class=tip><b>Note:</b> It is wise to save the playlist of clips as you
develop it, and not wait until the playlist is complete.
VLC has on occasion become unresponsive when using this
extension.
</div>
<br/>
<b>Details:</b><br/>
<b><a class=marker_red>1)</a></b>
 You can load individual files by using VLC's
 <b>Open File...</b>,
<b>Open Directory...</b> and similar menu items.
You can also drag and drop files onto the playlist.
 <b>To add items from a playlist</b>, enter that playlist's directory and file names in the
 <b class=button>Playlist directory</b> and <b class=button>Playlist name</b> text boxes,
 then press the <b class=button>[Load Playlist]</b> button.
 Clipper loads and saves playlists only in the <b>.m3u</b> format, added
 automatically to the file name.
<div class=tip><b>Note:</b> Clipper will not be aware of the
start and stop times of any items in the playlist when
Clipper begins, nor those of items in a playlist loaded by VLC <b>Open File...</b>
(before OR after Clipper starts). <b>However</b>, if the item loaded by VLC
has a stop-time
set, and the stop-time is BEFORE any stop-time set by Clipper, VLC will
stop the item at the VLC time, not the Clipper time.
</div>
<b><a class=marker_red>2)</a></b> To set start and stop times for an item, start playing it
(pause if you wish) then use a
<b class=button>[Start = ]</b> or <b class=button>[Stop = ]</b> buttons to set it at:
<ul>
<li><b class=button>Curr.</b> the current time in the file.</li>
<li><b class=button>Show</b> the time in the <b class=button>Show</b> text entry box </li>
<li><b class=button>Begin</b> or <b class=button>End</b> the beginning or end of the file</li>
</ul>
If the start or stop time is not set (shown as '<b>--:--</b>'), playback will start at the beginning
or or stop at the end of the file.<br/>
<b><a class=marker_red>3)</a></b> The <b class=button>[Split @ Curr.]</b> button
causes the item to be split into two items. The current time becomes the stop
time for one item and the start time for the next item.

<b><a class=marker_red>4)</a></b> To go to a specific time, enter that time in the
<b class=button>Show</b> text entry box, then press the <b class=button>[Show]</b> button.
Several time formats are available: 1h23m45s, 1:23:45, 1+23+45 and 5025 each mean
 "1 hour, 23 minutes and 45 seconds" from the beginning of the file.<br/>
Likewise, 1m23.45s,  1:23.45, 1+23.45 and 83.45 each mean "1 minute and 23.45 seconds"
from the beginning.<br/>
A negative value (like -1m17s) will set the time to that amount BACK from the END of the file.
<div class=tip>If you <b class=button>[Show]</b> a time PAST the stop time of the
clip, but before its end: <br/>
(a) If the media is playing, VLC will go to the next item in the playlist. <br/>
(b) If the media is paused, the media will not extend to that point, but you can press
<b class=button>[Stop = Show]</b> to set it as the stop time.</div>
<b><a class=marker_red>5)</a></b> Press the <b class=button>[&lt;&lt;]</b> or
<b class=button>[&gt;&gt;]</b> button to jump backward or forward
the time selected in the dropdown box to the left of those buttons.
The jumps are relative to the current time. If the jump time selected is 1 frame,
the video will pause to show those small jumps.<br/>
<b><a class=marker_red>6)</a></b> Press the <b class=button>[Save Absolute]</b> or
<b class=button>[Save Relative]</b> button to save the playlist in the file specified in the
<b class=button>Playlist directory</b> and <b class=button>Playlist name</b> text boxes.
Saving the playlist in the <b>Relative</b> format allows the playlist to work without
modification if it and the associated files (and directories) are moved to a
different location.<br/>
<b>Note:</b> Saving a playlist using VLC's "Save Playlist to File..." command
does not save start and stop times set by Clipper. A playlist saved by Clipper
will save the start and stop times ONLY if Clipper set them or loaded them from
a playlist.
<div class=tip><b>Caution:</b> You will not receive a warning if you are about
to overwrite an existing file.
</div>
<b><a class=marker_red>7)</a></b> To set the name of the item
as it appears in the Clipper <b class=button>Item Name</b> text entry box
each time the item is played, enter the name in that box then press the
<b class=button>[Item Name = ]</b> button. The name entered will also
appear in the playlist and on the VLC title bar unless the media file
has a "Title" defined in the file. That value can be changed in the Media
Information dialog of VLC.
<div class=tip><b>Note:</b> The changes made by Clipper to start and stop times and item names are stored
in the playlist only, not in the media files themselves.
 </div>
<b><a class=marker_red>8)</a></b> The numbers beside the
<b class=button>[Total Duration]</b> button give the total
duration of the clips and the total duration of the media files.
Some changes made by the VLC user (such as items
being added to or removed from the playlist) or by Clipper
are not immediately reflected
in those totals. To see the current totals, click the
<b class=button>[Total Duration]</b> button.
<div id=footer>
<b>Forum:</b>None so far<br/>
<b>VLC Lua scripting:</b> <a href="http://forum.videolan.org/viewtopic.php?f=29&t=98644#p330318">Getting started?</a><br />
Please, visit us and bring some new ideas.<br />
Learn how to write your own scripts and share them with us.<br />
Help to build a happy VLC community :o)
</div>
	]]
	help_html = dlg:add_html(help_text,1,help_row + 1,3,1)
	helpx_btn = dlg:add_button("HELP (x)", click_HELPx,help_col,help_row,1,1)
	dlg:update()
end

function click_HELPx()
	dlg:del_widget(help_html)
	dlg:del_widget(helpx_btn)
	help_html=nil
	helpx_btn=nil
	dlg:update()
end

------------------------ TIME FUNCTIONS --------------------------

function current_time()
	-- returns current time in the media (point to which it has been played)

	local curr_t
	local input = vlc.object.input()
	if (not input) or (vlc.playlist.status() == 'stopped') then
		curr_t = nil
	else
		curr_t = vlc.var.get(input, "time")
	end
	return curr_t
end

function parse_time(when)

	local time = no_time

	if (when == nil) or (when == no_time) then
		time = nil
	elseif (when == "curr") then
		time = current_time()
	elseif (type(when) == "string") then
		time = seconds_from_string(when)
		if (time == nil) then
			error("Invalid time string " .. when)
		end
	elseif (type(when) == "number") then
		time = when
	else
		error("Cannot parse time from " .. type(when) .. " " .. tostring(when))
	end
	return time
end

function hms_from_string(str)

	if not str then
		return nil, nil, nil
	end

	-- strip leading and trailing spaces
	str = string.match(str, "^%s*([^%s]*)%s*$")
	if not str then
		return nil, nil, nil
	end

	local pattern0 = "^(%d+%.?%d*)$"
	local pattern1a = "^(%d+):(%d+%.?%d*)$"
	local pattern1 = "^(%d+):(%d+):(%d+%.?%d*)$"
	local pattern2 = "^(%d+)[Hh](%d+)[Mm](%d+%.?%d*)[Ss]$"
	local pattern2a = "^(%d+)[Hh](%d+%.?%d*)[Mm]$"
	local pattern2b = "^(%d+)[Mm](%d+%.?%d*)[Ss]$"
	local pattern3a = "^(%d+)%+(%d+%.?%d*)$"
	local pattern3 = "^(%d+)%+(%d+)%+(%d+%.?%d*)$"
	local h, m, s

	s = string.match(str, pattern0)
	if s then
		return 0, 0, tonumber(s)
	end

	m, s = string.match(str, pattern1a)
	if m and s then
		return 0, tonumber(m), tonumber(s)
	end

	h, m, s = string.match(str, pattern1)
	if h and m and s then
		return tonumber(h), tonumber(m), tonumber(s)
	end

	h, m = string.match(str, pattern2a)
	if h and m then
		return tonumber(h), tonumber(m), 0
	end

	m, s = string.match(str, pattern2b)
	if m and s then
		return 0, tonumber(m), tonumber(s)
	end

	h, m, s = string.match(str, pattern2)
	if h and m and s then
		return tonumber(h), tonumber(m), tonumber(s)
	end

	m, s = string.match(str, pattern3a)
	if m and s then
		return 0, tonumber(m), tonumber(s)
	end

	h, m, s = string.match(str, pattern3)
	if h and m and s then
		return tonumber(h), tonumber(m), tonumber(s)
	end

	return nil, nil, nil
end

function seconds_from_string(str)

	local is_neg = false
	local h, m, s, sec

	if (not str) then
		return nil
	end

	if (str == ".") then
		return current_time()
	end

	if string.sub(str, 1, 1) == "-" then
		is_neg = true
		str = string.sub(str, 2, string.len(str))
	end

	h, m, s = hms_from_string(str)
	if (not s) then
		return nil
	else
		sec = (3600 * h) + (60 * m) + s
	end

	if (is_neg) then
		sec = -sec
	end

	return sec
end

function string_from_seconds(seconds)

	local str
	local h
	local hm_str = ""
	local m
	local s
	local s_str
	local sign = ""

	seconds = tonumber(seconds)

	if (not seconds) then
		return no_time
	end

	if (seconds < 0) then
		sign = "-"
		seconds = -seconds
	end

	h = math.floor(seconds / 3600)
	m = math.floor((seconds % 3600) / 60)
	s = seconds % 60

	s_str = string.format("%05.2f", s)

	if (h == 0) then
		if (m > 0) then
			hm_str = string.format("%d:", m)
		else
			-- we have only seconds
			s_str = string.format("%.2f", s)
		end
	else
		hm_str = string.format("%d:%02d:", h, m)
	end

	-- remove trailing zeroes and possible trailing decimal point
	if s_str:sub(-3) == ".00" then
		s_str = s_str:sub(1, s_str:len() - 3)
	elseif s_str:sub(-1) == "0" then
		s_str = s_str:sub(1, s_str:len() - 1)
	end

	return sign .. hm_str .. s_str
end

