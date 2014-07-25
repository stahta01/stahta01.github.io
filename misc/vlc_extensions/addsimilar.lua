--[[
 Add Similar, testing version

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
--]]

--[[ Extension description ]]

	function descriptor()
		return { title = "Add Similar" ;
				 version = "alpha" ;
				 author = "VideoLAN" ;
				 shortdesc = "Quickly adds files similar to the one you're playing";
				 description = "<h1>Add Similar</h1>"
							.. "When you're playing a file, use Add Similar to"
							.. "easily add files that are similar (like those in a series).";
				 capabilities = { "input-listener", "meta-listener" } }
	end

--[[ Global vars ]]
	path = nil
	target = nil


--[[ Hooks ]]

	-- Activation hook
	function activate()
		vlc.msg.dbg("[Add Similar] Activated")
		start()
	end

	-- Deactivation hook
	function deactivate()
		vlc.msg.dbg("[Add Similar] Deactivated")
	end


--[[ Start ]]

	function start()
		item = vlc.item or vlc.input.item() -- check if an item is playing
		if not item then -- return an alert box explaining what the user should do
			alert("Using Add Similar",
						"When you're playing a file, use Add Similar to "
						.. "automatically add other files in its folder that are like "
						.. "the one you're playing."
						.."<br /><br />To use Add Similar, start playing a file.")
			vlc.msg.dbg("[Add Similar] No item has been selected.")
		else	
			find_similar(item) -- starts the "Find Similar" process
		end
	end

	
function find_similar(item)
	vlc.msg.dbg("[Add Similar] File selected: "..vlc.strings.decode_uri((item:uri())))
	
	-- Check the protocol (currently, only file:/// is supported)
	if string.find(item:uri(), "file:///") then
		similar_media = find_files(item) -- delegate to the find_files
		vlc.msg.dbg("[Add Similar] Files found: "..table.concat(similar_media," , "))
	else
		similar_media = {}
		vlc.msg.dbg("[Add Similar] Unsupported media type.")
		alert("Unsupported media type", "We're sorry, but Add Similar only works on local files right now.")
	end
	
	-- Did it return anything?
	if #similar_media == 0 then -- If nothing was returned, inform the user
		vlc.msg.info("[Add Similar] didn't find similar files")
		alert("No similar files could be found.", "")
	else -- Add the files
		vlc.msg.info("[Add Similar] found similar files")
		for _,file in pairs(similar_media) do 
			local new_item = {}
			new_item.path = "file:///"..path..file
			new_item.name = file
			
			vlc.msg.dbg("[Add Similar] adding: "..path..file)
			vlc.playlist.enqueue({new_item})
		end
		vlc.deactivate()
	end
end

-- This function will find files and add them to a table, which it returns.
function find_files(item)
	-- Scour the directory for files (Starts at position 9 to get rid of "file:///") (TODO: Clean this up!)
	path = vlc.strings.decode_uri(string.sub(item:uri(), 9 , -(string.find(string.reverse(item:uri()), "/", 0, true))))
	target = vlc.strings.decode_uri(string.sub(item:uri(), string.len(item:uri())+2-(string.find(string.reverse(item:uri()), "/", 0, true))), -0)

	vlc.msg.dbg("[Add Similar] Target file: "..target)
	
	vlc.msg.dbg("[Add Similar] Loading directory: "..path)
	
	-- Load directory contents into a table
	local contents = vlc.net.opendir(path)

	-- TEST 1: Split the filename into words
	local keywords = split(target,"[%p%s]")
	
	vlc.msg.dbg("[Add Similar] Keywords: "..table.concat(keywords," \\ "))
	
	-- TEST 2: Analyze the filename to find its structure
	local structure = split(target,"[^%p]+")
	
	vlc.msg.dbg("[Add Similar] Structure: "..table.concat(structure))
	
	-- TEST 3: Look for keywords (second pass)
	
	
	score= {} 
	
	for _, file in pairs(contents) do 
		vlc.msg.dbg("[Add Similar] "..file)
		
		if not (file == target or file == '.' or file == '..') then		
			
			-- TEST 1: Look for matches in words in the file
			local file_keywords = split(file,"[%p%s]")
			local matches = 0	
			
				for _,key in pairs(keywords) do
					for _,file_key in pairs(file_keywords) do
						if (file_key == key) then
							matches = matches + 1
						end
					end
				end
				
				vlc.msg.dbg("      Matches: "..matches)
				vlc.msg.dbg("      Probability: "..(matches/#keywords))
					
				increment = ((matches/#keywords)*100)*0.40
				score[file] = score[file] or 0
				score[file] = score[file] + increment
				vlc.msg.dbg("      Score added: "..increment)
						
			-- TEST 2: Look for similarities in file structure		
			local file_structure = split(target,"[^%p]+")
				if table.concat(file_structure)==table.concat(structure) then 
					increment = 40
					vlc.msg.dbg("      Structure match: true")
					score[file] = score[file] or 0
					score[file] = score[file] + increment
					vlc.msg.dbg("      Score added: "..increment)
				end
				
				score[file] = score[file] or 0
				
				vlc.msg.dbg("      Final score: "..score[file])
		else 
			vlc.msg.dbg("      Not analyzed")
		end
	end

	local cutoff = 60 -- arbitrary value

	-- Return similar media
	local similar_media = {}
		
	for file,p in pairs(score) do 
		if p > cutoff then
			table.insert(similar_media,file)
		end
	end
	

	return similar_media
end



--[[ UTILITY FUNCTIONS ]]--

-- Create an alertbox, also quitting the extension

function alert(title,message)
	local dialog = vlc.dialog("Add Similar")
	dialog:add_label("<h2>"..title.."</h2>", 1, 1, 5, 10)
    dialog:add_label(message, 1, 14, 5, 5, 200)
    dialog:add_button("OK", function () dialog:delete() vlc.deactivate(); return nil end, 3, 20, 1, 5)
end

function close() -- when the messagebox is closed
    vlc.deactivate()
end

-- Splits a string into a table, based on a patterns (from: http://http://lua-users.org/wiki/SplitJoin )

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
	 table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t,cap)
   end
   return t
end