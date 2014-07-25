-- "eplased_time_to_file.lua" -- VLC Extension script

-- [ Global variables ] --
def_hotkey=120 -- x key

--------------------------

function descriptor()
	return {
		title = "eps_time",
		version = "1.0",
		author = "valuex",
		url = "...",
		shortdesc = "save eplased time to file.",
		description = "save eplased time to file by hotkey"
	}
end
function activate()
	datafile=vlc.misc.userdatadir().."/time_log.txt"	--time log file path
	vlc.var.add_callback( vlc.object.libvlc(), "key-pressed", key_press )
end
function deactivate()
	vlc.var.del_callback( vlc.object.libvlc(), "key-pressed", key_press )
end
function close()
    vlc.deactivate()
end

function key_press( var, old, new, data )
	--do some thing
	if new==def_hotkey then elapsed_time_to_file() end
	
end
function elapsed_time_to_file()
	local input = vlc.object.input()
	local curtime=vlc.var.get(input, "time")
	io.output(datafile)
	io.write(curtime)
	io.close()
end
