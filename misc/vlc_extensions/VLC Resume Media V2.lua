--[[
               Resume Media Version 2.20  
      VLC Lua Extension by Rocky Dotterer 5/5/2014

 Coded in VLC 2.1.3 Rincewind and Windows 8.1
 Copy this text to a text file named "VLC Resume Media V2.lua"
 Copy to C:\Users\<you>\AppData\Roaming\vlc\lua\extensions
    Create ..\lua\extensions directory if necessary
 Open VLC and check "Resume Media V2" in View menu before playing.
 Media positions saved in default VLC user data directory
    which should be C:\Users\<you>\AppData\Roaming\vlc
    as "VLC Resume Media V2.txt" Separate file for each table.

 Description: 
 Resume Media V2.20 now supports multiple tables.

 Resume Media detects the stopped positions of all video and audio 
 files in VLC and saves the positions in a table. When you restart, 
 say, a video in VLC, Resume Media detects it and automatically 
 moves the slider to the remembered position. When the video completes, 
 the entry is removed from the table.

 You can run Resume Media in the background by closing the table dialog 
 window and simply control the media from any VLC playlist. However, 
 the Resume Media dialog allows you to sort or play the entries in a 
 table or to switch tables. You can import the VLC playlist to a table.

     ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~

 A table can be used as a playlist for, say, a tv series or a music album. 
 The resume feature then allows you to play and stop and quickly resume 
 whichever entries interest you at the time until you have finally 
 completed the list. Sort the list to see which entries you have started.

 You can import and save top level playlists or directories into 
 a table. Then, when you are ready, move one entry to VLC, expand it, 
 and then import the media list back to a different table for execution.

 For most users, a single instance of VLC is sufficient and preferable. 
 Go to Tools > Preferences > Interface > Playlist and check the boxes 
 allowing only a single instance of VLC. However, a new instance of 
 Resume Media in a new instance of VLC will open the next available table. 
 The entries from different tables can be combined for convenience.
 Tables can be excluded from opening in a new instance of Resume Media.


 Notes:
 If you open Resume Media while a media is playing, the next stop event
    will be undetectable. Stop and restart the media to allow detection 
    or see changelog 2014-06-16 below to save the playing media position.
 There is a media-just-started tolerance of 60 seconds, so you have
    60 seconds to sample media without saving the stop position.
    Increase variable 'begintol' to increase media-just-started time.
 In the event that there are identical media names in the VLC playlist,
    Resume Media assumes they are associated with the same media file,
    and saves the path of the first one entered into the table.
 If VLC closes unexpectedly or Windows closes while VLC is open, then a
    table can be orphaned (busy flag stuck on.) The next time Resume 
    Media opens, you can switch to that table to free up the busy flag.
 Operations are performed on the current table. If you switch tables,
    then updates to media stop positions will be added to the new table.
 Combining tables saves the highest position of duplicate entries.
 Setting an excluded table to "K" will keep media in table when completed.
 Increase the value of variable 'maxtables' if you want more tables.
 See changelog 2014-07-03 below for new functionality.

 Changelog
   2014-07-03 update
      For consistency, media set to 'Finished' will remain in any table.
      This also allows media to remain in table 1.
   2014-07-03
      Set default media-just-started to 60 rather than 30 seconds.
      Improve table dialog functionality:
      Set media completed flag to 'Finished' rather than 00:00:01.
      When sorting by time, 'Finished' media will always be at the bottom.
      You can now reset media to 00:00:00 or to 'Finished.'
      'Finished' media will not update position unless reset to 00:00:00.
      'Finished' media will still delete at the end in non-'K' tables.
   2014-06-18
      Amend the previous update to include the case where the media is
      paused, because 'paused' is considered 'not playing'.
   2014-06-16
      If the table dialog 'Play' is clicked while media is playing, the
      media position will now update before selected entries are enqueued.
      One click can stop/enqueue or enqueue/play but not stop/enqueue/play.
   2014-06-12
      Allow media to remain in an excluded table when it completes.
      Set X=normal exclude or K=keep media with time reset to 00:00:01.
   2014-06-11
      Disallow automatic resume if Resume Media opened while media
        is playing. For some reason, the input object is nil when
        the media is stopped after this, causing the stop to be
        undetectable. So, if Media Resume is opened after a media
        has started, stop and restart the media to allow detection.
      Correct open_table function inadvertently broken in 6-9 update.
      Correct dialog update if media stopped during tables dialog.
   2014-06-09
      Refined the media detection to eliminate spurious updates.
      A few other minor improvements.
   2014-06-01
      Resume Media will now open even if all tables are busy or
      excluded. This should be very rare, but it allows recovery
      if tables are orphaned.
   2014-05-31
      Fix warning that busy tables cannot be combined
   2014-05-30
      Correct multiple-selection delete and move functions
      which were inadvertently broken in V2.20, 2014-05-25
   2014-05-25  V2.20
      Multiple table funtionality (see below) and sort ability
   2014-05-17  V2.10
      Move selected table entries to top or bottom
      Import VLC playlist to table
      Confirm delete selection
   2014-05-12  V2.00


   Uses input_changed() and meta_changed() functions called by VLC
         to capture media name and stop position 
   The reliability of this program depends on VLC calling one of
         these functions with position data when media started/stopped

   Multiple Instances of VLC:
   Multiple instances of VLC allow multiple instances of Resume Media. 
   The ability of multiple instances of Resume Media to maintain
   referential integrity between their tables is problematic given
   the abilities of Lua in VLC. To bypass this limitation, Resume Media
   allows 10 independent tables. Each instance of Resume Media will open
   a table that is not already open. If all tables are open or excluded,
   Resume Media opens in the recovery mode in case tables are orphaned.

   This added complexity does allow for some interesting new capabilities.
   A table can be reserved as a playlist for, say, a TV series or an album.
   You can then play and pause and resume whichever entries interest you
   at the time until you have finally completed the list.

   To support these new capabilities, any instance of Resume Media can
   switch to any unopen table. Selected tables can be combined into the
   current table. For duplicate entries, the highest saved position is 
   saved. Any table but the first can be excluded from automatically
   being opened when a new instance of Resume Media starts, thus
   protecting the table from unexpected changes.
--]]

                -- user adjustable variables

filename = ""   -- change if you want file(s) in your own directory
                -- ex. "D:\\Video\\VLC Media Resume V2.txt" (end in .txt)  
begintol = 60   -- set media-just-starting between 2 sec and a few minutes
maxtables = 10  -- set number of datafiles between 1 and a reasonable number

-------------- many (not all) global variables ------------------------

names = {}      -- table of media metadata/file names played and stopped
times = {}      -- stopped position times of media in seconds
paths = {}      -- full file path in %-coded uri/url format
len = 0         -- table length
optns = {}      -- comma separated options in line 2 of data file
endtol = 10     -- end-of-media interval. Don't resume too close to end
infoline = "<< This file generated by 'VLC Resume Media V2.lua' >>"
filenum = 0     -- the file (table) number we're using

                --   options (line 2 of file)
prevostime = 0     -- last time file closed
filelocked = 0     -- allow instance of Resume Media to open file or not
filebusy = 0       -- file (not) in use by instance of Resume Media

                --   dialog modes and mode flags
normal = true      ;  setnormal = 1
deleteyn = false   ;  setdeleteyn = 2  
playyn = false     ;  setplayyn = 3  
movetb = false     ;  setmovetb = 4 
getplayl = false   ;  setgetplayl = 5 
dotables = false   ;  setdotables = 6
openyn = false     ;  setopenyn = 7
combineyn = false  ;  setcombineyn = 8
sorttn = false     ;  setsorttn = 9
allbusy = false    ;  setallbusy = 10
lockmode = false    ;  setlockmode = 11

                --   dialog message labels
normallbl = "Click 'Play' with no selection to import playlist"
deleteynlbl = "Set selection to '00:00:00'/'Finished' or delete selection"
playynlbl = "Play selection"
movetblbl = "Move selection to top or bottom"
getplayllbl ="Add VLC playlist to table?"
lockmsglbl = "Exclude (X/K) means table won't initially "..
             "open in new instance of RM"
busylbl = "Cannot exclude table 1 or busy tables (except current table)"
busy2lbl = "Busy tables were not imported."
showynlbl = "Table already in use or orphaned. Continue?"
combineynlbl = "Combine selected tables into the current table?"
tabletitle = "Table #,   X/K=Excluded,   B=Busy,   # Entries,   First Entry"
sorttnlbl = "Sort ascending or descending (toggle)"
allbusylbl = "All tables are busy or excluded."
lockmodelbl = "Reset exclude mode or choose media-finished action for excluded tables"

                --   dialog button labels
setdeletelbl = "Set / Delete"
movelbl = "Sort / Move"
playlbl = "Import / Play"
deletelbl = "Delete"
startlbl = "'00:00:00'"
finishlbl = "'Finished'"
yeslbl = "Yes"  ;  nolbl = "No"
toplbl = "Top"  ;  botlbl = "Bottom"
donelbl = "Done"
tableslbl = "Tables"
openlbl = "Open"
locklbl = "Exclude"
combinelbl = "Combine"
backlbl = "Back"
namelbl = "Name"
timelbl = "Time"
exitrmlbl = "Exit RM"
resetlbl = "Reset"
removelbl = "Remove (X)"
keeplbl = "Keep (K)"

---------------- It all starts here ------------------------

function activate() 
    if filename == "" then   -- did user change the file name?
      filename = vlc.config.userdatadir().."\\VLC Resume Media V2.txt"
    end
    filebasename = filename  -- save for table routines
    get_file() -- input file -- get first non-busy table

                          --  display dialog

    lp = 30   -- default = 30   larger numbers don't seem to make it longer
    dlg = vlc.dialog("Resume Media Table "..filenum)
    list = dlg:add_list(1,3,10,lp)
    label_msg = dlg:add_label("",1,lp+10,10,1)
--    label_dbg = dlg:add_label("hello world",1,lp+11,10,1)  -- for testing
    button_1 = dlg:add_button("", click_button1,1,lp+15,1,1)
    button_2 = dlg:add_button("", click_button2,4,lp+15,1,1)
    button_3 = dlg:add_button("", click_button3,7,lp+15,1,1)
    button_4 = dlg:add_button("", click_button4,10,lp+15,1,1)
    if filenum > 0 then
      setdlgmode(setnormal)
    else
      setdlgmode(setallbusy) -- all tables busy or excluded
    end
        -- there seems to be an issue where a click function is called twice
        -- with a single click. uses lastclicktime to slow the calling process
    lastclicktime = os.time() 
    dlg:show()
end 

------------------------- Update Functions ------------------------

-- input_changed called once or twice when media starts.

function input_changed() 
    inpt = vlc.object.input()
    if inpt == nil then return end   -- just in case
    state = "start"
    check_names()
end

-- meta_changed called a bunch of times with state = 2 but only a few
-- times with state = 1 (near start) and only once with state = 4 (stop)
-- the state = 1 event seems to be needed since the input_changed event
-- doesn't always trigger a resume

function meta_changed()  
    inpt = vlc.object.input()
    if inpt == nil then return end   -- just in case
    stst = vlc.var.get(inpt, "state") -- 1=start 4=stop
    if stst == 1 then
      state = "start"
      check_names()
    elseif stst == 4 then
      state = "stop"
      check_names()
    end
end

function check_names()  -- check for playlist input changes
    nam = vlc.input.item():name()
    uri = vlc.input.item():uri()
    dur = vlc.input.item():duration()  -- end of media
    tim = vlc.var.get(inpt, "time") -- seconds from beginning
    fin = dur - endtol  -- end-of-media tolerance position
    if fin < begintol then return end  -- short media
    if tim < begintol then
      pos = "begin"
    elseif tim < fin then
      pos = "mid"
    else
      pos = "end"
    end
    idx = find_in_table(nam)  -- nil if not in table
    updatedlg = false   

  --     logic table
  --  if media  is in table and just started playing then
  --     move to remembered position (that's the whole idea!!!)
  --  if media  is in table and had been playing awhile then
  --     update the remembered position
  --  if media  is in table and at the end then
  --     remove from table (or reset to 00:00:01)
  --  if media not in table and just started playing then
  --     do nothing (no need to remember a new starting media)
  --  if media not in table and had been playing awhile then
  --     add the media and position to the tables

    if idx then                   -- in table?
      if state == "start" then    -- only change if starting
        if pos == "begin" then    -- just started playing?
          if times[idx] > 1 then  -- time=1 is media finished flag
           vlc.var.set(inpt, "time", times[idx]) -- resume!!!!!!!!
          end
        end
      elseif pos == "mid" then    -- been playing awhile, so
        if times[idx] ~= 1 then   -- don't update if already finished
          times[idx] = tim        -- update stopped position     
          updatedlg = true        -- change so update dialog 
        end
      elseif pos == "end" and times[idx] ~= 1 then   -- keep or delete
        if filelocked == 2 then   -- keep media entry (K)
          times[idx] = 1          -- 1 sec = media completed flag
        else
          table.remove(names,idx)
          table.remove(times,idx)
          table.remove(paths,idx)
          len = len - 1
        end
        updatedlg = true  -- change so update dialog 
      end
    elseif state == "stop" and pos == "mid" then   -- playing awhile? 
      table.insert(names,1,nam)    -- add stopped name
      table.insert(times,1,tim)    -- add stopped position
      table.insert(paths,1,uri)    -- add uri/path
      len = len + 1       
      updatedlg = true  -- change so update dialog 
    end

    if updatedlg then              -- update the dialog
      filename = getfilename(filenum)
      write_names()
      list_update() 
    end
end

function find_in_table(nam)
    idx = nil
    if len > 0 then
      for i = 1, len do
        if names[i] == nam then
          idx = i
          break
        end
      end
    end
    return idx  -- nil if not in table
end

------------------------ dialog functions -------------------

function click_button1()   -- Delete, Yes, Open or Reset
    if os.time() - lastclicktime < .2 then return end -- no double click
    lastclicktime = os.time()

    if normal then
      if is_selection() then
        setdlgmode(setdeleteyn)
      end
    elseif deleteyn then
      set_time(0)                 -- reset time to zero
    elseif playyn then
--    nothing
    elseif movetb then
      move_top()
    elseif getplayl then
      getplaylist()
      setdlgmode(setnormal)
    elseif dotables or allbusy then
       if open_table(false) then setdlgmode(setnormal) end
    elseif openyn then
      open_table(true)
      setdlgmode(setnormal)
    elseif combineyn then
      combine_tables()
    elseif sorttn then
      sort_by_time()
    elseif lockmode then
      lock_table(0)
    end
end

function click_button2()   -- Move, No, Exclude(Lock) or Remove
    if os.time() - lastclicktime < .2 then return end -- no double click
    lastclicktime = os.time()

    if normal then
      if is_selection() then
        setdlgmode(setmovetb)
      else
        setdlgmode(setsorttn)
      end
    elseif deleteyn then
      set_time(1)                 -- set time to 1 (finished)
    elseif playyn then
--    nothing
    elseif movetb then
      move_bottom()
    elseif getplayl then
      setdlgmode(setnormal)       -- cancel get playlist
    elseif dotables then
      if is_selection() and not (selcount == 1 and fstselidx == 0) then
        setdlgmode(setlockmode)
      end
    elseif openyn then
      if filenum == 0 then
        setdlgmode(setallbusy)
      else
        setdlgmode(setdotables)   -- reset
      end
    elseif combineyn then
      setdlgmode(setdotables)     -- reset
    elseif sorttn then
      sort_by_name()
    elseif lockmode then
      lock_table(1)
    end
end    

function click_button3()   -- Play, Done, Combine or Keep
    if os.time() - lastclicktime < .2 then return end -- no double click
    lastclicktime = os.time()

    if normal then
      if is_selection() then 
        makeplaylist()
        list_update()
      else
        setdlgmode(setgetplayl)
      end
    elseif deleteyn then
      delete()
    elseif dotables then
      if is_selection() and not 
        (selcount == 1 and (fstselidx == 0 or fstselidx == filenum)) then
        setdlgmode(setcombineyn)
      end
    elseif openyn or allbusy then
      if filenum == 0 then
        setdlgmode(setallbusy)
      else
        setdlgmode(setdotables)   -- reset
      end
    elseif combineyn then
      setdlgmode(setdotables)     -- reset
    elseif lockmode then
      lock_table(2)
    else  -- all other modes
      setdlgmode(setnormal)
    end
end

function click_button4()  -- Tables, Done, Back or Exit RM
    if os.time() - lastclicktime < .3 then return end -- no double click
    lastclicktime = os.time()

    if normal or lockmode then
      setdlgmode(setdotables)
    elseif deleteyn or dotables then
      setdlgmode(setnormal)
    elseif allbusy then
      vlc.deactivate()
    end
end

function delete()
    if is_selection() then
      for idx, selectedItem in pairs(selection) do
            -- search table because table altered after each delete
        i = find_in_table(string.sub(selectedItem,12)) -- remove hhmmss
        if i then                    -- in the table?
          table.remove(names,i)
          table.remove(times,i)
          table.remove(paths,i)
          len = len - 1
        end
      end
    end
    list_update()
end

function set_time(beginend)
    if is_selection() then
      for idx, selectedItem in pairs(selection) do
        times[idx] = beginend   --  set to 0 or 1 (finished)
      end
    end
    list_update()
end

function getplaylist()
    for i, item in pairs(vlc.playlist.get("playlist",false).children) do
      if not find_in_table(item.name) then
        len = len + 1        -- add playlist item to table
        names[len] = item.name
        paths[len] = item.path
        times[len] = 0
      end 
    end
    list_update()
end

function makeplaylist()
    if not is_selection() then return end
    inpt = vlc.object.input()  
    stat = vlc.playlist.status()
    if inpt ~= nil and (stat == "playing" or stat == "paused") then
      state = "stop"  
      check_names()   -- possible update before clearing playlist
    end
    vlc.playlist.clear()   -- create new playlist
    for i = 1, len do  -- this way because selection table is out of order
      j = 0
      for idx, selectedItem in pairs(selection) do
        if string.sub(selectedItem,12) == names[i] then  -- remove hhmmss 
          j = i
          break
        end
      end
      if j > 0 then
        video = { name = names[j], path = paths[j] }
        vlc.playlist.enqueue({video})
      end
    end
    vlc.playlist.play()
    list_update()         -- clear the selection
end

function move_top()
    if not is_selection() then return end
    for i = len, 1, -1 do  -- this way because selection table is out of order 
      k = nil
      for idx, selectedItem in pairs(selection) do
        if idx == i then -- search table because table altered after each move
          k = find_in_table(string.sub(selectedItem,12)) -- remove hhmmss
          break
        end
      end
      if k then
        nam = names[k]
        tim = times[k]
        uri = paths[k]
        table.remove(names,k)
        table.remove(times,k)
        table.remove(paths,k)
        table.insert(names,1,nam)  
        table.insert(times,1,tim)  
        table.insert(paths,1,uri)  
      end
    end
    list_update()
end

function move_bottom()
    if not is_selection() then return end
    for i = 1, len do  -- this way because selection table is out of order
      k = nil
      for idx, selectedItem in pairs(selection) do
        if idx == i then -- search table because table altered after each move
          k = find_in_table(string.sub(selectedItem,12)) -- remove hhmmss
          break
        end
      end
      if k then
        nam = names[k]
        tim = times[k]
        uri = paths[k]
        table.remove(names,k)
        table.remove(times,k)
        table.remove(paths,k)
        table.insert(names,len,nam)  
        table.insert(times,len,tim)  
        table.insert(paths,len,uri)  
      end
    end
    list_update()
end

flipflop = false
function flip_table(tbl,n)  -- allows table flipping in sort below
    if not flipflop then return tbl end
    local tmp = {}
    for i = 1, n do
      tmp[i] = tbl[n-i+1]
    end
    return tmp
end

function sort_by_name()
    idxs = flip_table(stable_sort(names,len),len) -- flip?
    flipflop = not flipflop
    names = sort_idxs(names,idxs,len)    
    times = sort_idxs(times,idxs,len)
    paths = sort_idxs(paths,idxs,len)
    list_update()
end

function sort_by_time()
    sort_by_name()            -- to make sure subsort is ascending by name
    flipflop = not flipflop         -- reverse flip in sort_by_name
    local hms = {}
    for i=1,len do hms[i] = hhmmss(times[i]) end -- sorts better by string
    idxs = flip_table(stable_sort(hms,len),len)
    flipflop = not flipflop
    names = sort_idxs(names,idxs,len)    
    times = sort_idxs(times,idxs,len)
    paths = sort_idxs(paths,idxs,len)
    move_completed()          -- now move finished media to the bottom
    list_update()
end

function stable_sort(tbl,n)  -- this preserves the sub-order of equal elements
    local idxs = {}
    for i = 1, n do
      nn = i
      if i < 1000 then nn = "0"..nn end   -- wow!
      if i < 100 then nn = "0"..nn end
      if i < 10 then nn = "0"..nn end
      nn = string.sub(nn,-4,-1)           -- no more than 4 digits
      idxs[i] = tbl[i]..nn
    end
    table.sort(idxs)  -- now we get a stable sort, then strip the indicies
    for i = 1, n do
      idxs[i] = tonumber(string.sub(idxs[i],-4,-1))
    end
    return idxs
end

function sort_idxs(tbl,idxs,n)    -- sort table based on sorted idxs
    local tmp = {}
    for i = 1, n do
      j = tonumber(idxs[i])
      if not j then j = i end     -- just in case
      if j < 1 or j > n then j = i end -- just in case
      tmp[i] = tbl[j]
    end
    return tmp
end

function move_completed()   -- move completed media to bottom
    local ntemp = {} ; local ttemp = {} ; local ptemp = {}
    k = 0
    for i = 1, len do       -- unfinished at top 
      if times[i] ~= 1 then
        k = k + 1
        ntemp[k] = names[i]
        ttemp[k] = times[i]
        ptemp[k] = paths[i]
      end
    end
    for i = 1, len do       -- finished at bottom 
      if times[i] == 1 then
        k = k + 1
        ntemp[k] = names[i]
        ttemp[k] = times[i]
        ptemp[k] = paths[i]
      end
    end
    names = ntemp
    times = ttemp
    paths = ptemp
end   

function get_tables()             -- read the tables
    if filenum > 0 then write_names() end  -- not first time
    lent = maxtables
    tbllen = {}
    tblentry = {}
    tbllock = {}
    tblbusy = {}
    for i = 1, lent do
      filename = getfilename(i)
      read_names(false)
      if len == 0 then
        tblentry[i] = "empty"
      else
        tblentry[i] = names[1]
      end
      tbllock[i] = filelocked
      tblbusy[i] = filebusy
      tbllen[i] = len
    end
    if filenum > 0 then
      filename = getfilename(filenum)
      read_names()                -- restore current table
    end
end

function tables_update()          -- show tables in dialog
    if not dlg then return end
    get_tables()
    list:clear()
    if lent > 0 then 
      list:add_value(tabletitle, 0)
      for i = 1, lent do
        t = i
        if i < 10 then t = "  "..i end
        if tbllock[i] == 1 then
          l = " X"
        elseif tbllock[i] == 2 then
          l = " K" 
        else       -- tbllock = 0
          l = "   "
        end
        b = ""
        if tblbusy[i] == 1 then b = "B" end
        n = tbllen[i]
        s = ""
        if n < 100 then s = "  "..s end
        if n < 10 then s = "  "..s end
        list:add_value(t..l..b.."\t"..s..n.."\t"..tblentry[i], i)
      end
    end
end

function open_table(doit)      -- make selection the current table
    if not doit then     -- doit means load the busy table from last call
      if not dlg then return nil end
      if not is_selection() then return nil end    -- no selection
      if selcount > 1 then return nil end          -- no multi-selection 
      if fstselidx == 0 then return nil end        -- table title line
      if fstselidx == filenum then return 1 end    -- current table
      get_tables()             --  refresh in case change
      tables_update()
    end
    if not doit and tblbusy[fstselidx] == 1 then
      setdlgmode(setopenyn)    -- table is already open or orphaned
    else
      filebusy = 0             -- close current table
      write_names()
      filenum = fstselidx
      filename = getfilename(filenum)
      read_names(false)        -- open new table
      filebusy = 1             -- tell others
      write_names()
      return 1
    end
end

function lock_table(mode)          -- set or unset exclude flag in tables
    if not is_selection() then return end
    if selcount == 1 and fstselidx == 0 then return end
    write_names()   -- save current table
    busyflag = false
    for idx, selectedItem in pairs(selection) do
      if idx == 0 then break end
      filename = getfilename(idx)
      read_names(false)
      if (filebusy == 1 and idx ~= filenum) or idx == 1 then
        busyflag = true
      else
        filelocked = mode  -- 0=normal 1=X(exclude) 2=K(exclude/keep media)
        write_names()
      end
    end
    setdlgmode(setdotables)
    if busyflag then label_msg:set_text(busylbl) end
    filename = getfilename(filenum)
    read_names()
end

function combine_tables()      -- move selected tables to current table
    if not dlg then return nil end
    if not is_selection() then return nil end
    if selcount == 1 and fstselidx == 0 then return nil end  -- title
    write_names()              -- save current table
    busyflag = false
    tnames = {}
    ttimes = {}
    tpaths = {}
    tlen = 0
    for idx, selectedItem in pairs(selection) do
      if idx == 0 or idx == filenum then break end
      filename = getfilename(idx)
      read_names(false)        -- read each selected table
      if filebusy == 1 then
        busyflag = true        -- don't move open tables
      else
        if len > 0 then        -- add table to this table
          for i =  1, len do
            tlen = tlen + 1
            tnames[tlen] = names[i]
            ttimes[tlen] = times[i]
            tpaths[tlen] = paths[i]
          end
          len = 0              -- clear the selected table
          write_names()
        end
      end
    end     
    filename = getfilename(filenum)      -- now reload current table
    read_names()
    if tlen > 0 then
      for i = 1 , tlen do
        ln = find_in_table(tnames[i])    -- check for dups
        if ln then
          if ttimes[i] > times[ln] then  -- if dup, save latest
            times[ln] = ttimes[i]
          end
        else
          len = len + 1                  -- add the selected tables
          names[len] = tnames[i]
          times[len] = ttimes[i]
          paths[len] = tpaths[i]
        end
      end
      write_names()              -- save
    end
    setdlgmode(setdotables)      -- don't stay in combine mode
    if busyflag then             -- warn about busy tables
      label_msg:set_text(busy2lbl)
    end
    return 1
end

function list_update()           -- redisplay
    if not dlg then return end
    if normal or deleteyn or sorttn or  -- don't update in tables mode
       movetb or getplayl or playyn then
      list:clear()
      if len > 0 then 
        for i = 1, len do
          t = hhmmss(times[i])
          if t == "00:00:01" then t = "Finished" end
          list:add_value(t.."   "..names[i], i)
        end
      end
    end
end

function setdlgmode(flag)        -- set dialog
    if not dlg then return end
    normal = false
    deleteyn = false
    playyn = false
    movetb = false
    getplayl = false
    dotables = false
    openyn = false
    combineyn = false
    sorttn = false
    allbusy = false
    lockmode = false
    if setnormal == flag then
      normal = true
      dlg:set_title("Resume Media Table "..filenum)
      list_update()
      label_msg:set_text(normallbl)
      button_1:set_text(setdeletelbl)
      button_2:set_text(movelbl)
      button_3:set_text(playlbl)
      button_4:set_text(tableslbl)
    elseif setdeleteyn == flag then
      deleteyn = true
      label_msg:set_text(deleteynlbl)
      button_1:set_text(startlbl)
      button_2:set_text(finishlbl)
      button_3:set_text(deletelbl)
      button_4:set_text(donelbl)
    elseif setplayyn == flag then
      playyn = true
      label_msg:set_text(playynlbl)
      button_1:set_text(yeslbl)
      button_2:set_text(nolbl)
      button_3:set_text(donelbl)
      button_4:set_text("        ")
    elseif setmovetb == flag then
      movetb = true
      label_msg:set_text(movetblbl)
      button_1:set_text(toplbl)
      button_2:set_text(botlbl)
      button_3:set_text(donelbl)
      button_4:set_text("        ")
    elseif setgetplayl == flag then
      getplayl = true
      label_msg:set_text(getplayllbl )
      button_1:set_text(yeslbl)
      button_2:set_text(nolbl)
      button_3:set_text(donelbl)
      button_4:set_text("        ")
    elseif setdotables == flag then
      dotables = true
      dlg:set_title("Resume Media Table "..filenum)
      tables_update()
      label_msg:set_text(lockmsglbl)
      button_1:set_text(openlbl)
      button_2:set_text(locklbl)
      button_3:set_text(combinelbl)
      button_4:set_text(backlbl)
    elseif setopenyn == flag then
      openyn = true
      label_msg:set_text(showynlbl )
      button_1:set_text(yeslbl)
      button_2:set_text(nolbl)
      button_3:set_text(donelbl)
      button_4:set_text("        ")
    elseif setcombineyn == flag then
      combineyn = true
      label_msg:set_text(combineynlbl )
      button_1:set_text(yeslbl)
      button_2:set_text(nolbl)
      button_3:set_text(donelbl)
      button_4:set_text("        ")
    elseif setsorttn == flag then
      sorttn = true
      label_msg:set_text(sorttnlbl )
      button_1:set_text(timelbl)
      button_2:set_text(namelbl)
      button_3:set_text(donelbl)
      button_4:set_text("        ")
    elseif setallbusy == flag then
      allbusy = true
      dlg:set_title("Resume Media")
      tables_update()
      label_msg:set_text(allbusylbl)
      button_1:set_text(openlbl)
      button_2:set_text("        ")
      button_3:set_text("        ")
      button_4:set_text(exitrmlbl)
    elseif setlockmode == flag then
      lockmode = true
      label_msg:set_text(lockmodelbl)
      button_1:set_text(resetlbl)
      button_2:set_text(removelbl)
      button_3:set_text(keeplbl)
      button_4:set_text(donelbl)
    end
end

function is_selection()               -- did the user select anything?
    if not dlg then return end
    selection = list:get_selection()  -- global var used by caller
    selcount = 0 
    for idx, selectedItem in pairs(selection) do
      fstselidx = idx                 -- global var used by caller
      selcount = selcount + 1         -- global var used by caller
    end
    return  selcount > 0
end

------------  temporary message functions to test code  -----------

function msgl(tf)
    if not dlg then return end
    if tf then
      message = "t"
    else
      message = "f"
    end 
    label_dbg:set_text(label_dbg:get_text().." "..message)
end

function msg(text)               -- msg in dialog label
    if not dlg then return end
    if text == nil then
      message = "Hello World"
    else
      message = text
    end
    label_dbg:set_text(label_dbg:get_text().." "..message)
end

------------- formatting functions (the old fashion way) --------

function secs(hhmmss)            -- "hh:mm:ss" to secs
    if string.len(hhmmss) ~= 8 then return 0 end -- oops
    h = string.sub(hhmmss,1,2)
    m = string.sub(hhmmss,4,5)
    s = string.sub(hhmmss,7,8)
    fsecs = s + m*60 + h*3600
return fsecs
end

function hhmmss(secs) -- secs to "hh:mm:ss"
    if secs < 0 or secs > 99*3600 then
      return "00:00:00"            -- oops
    end
    h = secs/3600
    hh = math.floor(h)
    m = (h - hh) * 60
    mm = math.floor(m)
    s = (m - mm) * 60
    ss = math.floor(s)
    if hh > 99 then hh = 99 end    -- just in case
    if hh < 10 then hh = "0"..hh end
    if mm < 10 then mm = "0"..mm end
    if ss < 10 then ss = "0"..ss end
    fhhmmss = hh..":"..mm..":"..ss
return fhhmmss
end

function integer(str)   -- hoping str is an integer in type string
    s = trim(str)
    oops = false
    for i = 1, string.len(s) do
      idx = string.find("-0123456789", string.sub(s,i,i), 1, true)
      if (not idx) then oops = true end
    end
    if oops then   -- if not an integer then set to 0
      num = 0
    else
      num = s + 0  -- convert to integer
    end
    return num 
end

function trim(s)  -- is there a lua trim function?
    if s == nil or s == "" then return "" end
    ts = s
    newls = string.len(ts)
    oldls = newls + 1
    while newls < oldls do
      if ts == "" or ts == " " then return "" end
      oldls = newls
      if string.sub(ts,1,1) == " " then
        ts = string.sub(ts,2)
        newls = newls - 1
      end
      if string.sub(ts,-1,-1) == " " then
        ts = string.sub(ts,1,-2)
        newls = newls - 1
      end
    end
    return ts
end  

------------- file input / output functions -------------------

function getfilename(tn)   -- get file name from table number
    fn = ""
    if tn > 1 then fn = " "..tn-1 end
    fn = string.sub(filebasename,1,-5)..fn..".txt"
    return fn
end

function get_file()
    filenum = 0
    get_tables()
    for i = 1, maxtables do
      if tblbusy[i] == 0 and tbllock[i] == 0 then
        filenum = i     -- get 1st file that isn't busy or locked
        break
      end
    end
    if filenum > 0 then 
      filename = getfilename(filenum)
      read_names(false)           -- read the table
      filebusy = 1                -- let other instances know
      write_names()
    end 
end

function read_names(optionsonly)
    file = io.open(filename,"r") 
    if (not file) then            -- exists?
      len = 0
      prevostime = 0
      filelocked = 0
      filebusy = 0
      return nil 
    end 
    len = -2
    for line in file:lines() do  -- load tables from file
      if len < 0 then   -- first two line are not part of table
        if len == -1 then 
          get_options(line)  -- comma separated options
          if optionsonly then
            file:close()
            return 0
          end
        end
        len = len + 1
      else                 -- look for filename , hh:mm:ss , uri
        ic = string.find(string.reverse(line),",",1,true) 
        ll = string.len(line)
        if ic then ic = ll - ic + 1 end    -- last comma in line
        if ic and ic>5 and ll-ic>8 then  -- basic error checking
          left = trim(string.sub(line,1,ic-1))
          path = trim(string.sub(line,ic+1))
          ic = string.find(string.reverse(left),",",1,true)
          ll = string.len(left)
          if ic then ic = ll - ic + 1 end   -- last comma
          if ic and ic>5 and ll-ic>8 then  -- basic error checking
            name = trim(string.sub(left,1,ic-1))
            time = secs(trim(string.sub(left,ic+1)))
            len = len + 1     --  now we have  filename , hh:mm:ss
            names[len] = name
            times[len] = time
            paths[len] = path
          end
        end
      end
    end
    file:close()
    return 1
end

function get_options(line)  -- extension options on line 2
    remainder = " "..trim(line).." "
    leno = 0
    while true do
      ic = string.find(remainder,",",1,true)
      ll = string.len(remainder)
      leno = leno + 1
      if not ic then
        optns[leno] = trim(remainder)
        break
      else
        optns[leno] = trim(string.sub(remainder,1,ic-1))
        remainder = " "..trim(string.sub(remainder,ic+1)).." "
      end
    end 
    if leno > 0 then         --  startup dialog option 
      prevostime = integer(optns[1]) 
    else
      prevostime = 0
    end 
    if leno > 1 then         --  startup dialog option 
      filelocked = integer(optns[2]) 
    else
      filelocked = 0
    end 
    if leno > 2 then         --  startup dialog option 
      filebusy = integer(optns[3]) 
    else
      filebusy = 0
    end 
end

function write_names()
    if len == 0 and filelocked == 0 and filebusy == 0 then  -- no sense saving empty file
      file = io.open(filename,"r") 
      if file then    -- nothing to save, so delete
        file:close()
        os.remove(filename)
      end
    else
      file = io.open(filename,"w")
      if file then
        file:write(infoline.."\n")   -- file descriptor
        file:write(os.time().." , "..filelocked.." , "..filebusy.."\n")
        for i = 1, len do
          file:write(names[i].." , "..hhmmss(times[i]).." , "..paths[i].."\n")
        end
        file:close()
      end
    end
end

------------------ VLC Extension functions ----------------------

function descriptor()
    return {title = "Resume Media V2";
            version = "2.20" ;
            author = "Rocky Dotterer" ;
            capabilities = {"input-listener"}
   }
end

function deactivate()
    if filenum > 0 then
      inpt = vlc.object.input()
      if inpt ~= nil and vlc.playlist.status() == "playing" then
        state = "stop"
        check_names()  -- possible update before leaving
      end
      filebusy = 0   -- no longer needed
      write_names()  -- output the updated file
    end
end

