-- start of VLC required functions
dialog_is_open = false

dlg = nil
lookup = nil
html = nil
manual_input = nil
url = nil

-- VLC Extension Descriptor
function descriptor()
	return {
				title = "Wikipedia Lookup";
				version = "0.1";
				author = "rsyh93";
				url = 'n/a';
				description = "<center><b>Wikipedia Lookup</b></center>"
						   .. "<br /><b>Looks up information about the song, artist, and/or author from Wikipedia</b>"
						   .. "<br /><b>(Based on the script made by Jean-Philippe Andre and ale5000)</b>";
				shortdesc = "Looks up information on Wikipedia";
				capabilities = { "menu"; "input-listener"; "meta-listener" }
			}
end

function menu()
	return { "Get Song Info","Get Album Info","Get Artist Info","Get Info Manually" }
end

-- Function triggered when the extension is activated
function activate()
	vlc.msg.dbg(_VERSION)
	vlc.msg.dbg("[WikiLook] Activating")
	return true
end

-- Function triggered when the extension is deactivated
function deactivate()
	if dialog_is_open then
		close() -- Will Reset Variables
	else
		reset_variables()
	end
	vlc.msg.dbg("[WikiLook] Deactivated")
	vlc.deactivate()
	return true
end

function close()
	vlc.msg.dbg("[WikiLook] Closing dialog")

	reset_variables()
	
	if dlg ~= nil then
		dlg:delete()
	end

	dlg = nil
	return true
end

function reset_variables()
	dialog_is_open = false
	dlg = nil
	lookup = nil
	html = nil
	manual_input = nil
	url = nil
end

function new_dialog(title)
	dlg=vlc.dialog(title)
end

function show_dialog()
	if dlg == nil then
		new_dialog("Wikipedia Lookup")
	end	
	-- column, row, col_span, row_span, width, height
	html = dlg:add_html(get_wikipedia_info(lookup), 1, 1, 8, 4)
	dlg:add_button("Get More Info", click_more_info, 1, 5, 8, 4)
	return true
end

function show_dialog_manual()
	if dlg == nil then
		new_dialog("Manual Lookup")
	end	
	
	dlg:add_label("Search:", 1,1,1,1)
	manual_input = dlg:add_text_input("", 2,1,3,1)
	html = dlg:add_html("", 1,2,4,4)
	dlg:add_button("Get Info", click_manual_info, 1,6,4,1)
end

function click_manual_info()
	if manual_input:get_text() == "" or manual_input:get_text() == nil then
		vlc.msg.dbg("[WikiLook] No Manual Input")
		return false
	end
	
	local input = manual_input:get_text()
	input = trim(input)
	input = string.gsub(input, "%s", "+")
	
	url = "http://en.m.wikipedia.org/wiki?search=" .. input
	local stream = vlc.stream(url)
	local doc = stream:read(65535)
	html:set_text(doc)
	
	return true
end
-- Function triggered when a element from the menu is selected
function trigger_menu(id)
	dialog_is_open = true

	if id == 1 then
		lookup = get_title()
	elseif id == 2 then
		lookup = get_album()
	elseif id == 3 then
		lookup = get_artist()
	elseif id == 4 then
		if dlg ~= nil then
			close()
		end
		new_dialog("Wikipedia Lookup (Manual)")
		return show_dialog_manual()
	end
	
	if lookup == nil then
		vlc.msg.err("[WikiLook] Invalid menu id: "..id)
		return false
	end
	
	if dlg == nil then
		new_dialog("Wikipedia Lookup")
		return show_dialog()
	elseif html ~= nil then
		return html:set_text(get_wikipedia_info(lookup))
	end	
end

-- Function triggered when "Get More Info" button is clicked
function click_more_info()
	if not string.match(url, "m.wikipedia.org") then
		url = string.gsub(url, "(%a)(%a).wikipedia.org", "%1%2.m.wikipedia.org")
		url = string.gsub(url, "w/index.php%?title=Special:Search&search=","wiki%?search=")
	end
	local stream = vlc.stream(url)
	local doc = stream:read(65535)
	html:set_text(doc)
	
	return true
end
-- end of VLC functions




-- Get clean title from filename
function get_title()
    local item = vlc.item or vlc.input.item()
    if not item then
        return ""
    end
    local metas = item:metas()
    if metas["title"] then
        return metas["title"]
    else
        local filename = string.gsub(item:name(), "^(.+)%.%w+$", "%1")
        return trim(filename or item:name())
    end
end

function get_album()
    local item = vlc.item or vlc.input.item()
    if not item then
        return ""
    end
    local metas = item:metas()
    if metas["album"] then
        return metas["album"] .. " ("..get_artist().." Album)"
    else
        return ""
    end
end

-- Get clean artist from filename
function get_artist()
    local item = vlc.item or vlc.input.item()
    if not item then
        return ""
    end
    local metas = item:metas()
    if metas["artist"] then
        return metas["artist"]
    else
        return ""
    end
end

function get_wikipedia_info(entry)
	url = get_wikipedia_url(entry)
	local stream = vlc.stream(url)
	
	local document = stream:read(65535)
	
	if string.match(document, "Search results - Wikipedia, the free encyclopedia") then
		vlc.msg.err("[WikiLook] The page does not exist or may be confused with other pages.")
		return nil
	end
	
	local list = {}
	
	local html_string = ""
	
	vlc.msg.dbg("[WikiLook] Finding Matches to Info Box")
	
	for key,value in string.gmatch(document, '<th scope="row" style="text%-align:left;">(.-)</th>.-<td.->(.-)</td>') do
		key = string.gsub(key, "<br />", " ")
		value = string.gsub(value, "<br />", " ")
		list[key] = value
--		vlc.msg.dbg(key, value)
	end
	
	for k,v in pairs(list) do
		html_string = html_string .. k .. ": " .. v .. "<br />"
	end
	
	html_string = string.gsub(html_string, "&#(%d+)", string.char)
	html_string = string.gsub(html_string, "<a href=.->(.-)</a>", "%1")
	
	html_string = html_string .. '<br /><a href="'.. url .. '">Get More Info...</a>'
	
	return html_string
end

function get_wikipedia_url(entry)
	if entry == nil or entry == "" then
		return nil
	end
	
	local entry = trim(entry)
	entry = string.gsub(entry, " ", "+")

	return "http://en.wikipedia.org/w/index.php?title=Special:Search&search=" .. entry
end

-- Remove leading and trailing spaces
function trim(str)
    if not str then return "" end
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end