-- time.lua -- VLC extension --
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

-- defaults
time_format = "[T]"  -- [T]-ime, [O]-ver, [E]-lapsed, [D]-uration, [R]-remaining
osd_position = "top-right"
-- predefined time format patterns
time_formats = {"[T]", "[T] >> [O]", "[E] / [D]", "-[R] / [D]", "-[R] ([T])"}

function descriptor()
	return {
		title = "Time";
		version = "1.0";
		author = "lubozle";
		url = 'http://addons.videolan.org/content/show.php?content=149618';
		shortdesc = "Time displayer";
		description = "<div style=\"background-color:lightgreen;\"><b>Time</b> is VLC extension (extension script \"time.lua\") that displays running time on the screen in a playing video.</div>";
		capabilities = {"input-listener"}
	}
end
function activate()
	input_callback("add")
	create_dialog()
end
function deactivate()
	input_callback("del")
end
function close()
	vlc.deactivate()
end
function input_changed()
	input_callback("toggle")
end

callback=false
function input_callback(action)  -- action=add/del/toggle
	if (action=="toggle" and callback==false) then action="add"
	elseif (action=="toggle" and callback==true) then action="del" end

	local input = vlc.object.input()
	if input and callback==false and action=="add" then
		callback=true
		vlc.var.add_callback(input, "intf-event", input_events_handler, "Hello world!")
	elseif input and callback==true and action=="del" then
		callback=false
		vlc.var.del_callback(input, "intf-event", input_events_handler, "Hello world!")
	end
end

t=0
function input_events_handler(var, old, new, data)
  tt=os.clock()
  if tt>=(t+.5) then -- OSD update approximately 2 times per second instead of 4-5 times
	t=tt

	--vlc.osd.message(tostring(var)..'\n'..tostring(old)..'\n'..tostring(new)..'\n'..tostring(data))
	--local systemTime = os.date("%H:%M:%S") -- reads and formats OS time
	if time_format~=nil or time_format~="" then
		osd_output = decode_time_format()
		vlc.osd.message(osd_output, channel1, osd_position) -- displays time on the screen in a video
	end
	--vlc.msg.info(systemTime)

  end
end

function decode_time_format()
	local input = vlc.object.input()

	local elapsed_time = vlc.var.get(input, "time")
	--local duration = vlc.var.get(input, "length")
	local duration = vlc.input.item():duration()

	local systemHour = os.date("%H")
	local systemMinute = os.date("%M")
	local systemSecond = os.date("%S")

	local elapsedHour = math.floor(elapsed_time / 3600)
	local elapsedMinute = math.floor((elapsed_time % 3600) / 60)
	local elapsedSecond = math.floor(elapsed_time % 60)

	if duration>0 then
		local durationHour = math.floor(duration / 3600)
		local durationMinute = math.floor((duration % 3600) / 60)
		local durationSecond = math.floor(duration % 60)

		remaining_time = duration - elapsed_time
		local remainingHour = math.floor(remaining_time / 3600)
		local remainingMinute = math.floor((remaining_time % 3600) / 60)
		local remainingSecond = math.floor(remaining_time % 60)

		local endingSecond = math.floor((systemSecond + remainingSecond) % 60)
		local endingMinute = math.floor(((systemSecond + remainingSecond) / 60 + (systemMinute + remainingMinute)) % 60)
		local endingHour = math.floor((((systemSecond + remainingSecond) / 60 + (systemMinute + remainingMinute)) / 60 + systemHour + remainingHour) % 24)

		duration = string.format("%02d:%02d:%02d", durationHour, durationMinute, durationSecond)
		remaining_time = string.format("%02d:%02d:%02d", remainingHour, remainingMinute, remainingSecond)
		ending_time = string.format("%02d:%02d:%02d", endingHour, endingMinute, endingSecond)
	else
		duration = "--:--"
		remaining_time = "--:--"
		ending_time = "--:--"
	end
	local elapsed_time = string.format("%02d:%02d:%02d", elapsedHour, elapsedMinute, elapsedSecond)
	--local system_time = os.date("%H:%M:%S")
	local system_time = systemHour..":"..systemMinute..":"..systemSecond

	local osd_output = string.gsub(time_format, "%[E%]", elapsed_time)
	local osd_output = string.gsub(osd_output, "%[T%]", system_time)
	local osd_output = string.gsub(osd_output, "%[D%]", duration)
	local osd_output = string.gsub(osd_output, "%[R%]", remaining_time)
	local osd_output = string.gsub(osd_output, "%[O%]", ending_time)

	return osd_output	
end

function create_dialog()
	w = vlc.dialog("Time")
	--w1 = w:add_label("Time format: \\ Position:",1,1,2,1)
	w1 = w:add_label("<b>Time format:</b>",1,1,1,1)
	w01 = w:add_label("<b>\\ Position:</b>",2,1,1,1)
	w2 = w:add_dropdown(3,1,1,1)
		w2:add_value("top-left", 1)
		w2:add_value("top", 2)
		w2:add_value("top-right", 3)
		w2:add_value("left", 4)
		w2:add_value("center", 5)
		w2:add_value("right", 6)
		w2:add_value("bottom-left", 7)
		w2:add_value("bottom", 8)
		w2:add_value("bottom-right", 9)
			w2:set_text(osd_position)
	w3 = w:add_text_input(time_format,1,2,3,1)
	w4 = w:add_dropdown(1,3,2,1)
		w4:add_value("", 1)
		for i=1,#time_formats do
			w4:add_value(time_formats[i], i+1)
		end
			w4:set_text("")
	w10 = w:add_button("START", click_START,1,4,1,1)
	w11 = w:add_button("STOP", click_STOP,2,4,1,1)
	w12 = w:add_button(">> PUT^IN", click_PUTIN,3,3,1,1)
	w13 = w:add_button("HELP", click_HELP,3,4,1,1)
end
function click_STOP()
	time_format = ""
end
function click_START()
	time_format = w3:get_text()
	osd_position = w2:get_text()
end
function click_PUTIN()
	w3:set_text(w4:get_text())
	w4:set_text("")
	w:update()
end
function click_HELP()
	local help_text=""
.."<div style=\"background-color:lightgreen;\"><b>Time</b> is VLC extension (extension script \"time.lua\") that displays running time on the screen in a playing video.</div>"
.."<hr />"
.."<center><b><a style=\"background-color:#FF7FAA;\">&nbsp;Instructions&nbsp;</a></b></center>"
.."<b><a style=\"background-color:#FF7FAA;\">1.)</a></b> Choose a desired <b><a style=\"background-color:lightblue;\">position</a></b> from the drop-down menu.<br />"
.."<b><a style=\"background-color:#FF7FAA;\">2.)</a></b> In <b><a style=\"background-color:lightblue;\">time format</a></b> input field write some time pattern containing time tags. The list of available tags is below.<br />"
.."You can use predefined pattern from the drop-down menu. Choose one and put it in the time format field by pressing <b><nobr><a style=\"background-color:silver;\">[ >> PUT^IN ]</a></nobr></b> button.<br />"
.."<b><a style=\"background-color:#FF7FAA;\">3.)</a></b> Press <b><nobr><a style=\"background-color:silver;\">[ START ]</a></nobr></b> button for changes to take effect.<br /><br />"
.."<b>Following <a style=\"background-color:#FF7FAA;\">time tags</a> can be used within time format pattern:</b>"
.."<div style=\"background-color:#FF7FAA;\">"
.."<b>&nbsp;[T]</b> - actual system time;<br />"
.."<b>&nbsp;[O]</b> - time when video will be over;<br />"
.."<b>&nbsp;[E]</b> - elapsed time (current playback position);<br />"
.."<b>&nbsp;[R]</b> - remaining time;<br />"
.."<b>&nbsp;[D]</b> - duration (length);</div>"
.." > They are automatically replaced with actual time values on the screen.<br />"
.." > If duration value is not available then [D], [R], [O] is replaced with \"--:--\".<br />"
.." > You can also use some short descriptions or put some delimiters among time tags.<br />"
.."<div style=\"background-color:#FFFF7F;\"><b>OSD text format</b> can be customised within internal VLC settings:<br />"
.."Tools > Preferences > (Show settings - Simple) > Subtitles / OSD<br />"
.."Tools > Preferences > (Show settings - All) > +Video > +Subtitles / OSD > -Text renderer<br />"
.."Do not forget to Save and restart VLC for changes to take effect!</div>"
.."<hr />"
.."<div style=\"background-color:lightblue;\">"
.."<b>Homepage:</b> <a href=\"http://forum.videolan.org/viewtopic.php?f=29&t=97639#p332364\">VLC extension: Time</a><br />"
.."<b>Forum:</b> <a href=\"http://forum.videolan.org/viewforum.php?f=29\">Scripting VLC in Lua</a><br />"
.."Please, visit us and bring some new ideas.<br />"
.."Learn how to write own scripts and share them with us.<br />"
.."Help to build happy VLC community :o)</div>"
.."<pre>     www<br />"
.."    (. .)<br />"
.."-ooo-(_)-ooo-</pre>"
	w5=w:add_html(help_text,1,5,3,1)
	w14 = w:add_button("HELP (x)", click_HELPx,3,4,1,1)
	w:update()
end
function click_HELPx()
	w:del_widget(w5)
	w:del_widget(w14)
	w5=nil
	w14=nil
	w:update()
end