--[[
author:  roland1 (at videolan's addons internet presence)
license: GPL
--]]
local DATA_FD = nil -- fill in file-dir if vlc.config.userdatadir() does not work.

local AUTOSTART_PLAY = true -- set to false if not desired.
local AUTOSTART_PAUSE = false -- kinda overwrites AUTOSTART_PLAY.

local REQUIRE_POSITIVE_DURATION = true
local EPS = 2
local DATA_FN = "progress.lon"
------------------------------------------------------------------------------------
local DATA_FP, DB, URI, INPUT, ITEM, DURA
------------------------------------------------------------------------------------
local function decode(s) return loadstring("return "..s)() end

local function encode(o, buf, n)
	buf, n = buf or {}, n or 1
	local tpo = type(o)
	if tpo == "number" or tpo == "boolean" or tpo == "nil" then
		buf[#buf+1] = tostring(o)
	elseif tpo == "string" then
		buf[#buf+1] = ("%q"):format(o)
	elseif tpo == "table" then
		buf[#buf+1] = "{"
		local nindsb = "\n"..("  "):rep(n).."["
		for k, v in pairs(o) do
			buf[#buf+1] = nindsb
			encode(k, buf, n+1)
			buf[#buf+1] = "] = "
			encode(v, buf, n+1)
			buf[#buf+1] = ","
		end
		buf[#buf] = next(o) == nil and "{}" or "\n"..("  "):rep(n-1).."}"
	end
	if n == 1 then return table.concat(buf) end
end
------------------------------------------------------------------------------------
function descriptor()
	return {
		title = "Progress",
		version = "0.1",
		author = "roland1 (at videolan's addons internet presence)",
		shortdesc = "Auto-Restore Playlist, Auto-Start, Auto-Resume.",
		capabilities = {"input-listener"},
	}
end

function activate()
	os.setlocale("C", "numeric")
	local pd = package.config:sub(1, 1)
	DATA_FP = (DATA_FD or vlc.config.userdatadir()):gsub(pd.."+$", "")..pd..DATA_FN
	local fr = io.open(DATA_FP, "r")
	if fr then
		local s = fr:read"*a" or "{}"
		fr:close()
		if s:find"^%s*{.*}%s*$" then DB = decode(s) end
	end
	if type(DB) ~= "table" then DB = {} end
	for _, n in ipairs{"progress", "session"} do
		if type(DB[n]) ~= "table" then DB[n] = {} end
	end
	local plc = vlc.playlist.get("normal", false).children
	if plc and next(plc) ~= nil then return end
	local plitems, dbs = {}, DB.session
	for i = 1, #dbs do plitems[i] = {path = dbs[i]} end
	if next(plitems) == nil then return end
	vlc.playlist.enqueue(plitems)
	if not AUTOSTART_PLAY and not AUTOSTART_PAUSE then return end
	local path = DB.session.last_played
	if not path then return end
	local plc = vlc.playlist.get("normal", false).children
	if type(plc) ~= "table" then return end
	for i = 1, #plc do
		local item = plc[i]
		if item.path == path then
			(vlc.playlist.gotoitem or vlc.playlist["goto"])(item.id)
			if AUTOSTART_PAUSE then vlc.playlist.pause() end
			break
		end
	end
end

function input_changed()
	local prg = DB.progress
	if INPUT and URI then
		local succ, t = pcall(vlc.var.get, INPUT, "time")
		if succ then
			prg[URI] = (not REQUIRE_POSITIVE_DURATION or DURA >= t+EPS) and t or nil
		end
	end
	ITEM = vlc.input.item()
	if not ITEM then return end
	INPUT, URI, DURA = vlc.object.input(), ITEM:uri(), ITEM:duration()
	local t = prg[URI]
	if URI and t and INPUT and math.abs(t-vlc.var.get(INPUT, "time")) >= EPS then
		vlc.var.set(INPUT, "time", t)
	end
end

meta_changed = input_changed

function deactivate()
	DB.session = {last_played = URI}
	input_changed()
	local plc, dbs = vlc.playlist.get("normal", false).children, DB.session
	if type(plc) == "table" then
		for i = 1, #plc do dbs[i] = plc[i].path end
	end
	io.output(DATA_FP)
	io.write(encode(DB))
	io.close()
end

close = deactivate
