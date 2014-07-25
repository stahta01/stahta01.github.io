-- Global variables
title = ""
filename = ""
site = "myanimelist"
page = ""

-- For dialog
dialog_is_opened = false
dlg = nil
reload_button = nil
anime_info = nil

function descriptor()
  return {
    title = site .. " scraper";
    version = "0.01";
    author = "aoeu";
    description = "<center><b>" .. site .. " scraper</b></center>"
    .. "Fetch information for anime from " .. site;
    shortdesc = "Fetch information for anime from " .. site;
    capabilities = { "menu"; "input-listener"--[[; "meta-listener"]] }
  }
end


function menu()
  return { "Get information", "About" }
end

-- Function triggered when the extension is activated
function activate()
  vlc.msg.dbg(_VERSION)
  vlc.msg.dbg("[" .. site .. "] Activating")
  show_chooser()
  return true
end

-- Function triggered when the extension is deactivated
function deactivate()
  if dialog_is_opened then
    close()
  else
    dlg = nil
  end

  vlc.msg.dbg("[" .. site .. "] Deactivated")
  return true
end

-- Function triggered when the dialog is closed
function close()
  reload_button = nil
  dialog_is_opened = false
  vlc.msg.dbg("[" .. site .. "] Closing dialog")

  if dlg ~= nil then dlg:delete() end
  dlg = nil
  return true
end

function show_dialog_about()
  local data = descriptor()

  new_dialog("About")

  dlg:add_label("<center><b>" .. data.title .. " " .. data.version .. "</b></center>", 1, 1, 1, 1)
  dlg:add_html(data.description, 1, 2, 1, 1)

  return true
end

function new_dialog(title)
  close()
  dialog_is_opened = true
  dlg = vlc.dialog(title)
end

-- Function triggered when a element from the menu is selected
function trigger_menu(id)
  if id == 1 then
    return show_chooser()
  elseif id == 2 then
    return show_dialog_about()
  end

  vlc.msg.err("[" .. site .. "] Invalid menu id: " .. id)
  return false
end

function unset_variables()
  title = ""
  filename = ""
  page = ""
end

function reload()
  unset_variables()
  get_title()
  get_info()
  return true
end

function get_title()
    local item = vlc.item or vlc.input.item()
    if not item then
        title = ""
        return false
    end
    local metas = item:metas()
    if metas and metas["title"] then
        title = metas["title"]
    else
        filename = string.gsub(item:name(), "%.[^.]+$", "")
        title = filename or item:name()
    end
    
    if title then
      title = string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(title,
        "[_.]", " "),
        " %-.*$", ""),
        "%[[^%][]*%]", ""),
        "%([^)(]*%)", ""),
        "[0-9][0-9]+.*$", ""),
        "[Ee]p(isode)?.*$", ""),
        " *$", "")
    else
      return false
    end
    
    return true
end

function show_chooser()
  reload()
  new_dialog("Anime chooser")
  dlg:add_label("<center><b>Choose anime for " .. title .. "</b></center>", 1, 1, 1, 1)
  anime_info = dlg:add_html(page, 1, 2, 1, 1)
  reload_button = dlg:add_button("Reload", reload, 1, 3, 1, 1)
  return true
end

function get_info()
  if(title == nil or title == "") then return false end

  local url = "http://myanimelist.net/anime.php?q=" .. string.gsub(title, " ", "+")
  
  local stream = vlc.stream(url)
  if stream == nil then vlc.msg.err("[" .. site .. "] myanimelist.net isn't reachable") return false end

  local reading = "this string left intentionally empty"
  page = ""
  while(reading ~= nil and reading ~= "") do
    reading = stream:read(65653)
    if(reading) then
      page = page .. reading
    end
  end
  if not page or page == "" then
    vlc.msg.err("[" .. site .. "] couldn't get anime page")
    return false
  end
  page = string.gsub(string.gsub(page,
    "^.*<div class=\"borderClass\" style=\"text.align: right; margin: 5px 0; border.width: 0;\"></div><table", "<table"),
    "</table><div class=\"borderClass\" style=\"text.align: right; margin: 5px 0; border.width: 0;\"></div>.*$", "</table>")
    
  page = string.gsub(string.gsub(page,
    "^.*<div id=\"roadblock\">.*<h1>", "<h1>"),
    "<div id=\"rightcontentunder\">.*$", "")
  
end