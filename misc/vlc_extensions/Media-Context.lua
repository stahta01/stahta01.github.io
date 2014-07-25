--[[
Program: Media Context
Purpose: Displays media context information

Author: Copyright 2011-2013 Xavion

License:

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

-- Imports

require "simplexml"

-- Defines

appname = "Media Context"
appver = "0.7.0"
author = "Xavion"
username = "Media-Context"
domain = author .. ".name"
--website = "http://" .. username .. "." .. domain
website = "http://addons.videolan.org/content/show.php?content=143241"
dropbox = "http://dl.dropbox.com/u/106000/Programming/Lua/Media-Context/"
feedback = "mailto:"..username.."@"..domain.."?subject="..appname.."%20v"..appver.."%20-%20Feedback%20-%20"

vlcreq = "2.0.1"
vlcsite = 'http://www.videolan.org/vlc/'

-- Constants

SMALL = 350
MEDIUM = 600
LARGE = 850

PHOTO = 0
FACE = 1
ANY = 2

PRECISE = 0
RELAXED = 1

ARTIST = 0
TRACK = 1
ALBUM = 2

NOW = 1

-- Settings

wiki_lang = "en" -- Wikipedia language code, options: en, fr, ru, ar, ...

def_img_size = SMALL -- Default image size, options: SMALL, MEDIUM, LARGE
def_img_type = PHOTO -- Default image type, options: PHOTO, FACE, ANY
def_img_search = RELAXED -- Default image search, options: PRECISE, RELAXED
def_topic_type = ARTIST -- Default topic type, options: ARTIST, TRACK, ALBUM

num_img_pages = 2 -- Number of Google Images results pages, options: 1, 2, ...
max_file_size = 512 -- Maximum image file size in KiB, options: 512, 1024, ...

remove_me = NOW -- Check for default settings, remove when done modifying

-- Functions

function descriptor()
	return	{
			title = appname;
			version = appver;
			author = author;
			url = website;
			shortdesc = "Displays media context information";
			description = "Purpose:<br />"
						.. "* Displays contextual information about the currently playing media<br />"
						.. "* Adapted from similar scripts by rsyh93, Jean-Philippe Andre and ale5000<br />"
						.. "<br />Feedback: <a href='"..feedback.."Bad'>Bad</a>, <a href='"..feedback.."Good'>Good</a>, <a href='"..feedback.."Idea'>Idea</a>";
			capabilities = { "input-listener", "meta-listener" }
			}
end

--[[
function menu()
	return {}
end
]]

function activate()
	-- Initialise
    reset_variables()
	test_environment()
	show_dialog()

	--[[
	-- Retrieve
	if not_stopped() and vlc_ok then
		track_changed()
	end
	]]

	return true
end

function deactivate()
	busy = true

	-- Close & reset
	if dlg ~= nil then
	    remove_widgets()
		--remove_widget(statusmsg)
		if statusmsg then dlg:del_widget(statusmsg); statusmsg = nil end
	    
	    dlg:delete()
		dlg = nil
	end
	reset_variables()

	vlc.deactivate()

	return true
end

function close()
	deactivate()
end

function input_changed()
	--[[
	if vlc.misc and vlc.misc.mdate then
		print_debug_text("Input change at " .. vlc.misc.mdate()/1000000 .. " seconds.")
	end
	]]--

	-- Retrieve or reset
	--if vlc.input.is_playing() == false then
	if not_stopped() then
		if vlc_ok then
		--if source_is_file() == true then
		--if vlc_ok and source_is_file() == true then
			print_debug_text("Media: URI = " .. vlc.input.item():uri())
			--track_changed()
		end
	else
		remove_widgets()
		reset_variables()
	end
end

function meta_changed()
	--[[
	if vlc.misc and vlc.misc.mdate then
		print_debug_text("Meta change at " .. vlc.misc.mdate()/1000000 .. " seconds.")
	end
	]]--

	-- Retrieve info
	--if vlc.input.is_playing() == false then
	if not_stopped() then
		if vlc_ok then
		--if source_is_file() == false then
		--if vlc_ok and source_is_file() == false then
			--if (now - last) > 15 then
			--last = now
			track_changed()
			--end
		end
	end
end

function get_vlc_ver()
	local vlcver

	if vlc.misc and vlc.misc.version then
		vlcver = vlc.misc.version()
	end

	return vlcver
end

function reset_variables()
	statuslen = 60
	img_res = def_img_size
	errtol = 0.2
	retrieve = nil
	skip_next = 0

	reset_last()
end

function reset_last()
	busy = false
	last = 0
	topic = ""
	artist = ""
	imgs = nil
	sizes = nil
end

function reset_status()
	dlg:set_title(appname)

	-- Test requirements
	if not vlc_ok then
		set_status_text("<b>Click <a href='"..vlcsite.."'>here</a> to download VLC v"..vlcreq.."+ first</b>")
	elseif not_stopped() then
		track_changed()
		--set_status_text("<b>Always start MC before playing media</b>")
	else
		set_status_text("Waiting for media to be played ...")
	end
end

function test_environment()
	check_vlc_version()
end

function show_dialog()
	if dlg == nil then
		dlg = vlc.dialog(appname)
	end
	statusmsg = dlg:add_label("", 21, 22, 35, 1)

	reset_status()
end

--[[
function remove_widgets()
	-- Image widgets
	remove_image(true)
    remove_widget(labimage)
    remove_widget(getnewim)

	-- Topic widgets
    remove_widget(labcon)
    remove_widget(toptype_dd)
    remove_widget(field)
    remove_widget(refine)
    remove_html()

	reset_status()
end
]]

function remove_widgets()
	-- Image widgets
	remove_fb_image()
	remove_image(true)
	if labimage then dlg:del_widget(labimage); labimage = nil end
	if imsize_dd then dlg:del_widget(imsize_dd); imsize_dd = nil end
	if imtype_dd then dlg:del_widget(imtype_dd); imtype_dd = nil end
	if labsearch then dlg:del_widget(labsearch); labsearch = nil end
	if exact_dd then dlg:del_widget(exact_dd); exact_dd = nil end
	if getnewim then dlg:del_widget(getnewim); getnewim = nil end

	-- Topic widgets
	if labcon then dlg:del_widget(labcon); labcon = nil end
	if toptype_dd then dlg:del_widget(toptype_dd); toptype_dd = nil end
	if field then dlg:del_widget(field); field = nil end
	if refine then dlg:del_widget(refine); refine = nil end
    remove_html()

	reset_status()
end

--[[
function remove_widget(widget)
	if widget ~= nil then
		dlg:del_widget(widget)
		--pcall(dlg:del_widget(widget))
		widget = nil
	end
end
]]

function remove_fb_image()
    --remove_widget(fbimg)
	if fbimg then dlg:del_widget(fbimg); fbimg = nil end
end

function remove_image(delfile)
    --remove_widget(image)
	if image then dlg:del_widget(image); image = nil end

	-- Delete file
	if imgfile and delfile then
		os.remove(imgfile)
		imgfile = nil
	end
end

function remove_html()
    --remove_widget(html)
	if html then dlg:del_widget(html); html = nil end
end

function check_vlc_version()
	local msg = "Checking if VLC is up-to-date ..."
	--set_status_text(msg)
	print_debug_text(msg)

	local vlcver = get_vlc_ver() or ""
	vlcver = string.match(vlcver, "(%S+)")
	vlc_ok = compare_versions(vlcver, vlcreq)
end

function check_for_updates()
	local msg = "Checking if MC is up-to-date ..."
	set_status_text(msg)
	print_debug_text(msg)

	get_fallback_image(true)

	-- Get versions stream
	local wstream = vlc.stream(dropbox .. "Current.txt")
	if wstream == nil then
		set_status_text("Click <a href='"..website.."'>here</a> to check for a newer MC version")
		return nil
	end
	--local doc = wstream:read(65536)

	-- Check if current
	local doc = ""
	local utype = nil
	local remver = nil
	local current = true
	local line = wstream:readline()
	while line ~= nil do
		if string.find(line, "Required", 0, true) then
			utype = "stable"
			remver = string.match(line, "Required = (.+)")
			current = compare_versions(appver, remver)
			if not current then break end
		elseif string.find(line, "Recommended", 0, true) then
			utype = "beta"
			remver = string.match(line, "Recommended = (.+)")
			current = compare_versions(appver, remver)
			if not current then break end
		end

		line = wstream:readline()
	end

	-- Inform the user
	if current then
		set_status_text("You are using the latest MC release")
	else
		set_status_text("Click <a href='"..website.."'>here</a> to download MC v"..remver.." ("..utype..")")
	end
end

function compare_versions(locver, remver)
	local older = false

	if locver and remver then
		local lmajor, lminor, lpoint, rmajor, rminor, rpoint
		lmajor, lminor, lpoint = string.match(locver, "(%d+)%p(%d+)%p(%d+)")
		rmajor, rminor, rpoint = string.match(remver, "(%d+)%p(%d+)%p(%d+)")
		lmajor = tonumber(lmajor)
		lminor = tonumber(lminor)
		lpoint = tonumber(lpoint)
		rmajor = tonumber(rmajor)
		rminor = tonumber(rminor)
		rpoint = tonumber(rpoint)

		print_debug_text("Versions: Local = "..lmajor.."."..lminor.."."..lpoint..", Remote = "..rmajor.."."..rminor.."."..rpoint)

		-- Major
		if lmajor < rmajor then
			older = true
		elseif lmajor == rmajor then
			-- Minor
			if lminor < rminor then
				older = true
			elseif lminor == rminor then
				-- Point
				if lpoint < rpoint then
					older = true
				end
			end
		end
	else
		print_debug_text("Unable to compare versions")
	end

	return not older
end

function source_is_file()
	-- Get input source
	local filesrc
	local uri = vlc.input.item():uri()
	if string.find(uri, "file://", 0, true) then
	    filesrc = true
	else
	    filesrc = false
	end
	
	return filesrc
end

function not_stopped()
	return vlc.playlist.status() == ("playing" or "paused")
end

function click_change()
	if not busy then
		busy = true

		-- Update image list if necessary
		if exact ~= get_exact() or imsize ~= get_image_size() or imtype ~= get_image_type() then
			update_image_list()
		end

		-- Change the image
		if change_image() then
			-- Replace topic info
			if html then
				local text = html:get_text()
				remove_html()
				add_html(text)
			end
		else
			--reset_last()
		end

		busy = false
	end
end

function click_refine()
	if not busy then
		if choose_topic(false) then
			busy = true

			update_image_list()

			-- Change the topic
			if not change_topic() then
				--reset_last()
			end

			busy = false
		end
	end
end

function track_changed()
	local proceed = false
	if not busy then
		proceed = choose_topic(true)
	end

	-- Retrieve only
	if proceed == true then
		busy = true

		update_image_list()
		get_fallback_image(false)

	    local failed = false

		-- Change image
		--if vlc.input.is_playing() == true then
		if not change_image() then
		    failed = true
		end
		
		-- Change topic
		if not change_topic() then
		    failed = true
		end

		if failed == false then
			set_status_text("Successfully retrieved new context details")
		else
			--reset_last()
			set_status_text("<b>Couldn't retrieve all new context details</b>")
		end

		-- Check config settings
		if math.random(10) == 5 then
			if remove_me then
				set_status_text("Modify 'Settings' section of code to suit")
			end
		-- Check for updates
		elseif math.random(20) == 10 then
			check_for_updates()
		end

		busy = false
	elseif proceed == nil then
		set_status_text("<b>Couldn't determine new media context (yet)</b>")
	end
end

function choose_topic(auto)
	local newtopic = nil
	local proceed = false

	-- Metadata change
	if auto then
		-- Metadata is stabler
		if vlc.input.item():is_preparsed() then
			newtopic = get_topic()
		end
	-- Refine clicked
	else
		newtopic = field:get_text()

		-- Type changed
		if newtopic == topic then
			newtopic = get_topic()
		end
	end

	-- Topic change
	if newtopic and (newtopic ~= topic) then
		topic = newtopic
		proceed = true
		print_debug_text("Topic = " .. topic)
	elseif newtopic == nil then
		proceed = nil
	end

	return proceed
end

function set_status_text(msg)
	if msg then
		local prefix = "Status: "
		local newmsg = "<code>" .. extend_string(prefix..msg, statuslen) .. "</code>"
		statusmsg:set_text(newmsg)
		dlg:update()

		-- Debug output
		--print_debug_text(prefix .. msg)
	end
end

function print_debug_text(msg)
	if msg then
		vlc.msg.dbg("["..appname.."] " .. msg)
	end
end

function add_html(text)
	if not html then
		html = dlg:add_html(text, 21, 2, 35, 20)
	end
end

function add_image_controls()
	-- Add image label
	if labimage == nil then
		labimage = dlg:add_label("Image:", 1, 1, 0, 1)
	end

	-- Add size dropdown
	if imsize_dd == nil then
		imsize_dd = dlg:add_dropdown(2, 1, 0, 1)
		
		-- Add default first
		if def_img_size == MEDIUM then
			imsize_dd:add_value("Medium", MEDIUM)
		elseif def_img_size == LARGE then
			imsize_dd:add_value("Large", LARGE)
		else
			imsize_dd:add_value("Small", SMALL)
		end

		-- Add other items
		if def_img_size ~= SMALL then imsize_dd:add_value("Small", SMALL) end
		if def_img_size ~= MEDIUM then imsize_dd:add_value("Medium", MEDIUM) end
		if def_img_size ~= LARGE then imsize_dd:add_value("Large", LARGE) end
		--imsize_dd:add_value("Disabled", 0)
	end

	-- Add type dropdown
	if imtype_dd == nil then
		imtype_dd = dlg:add_dropdown(3, 1, 0, 1)

		-- Add default first
		if def_img_type == FACE then
			imtype_dd:add_value("Face", FACE)
		elseif def_img_type == ANY then
			imtype_dd:add_value("Any", ANY)
		else
			imtype_dd:add_value("Photo", PHOTO)
		end

		-- Add other items
		if def_img_type ~= PHOTO then imtype_dd:add_value("Photo", PHOTO) end
		if def_img_type ~= FACE then imtype_dd:add_value("Face", FACE) end
		if def_img_type ~= ANY then imtype_dd:add_value("Any", ANY) end
	end

	-- Add image label
	if labsearch == nil then
		labsearch = dlg:add_label("Search:", 1, 22, 0, 1)
	end

	-- Add exact check-box
	if exact_dd == nil then
		exact_dd = dlg:add_dropdown(2, 22, 0, 1)
		
		-- Add default first
		if def_img_search == RELAXED then
			exact_dd:add_value("Relaxed", RELAXED)
		else
			exact_dd:add_value("Precise", PRECISE)
		end

		-- Add other items
		if def_img_search ~= PRECISE then exact_dd:add_value("Precise", PRECISE) end
		if def_img_search ~= RELAXED then exact_dd:add_value("Relaxed", RELAXED) end
	end

	-- Add change button
	if getnewim == nil then
		getnewim = dlg:add_button("Change", click_change, 3, 22, 0, 1)
	end
end

function change_fb_image()
	-- Remove old one
	if img_res ~= get_image_res() then
		remove_fb_image()
	end

	-- Add new one
	if not fbimg then
		img_res = get_image_res()
		local fbfile = get_temp_filename() or ""
		fbimg = dlg:add_image(fbfile, 1, 2, 20, 20, img_res, img_res)
	end
end

function change_image()
	local changed = false

	set_status_text("<i>Retrieving a new image of the topic ...</i>")

	imgfile = get_image_filename()

	add_image_controls()
	change_fb_image()

	-- Remove last image
	remove_image(false)

	-- Add new image
	if imgfile and string.len(imgfile) > 0 then
		changed = true
		img_res = get_image_res()
		image = dlg:add_image(imgfile, 1, 2, 20, 20, img_res, img_res)
	end

    set_status_length()

	if changed == true then
		set_status_text("Successfully retrieved an image of the topic")
	else
		set_status_text("<b>Couldn't retrieve an image of the topic</b>")
	end

	return changed
end

function add_topic_controls()
	-- Add topic label
	if labcon == nil then
		labcon = dlg:add_label("Topic:", 21, 1, 0, 1)
	end

	-- Add topic list
	if toptype_dd == nil then
		toptype_dd = dlg:add_dropdown(22, 1, 0, 1)
		
		-- Add default first
		if def_topic_type == TRACK then
			toptype_dd:add_value("Track", TRACK)
		elseif def_topic_type == ALBUM then
			toptype_dd:add_value("Album", ALBUM)
		else
			toptype_dd:add_value("Artist", ARTIST)
		end

		-- Add other items
		if def_topic_type ~= ARTIST then toptype_dd:add_value("Artist", ARTIST) end
		if def_topic_type ~= TRACK then toptype_dd:add_value("Track", TRACK) end
		if def_topic_type ~= ALBUM then toptype_dd:add_value("Album", ALBUM) end
	end

	-- Add input field
	if field == nil then
		field = dlg:add_text_input(nil, 23, 1, 32, 1)
	end

	-- Add refine button
	if refine == nil then
		refine = dlg:add_button("Refine", click_refine, 55, 1, 0, 1)
	end
end

function change_topic()
	local changed = false

	-- Get new info
	local data = ""
	if topic ~= nil then
		set_status_text("<i>Retrieving the new topic information ...</i>")

		data = get_wikipedia_info(topic)
	end

	-- Remove last info
	remove_html()

	add_topic_controls()

	-- Add new info
	--if html == nil then
	if data and string.len(data) > 0 then
		-- Add webpage
		add_html(data)
		changed = true

		--else
		--	html:set_text(data)
		--end
	end

	-- Set info titles
	if topic ~= nil then
		field:set_text(topic)
		dlg:set_title(appname .. " - " .. topic)
	end

	if changed == true then
		set_status_text("Successfully retrieved new topic information")
	else
		set_status_text("<b>Couldn't retrieve the new topic information</b>")
	end

	return changed
end

function set_status_length()
	local res = get_image_res()
	
	-- ID to text
	if res == SMALL then
		statuslen = 60
	elseif res == MEDIUM then
		statuslen = 80
	elseif res == LARGE then
		statuslen = 100
	end
end

function get_image_res()
	local res = def_img_size

	-- Get ID
    if imsize_dd ~= nil then
		res = imsize_dd:get_value()
	end

	return res
end

function get_image_size()
	local imsize_text = nil
	local res = get_image_res()

	-- ID to text
	if res == SMALL then
		imsize_text = "isz:m"
	elseif res == MEDIUM then
		imsize_text = "isz:l"
	elseif res == LARGE then
		imsize_text = "isz:l"
	end

	return imsize_text
end

function get_image_type()
	local imtype_id = def_img_type
	local imtype_text = nil

	-- Get ID
    if imtype_dd ~= nil then
		imtype_id = imtype_dd:get_value()
	end

	-- ID to text
	if imtype_id == PHOTO then
		imtype_text = ",itp:photo"
	elseif imtype_id == FACE then
		imtype_text = ",itp:face"
	elseif imtype_id == ANY then
		imtype_text = ""
	end

	return imtype_text
end

function get_exact()
	local exact_id = def_img_search
	local exact_text = nil

	-- Get ID
    if exact_dd ~= nil then
		exact_id = exact_dd:get_value()
	end

	-- ID to text
	if exact_id == PRECISE then
		exact_text = '"'
	elseif exact_id == RELAXED then
		exact_text = ''
	end

	return exact_text
end

function get_topic()
	local topic_id = def_topic_type
	local topic_text = nil

	-- Get ID
    if toptype_dd ~= nil then
		topic_id = toptype_dd:get_value()
	end

	-- ID to text
	if topic_id == ARTIST then
		topic_text = get_artist()
	elseif topic_id == TRACK then
		topic_text = get_track()
	elseif topic_id == ALBUM then
		topic_text = get_album()
	end

	return topic_text
end

function get_artist()
	-- Check input
    local item = vlc.item or vlc.input.item()
    if not item then return nil end

	-- Get metadata
	local name = nil
	local metas = item:metas()
	if source_is_file() then
		if metas["artist"] and string.len(metas["artist"]) > 0 then
			name = metas["artist"]
		elseif metas["title"] and string.len(metas["title"]) > 0 then
			if string.find(metas["title"], " - ", 0, true) then
				name = get_artist_from_combo(metas["title"])
			end
		else
			local filename = string.gsub(item:name(), "^(.+)%.%w+$", "%1")
			name = trim(filename or item:name())
			if string.find(name, " - ", 0, true) then
				name = get_artist_from_combo(name)
			else
				name = nil
			end
		end
	else
		if metas["now_playing"] and string.len(metas["now_playing"]) > 0 then
			if string.find(metas["now_playing"], " - ", 0, true) then
				name = get_artist_from_combo(metas["now_playing"])
			else
				name = metas["now_playing"]
			end
		end
	end

    return name
end

function get_track()
	-- Check input
    local item = vlc.item or vlc.input.item()
    if not item then return nil end

	-- Get metadata
	local name = nil
    local metas = item:metas()
	if source_is_file() then
		if metas["title"] and string.len(metas["title"]) > 0 then
			if string.find(metas["title"], " - ", 0, true) and (not metas["artist"] or string.len(metas["artist"]) == 0) then
				name = get_track_from_combo(metas["title"])
			else
				name = metas["title"]
			end
		else
			local filename = string.gsub(item:name(), "^(.+)%.%w+$", "%1")
			name = trim(filename or item:name())
			if string.find(name, " - ", 0, true) then
				name = get_track_from_combo(name)
			end
		end
	else
		if metas["now_playing"] and string.len(metas["now_playing"]) > 0 then
			if string.find(metas["now_playing"], " - ", 0, true) then
				name = get_track_from_combo(metas["now_playing"])
			end
		end
	end

    return name
end

function get_album()
	-- Check input
    local item = vlc.item or vlc.input.item()
    if not item then return nil end

	-- Get metadata
	local name = nil
    local metas = item:metas()
	if source_is_file() then
		if metas["album"] and string.len(metas["album"]) > 0 then
			name = metas["album"]
			--name = metas["album"] .. " ("..get_artist().." Album)"
		end
	end

    return name
end

function get_artist_from_combo(combo)
	return string.sub(combo, 0, string.find(combo, " - ", 0, true)-1)
end

function get_track_from_combo(combo)
	return string.sub(combo, string.find(combo, " - ", 0, true)+3)
end

function get_file_sizes(withtol)
	local minimum = 128
	local maximum = max_file_size

	-- Use tolerance
	if withtol then
		minimum = math.floor(minimum * (1-errtol))
		maximum = math.ceil(maximum * (1+errtol))
	end

	-- Small image
	if get_image_res() < MEDIUM then
		minimum = math.floor(minimum / 4)
		maximum = math.ceil(maximum / 4)
	end

	return minimum, maximum
end

function get_image_list(loose)
    -- Get image style
    exact = ''
    imsize = get_image_size()
    imtype = get_image_type()

	-- Get size extents
	local min_fsize, max_fsize = get_file_sizes(false)

	-- Get image range
    if not loose then
		exact = get_exact()
	end

	local imgs = {}
	local sizes = {}

	-- Get search results
	for i=0,(num_img_pages-1) do
		-- Get images stream
		local lststr = vlc.stream("http://images.google.com/images?q=" .. vlc.strings.encode_uri_component(exact..topic..exact) .. "&tbs=ift:jpg," .. imsize .. ",iar:s" .. imtype .. ",imgo:1&start="..i*20)
		if not lststr then break end
		local page = lststr:read(1024^2)
		lststr = nil

		-- Save list locally
		--save_to_cache(page, "Images-"..i..".html", "w")

		-- Tabulate results
		for url, height, width, fsize in string.gmatch(page, "imgurl=(http://.-%..-)&amp;.-&amp;h=(%d-)&amp;w=(%d-)&amp;sz=(%d-)&amp;") do
			local imgsize = tonumber(fsize)

			-- Check size and shape
			if imgsize >= min_fsize and imgsize <= max_fsize and height == width then
				table.insert(imgs, vlc.strings.decode_uri(url))
				table.insert(sizes, imgsize)
			--[[
				print_debug_text("Image: Added: " .. url .. ", Size: " .. fsize .. ", Height: " .. height .. ", Width: " .. width)
			else
				print_debug_text("Image: Rejected: " .. url .. ", Size: " .. fsize .. ", Height: " .. height .. ", Width: " .. width)
			--]]
			end
		end
	end

	return imgs, sizes
end

function get_fallback_image(force)
	-- Not yet retrieved
	if get_temp_filename() == nil or force == true then
		local filename = "Fallback.jpg"
		local imgstr = vlc.stream(dropbox .. filename)
		if imgstr == nil then return nil end
		local data = imgstr:read(128 * 1024)
		if data == nil then return nil end

		-- Save image locally
		save_to_cache(data, filename, "wb")
	end
end

function update_image_list()
	set_status_text("<i>Retrieving a list of available images ...</i>")

	-- Automatic
    imgs, sizes = get_image_list(false)
	print_debug_text("Images: List Length (Auto) = " .. table.maxn(imgs))

	-- Relaxed
    if table.maxn(imgs) < 5 and exact == '"' then
		imgs, sizes = get_image_list(true)
		print_debug_text("Images: List Length (Relaxed) = " .. table.maxn(imgs))
    end
end

function get_image_filename()
    local data = nil
	local found = false

	-- Get size extents
	local min_fsize, max_fsize = get_file_sizes(true)

	-- Get info
    --artist = get_artist()
    --track = get_track()
    --if artist == nil then return nil end
    if topic == nil then return nil end

    -- Get random image
	while not found and table.maxn(imgs) > 0 do
		local pick = math.random(table.maxn(imgs))
		local arturl = imgs[pick]
		local imgstr = vlc.stream(arturl)

		if imgstr then
			local start = imgstr:read(2)

			-- Ensure JPEG format
			if start and string.byte(start, 1) == 0xFF and string.byte(start, 2) == 0xD8 then
				data = start .. imgstr:read(max_fsize*1024 - 2)
			end

			-- Run checks
			if data then
				local filesize = #data / 1024
				--print_debug_text("Image: File Size = "..filesize..", Maximum = "..max_fsize)

				-- File size
				if filesize >= max_fsize then
					print_debug_text("Image: Reject = "..pick..", Truncated")
				elseif filesize >= (sizes[pick] * (1-errtol)) and filesize <= (sizes[pick] * (1+errtol)) then
					found = true
					print_debug_text("Image: Pick = "..pick..", URL = "..arturl)
				else
					print_debug_text("Image: Reject = "..pick..", Size = "..math.floor(filesize*100/sizes[pick]).."%")
				end
			end

			imgstr = nil
		end

		-- Remove from list
		table.remove(imgs, pick)
		table.remove(sizes, pick)
	end

	if data == nil then return "" end

	-- Save image locally
	return save_to_cache(data, "Image.jpg", "wb")
end

function get_temp_filename()
	local filepath = vlc.config.cachedir() .. "/MC-Fallback.jpg"
	local fhandle = io.open(filepath, "rb")

	-- Not yet retrieved
	if fhandle == nil then return nil end

	return filepath
end

function get_wikipedia_info(entry)
	-- Get info URL
	local list_url = get_wiki_list_url(entry)
	if list_url == nil then return nil end
	--print_debug_text("List: URL = " .. list_url)

	-- Get list stream
	local list_str = vlc.stream(list_url)
	if list_str == nil then return nil end
	--local doc = list_str:read(65536)
	--local wiki_lang = string.match(list_url, "http://(%w+)%.")

	-- Get page stream
	local list = list_str:read(1024^2)
	list_str = nil
	local first = string.match(list, 'class="mw%-search%-result%-heading".-href="/wiki/(.-)"%s')
	if first == nil then return nil end
	local page_url = "http://"..wiki_lang..".wikipedia.org/w/api.php?action=mobileview&noimages&sections="..desired_sections().."&prop=text&format=xml&page="..first
	print_debug_text("Info: URL = " .. page_url)

	set_status_text("<i>Extracting relevant topic information ...</i>")

	-- Extract XML data
	local xml_tree = simplexml.parse_url(page_url)
	if xml_tree == nil then return nil end
	local doc = format_topic_info(xml_tree)
	xml_tree = nil

	-- Save doc locally
	--save_to_cache(doc, "Info.html", "w")

	return doc
end

function get_wiki_list_url(entry)
	if entry == nil or entry == "" then return nil end

	-- Format query
	local entry = trim(entry)
	entry = string.gsub(entry, " ", "+")
	--entry = string.gsub(entry, " ", "_")

	return "http://"..wiki_lang..".m.wikipedia.org/w/index.php?title=Special:Search&search=~" .. entry
	--return "http://"..wiki_lang..".m.wikipedia.org/wiki/" .. entry
end

function desired_sections()
	local sections = "0"

	-- Choose sections
	if get_image_res() >= MEDIUM then
		sections = "all"
	end

	return sections
end

function format_topic_info(xml_tree)
	-- Introduction
	local intro = xml_tree.children[1].children[1].children[1].children[1] or ""
	intro = string.gsub(intro, '(<div [^>]-class="[^"]-metadata.-</div>)', '', 1) -- Good article
	intro = string.gsub(intro, '(<table [^>]-class="[^"]-metadata.-</table>)', '') -- Problem list
	table.remove(xml_tree.children[1].children[1].children, 1)

	-- Sections
	local sections = ""
	for key,value in pairs(xml_tree.children[1].children[1].children) do
		local section = xml_tree.children[1].children[1].children[key].children[1]
		if string.find(section, 'id="References"', 0, true) or string.find(section, 'id="External_links"', 0, true) then
			break
		end
		section = string.gsub(section, '(<h%d>.-)(<span [^>]-class="mw%-editsection">.*</span>)(.-</h%d>)', '%1%3', 1) -- Edit link
		sections = sections .. section
	end

	-- Combine
	local doc = intro .. sections or ""

	-- Make URLs absolute
	doc = string.gsub(doc, 'href="/wiki/', 'href="http://'..wiki_lang..'.wikipedia.org/wiki/')

	return doc
end

function save_to_cache(data, file, mode)
	-- Form file path
	local fpath = vlc.config.cachedir() .."/MC-".. file
	--if fpath == nil then return "" end

	-- Write file data
	--local fhandle = io.tmpfile()
	local fhandle = io.open(fpath, mode)
	if fhandle == nil then return "" end
	fhandle:write(data)
	fhandle:close()
	--print_debug_text("Topic: File = " .. fpath)

	return fpath
end

function extend_string(msg, newlen)
	if msg then
		local oldlen = string.len(msg)
		--print_debug_text("String: Old length (before) = " .. oldlen)

		-- Ignore style code
		for beg, fin in string.gmatch(msg, "(<.>).+(</.>)") do
			--print_debug_text("String: Removing style code: " .. beg .. ", " .. fin)
			oldlen = oldlen - string.len(beg) - string.len(fin)
		end

		-- Ignore web links
		for beg, fin in string.gmatch(msg, "(<a .+>).+(</a>)") do
			--print_debug_text("String: Removing web link: " .. beg .. ", " .. fin)
			oldlen = oldlen - string.len(beg) - string.len(fin)
		end
		--print_debug_text("String: Old length (after) = " .. oldlen)

		-- Extend length
		msg = msg .. string.rep("&nbsp;", newlen - oldlen)
		--print_debug_text("String: New length = " .. string.len(msg))
	end

	return msg
end

function trim(str)
    if not str then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end
