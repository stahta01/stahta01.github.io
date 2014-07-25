-- sampler.lua -- VLC extension
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
Then you simply use the extension by going to the "View" menu and selecting it there.
--]]

-- defaults:
samples=1  -- number of samples per playlist item; minimum 1
sample_duration=60  -- time in seconds
random_position=false  -- true/false
skip_begin=0  -- seconds
skip_end=0  -- seconds
-- predefined profiles:
profiles={{"default",1,60,false,0,0},{"DJ Music",1,20,true,20,20},{"Movie previewer",6,20,false,120,300}}

function descriptor()
	return {
		title = "Sampler";
		version = "1.0";
		author = "lubozle";
		url = 'http://addons.videolan.org/content/show.php?content=149688';
		shortdesc = "Samples player.";
		description = "<div style=\"background-color:lightgreen;\"><b>Sampler</b> is VLC extension (extension script \"sampler.lua\") that plays samples of playlist items of desired duration.</div>";
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
		set_sample()
		vlc.var.add_callback(input, "intf-event", input_events_handler, "Hello world!")
	elseif input and callback==true and action=="del" then
		callback=false
		vlc.var.del_callback(input, "intf-event", input_events_handler, "Hello world!")
	end
end

function set_sample()
	local duration=-1
	repeat
		duration=vlc.input.item():duration()
	until duration>0  -- ugly wait for duration as it is not always available immediately
	--local duration = vlc.input.item():duration()
vlc.msg.info("[Sampler] duration > "..duration)

	set_position=nil
	samples_positions={}
	if (duration - skip_begin - skip_end)>sample_duration then
		possible_samples=math.floor((duration - skip_begin - skip_end) / sample_duration)
		if samples>possible_samples then samples_number=possible_samples else samples_number=samples end
vlc.msg.info("[Sampler] samples_number > "..samples_number)
		if samples_number>1 then
			skipper = math.floor(((duration - skip_begin - skip_end) - (samples_number * sample_duration)) / (samples_number - 1))
		else
			skipper = 0
		end
vlc.msg.info("[Sampler] skipper > "..skipper)

		for i=1,samples_number do
			if random_position==true then
				set_position=skip_begin+math.floor(math.random()*(duration - skip_begin - skip_end - sample_duration))
			else
				if i==1 then
					set_position=skip_begin
				else
					set_position=set_position + sample_duration + skipper
				end
			end
vlc.msg.info("[Sampler] set_position #"..i.." > "..set_position)
			table.insert(samples_positions, set_position)
		end
vlc.msg.info("[Sampler] samples_positions > "..#samples_positions)
	elseif duration > sample_duration then
		if random_position==true then
			set_position=math.floor(math.random()*(duration - sample_duration))
			table.insert(samples_positions, set_position)
		end
	end

	if #samples_positions>0 then
		local input=vlc.object.input()
		actual_sample=1
vlc.msg.info("[Sampler] actual_sample > #"..actual_sample)
		vlc.var.set(input, "time", samples_positions[actual_sample])
vlc.msg.info("[Sampler] new position > "..samples_positions[actual_sample])
	else
		table.insert(samples_positions, 0)
	end
end

function input_events_handler(var, old, new, data)
	--local system_time = os.date("%H:%M:%S")
	--vlc.msg.info(system_time.." > event (old-new): "..old.."-"..new)
	if new==4 then  -- 4 ~ INPUT_EVENT_POSITION 
		local input = vlc.object.input()
		if input then
			if vlc.var.get(input, "time") > (samples_positions[actual_sample] + sample_duration) then
				if actual_sample==#samples_positions then
					vlc.playlist.next()
vlc.msg.info("[Sampler] play next playlist item\n")
				else
					actual_sample=actual_sample+1
vlc.msg.info("[Sampler] actual_sample > #"..actual_sample)
					vlc.var.set(input, "time", samples_positions[actual_sample])
vlc.msg.info("[Sampler] new position > "..samples_positions[actual_sample])
				end
			end
		end
	end
end

function create_dialog()
	w = vlc.dialog("Sampler")
	w2 = w:add_dropdown(2,1,1,1)
	for i,profile in pairs(profiles) do
		w2:add_value(profile[1], i)
	end
	w3 = w:add_label("<b>Samples per item:</b>",1,2,1,1)
	w4 = w:add_text_input(samples,2,2,1,1)
	w5 = w:add_label("<b>Sample duration [s]:</b>",1,3,1,1)
	w6 = w:add_text_input(sample_duration,2,3,1,1)
	w7 = w:add_check_box("random position",random_position,2,4,1,1)		
	w8 = w:add_label("<b>Skip begin/end [s]:</b>",1,5,1,1)
	w9 = w:add_text_input(skip_begin,2,5,1,1)
	w10 = w:add_text_input(skip_end,2,6,1,1)
	w11 = w:add_button("Apply!", click_Apply,1,7,1,1)
	w12 = w:add_button("HELP", click_HELP,2,7,1,1)
	w1 = w:add_button("Load profile:", click_Profile,1,1,1,1)
end
function click_Profile()
	local profile = profiles[w2:get_value()]
	w4:set_text(profile[2])
	w6:set_text(profile[3])
	w7:set_checked(profile[4])
	w9:set_text(profile[5])
	w10:set_text(profile[6])
end
function click_Apply()
	samples = tonumber(w4:get_text())
	sample_duration = tonumber(w6:get_text())
	random_position = w7:get_checked()
	skip_begin = tonumber(w9:get_text())
	skip_end = tonumber(w10:get_text())
	-- to test input values...
end
function click_HELP()
	local help_text=""
.."<div style=\"background-color:lightgreen;\"><b>Sampler</b> is VLC extension (extension script \"sampler.lua\") that plays samples of playlist items of desired duration.</div>"
.."<hr />"
.."<center><b style=\"background-color:#FF7FAA;\">&nbsp;Instructions&nbsp;</b></center>"
.."Feed VLC's playlist with audio/video files. Then:<br />"
.."<b style=\"background-color:#FF7FAA;\">1.)</b> In the drop-down menu choose a desired profile and load it by pressing <b style=\"background-color:silver;\">[ Load profile: ]</b> button. All fields will be updated with predefined profile's values.<br />"
.."<b style=\"background-color:#FF7FAA;\">2.)</b> You can set your own values if you are not happy with predefined ones.<br />"
.."<b style=\"background-color:lightblue;\">Samples per item:</b> how many samples you want to be generated for each playlist item. Minimum is 1.<br />"
.."<b style=\"background-color:lightblue;\">Sample duration [s]:</b> in seconds, how long each sample should be.<br />"
.."<b style=\"background-color:lightblue;\">[ ] random position</b> - tick it, if you want samples to have random position rather than ordered sequentionally.<br />"
.."<b style=\"background-color:lightblue;\">Skip begin/end [s]:</b> - in seconds, how long part of each playlist item should be ignored at the beginning and at the end of it.<br />"
.."<b style=\"background-color:#FF7FAA;\">3.)</b> Do not forget to press <b style=\"background-color:silver;\">[ Apply! ]</b> button for changes to take effect. If you make changes during playback, then the changes will be applied in next playlist item or you need to STOP/PLAY or PLAY NEXT/PREVIOUS playlist item for immediate effect.<br /><br />"
.."Depending on used values and duration of playlist item, algorithm parses samples in several ways, schematicly:"
.."<pre>|-SB-+--+S2S1+---+S3+-+-SE-|<br />"
.."|-SB-+S1+---+S2+---+S3+-SE-|<br />"
.."|---+S1+-|<br />"
.."|S1+-----|<br />"
.."|S1|</pre>"
.."<div style=\"background-color:#FFFF7F;\">You can watch code markers during playback. In VLC menu go to:<br />"
.."Tools > Messages</div>"
.."<hr />"
.."<div style=\"background-color:lightblue;\">"
.."<b>Homepage:</b> <a href=\"http://forum.videolan.org/viewtopic.php?f=29&t=99501\">VLC extension: Sampler</a><br />"
.."<b>Forum:</b> <a href=\"http://forum.videolan.org/viewforum.php?f=29\">Scripting VLC in Lua</a><br />"
.."Please, visit us and bring some new ideas.<br />"
.."Learn how to write own scripts and share them with us.<br />"
.."Help to build happy VLC community :o)</div>"
	w13=w:add_html(help_text,1,8,2,1)
	w14=w:add_button("HELP (x)", click_HELPx,2,7,1,1)
	w:update()
end
function click_HELPx()
	w:del_widget(w13)
	w:del_widget(w14)
	w13=nil
	w14=nil
	w:update()
end