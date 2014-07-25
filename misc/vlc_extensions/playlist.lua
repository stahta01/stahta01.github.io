
function descriptor()
	return {
		title = "Playlist Cleaner";
		version = "1.2";
		author = "basaquer";
		url = "http://addons.videolan.org/content/show.php/Playlist+Cleaner?content=155249";
		shortdesc = "Cleans orphaned and duplicates tracks from the playlist.";
		description = "<div style=\"color:#0c0c0c;background-color:#fff;\"><b>Playlist Cleaner</b> is VLC extension (extension script \"playlist.lua\") that checks the active playlist for duplicate and orphaned files (files that have been deleted or otherwise moved) and removes them as needed.</div>";
	}
end

function activate()
	select_options()
end

function close()
	vlc.deactivate()
end

function select_options()
	options = vlc.dialog( "Playlist Cleaner" )
	duplicates = options:add_check_box("Delete Duplicates?",1,1,1,1 )
	orphans = options:add_check_box("Delete Orphans?",1,3,1,1 )
	okbutton = options:add_button( "OK",get_options,3,4,1,1 )
	options:show()
end

function get_options()
	show_totals(update_playlist(orphans:get_checked(), duplicates:get_checked()))
end

function show_totals(totalcount)
	options:hide()
	options:del_widget(duplicates)
	options:del_widget(orphans)
	options:del_widget(okbutton)
	options:add_label( string.format("Process complete. Removed " .. totalcount["orphans"] .. " orphaned track(s) and " .. totalcount["duplicates"] .. " duplicate track(s) from the current playlist."),1,1,5,1)
	options:add_button( "OK", vlc.deactivate,3,2,1,1 ) 
	options:show()
end

function update_playlist(o, d)
	local counter, fileset = {}, {}
	local orphan_count, duplicate_count = 0, 0
	for i, v in pairs(vlc.playlist.get("playlist",false).children) do
		if d then
			if fileset[v.path] then
				vlc.playlist.delete(tonumber(v.id))
				duplicate_count = duplicate_count + 1
			else
				fileset[v.path] = 1
			end
		end
		if o then
			if check_orphans(v.path)==false then
				vlc.playlist.delete(tonumber(v.id))
				orphan_count = orphan_count + 1
			end
		end
	end
	counter["orphans"] = orphan_count
	counter["duplicates"] = duplicate_count
	return counter
end

function check_orphans(filepath)
	local pathval = string.gsub(filepath, "file:\/\/\/", "")
	if pathval==nil then return true end
	pathval = unescape(pathval)
	local file,err,code = io.open(pathval, "r")
	if err and code==2 then return false end
end

function unescape(str)
    newstr = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
    if newstr==nil then newstr=str end
	return newstr
end