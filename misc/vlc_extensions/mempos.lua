-- Extension description
function descriptor()
 return { title = "Remember position" ;
  version = "1.0" ;
  author = "August" ;
  url = 'http://www.opensubtitles.org/';
  shortdesc = "Remember file pos";
  description = "Remember file position.\n"
    .. "Maintains a database of current play position for all files played." ;
  capabilities = { "input-listener" }
 }
end

function serialize (o)
      if type(o) == "number" then
        io.write(string.gsub(o,",","."))
      elseif type(o) == "string" then
        io.write(string.format("%q", o))
      elseif type(o) == "table" then
        io.write("{\n")
        for k,v in pairs(o) do
          io.write("  [\"", k, "\"] = ")
          serialize(v)
          io.write(",\n")
        end
        io.write("}\n")
      else
        error("cannot serialize a " .. type(o))
      end
    end

lastsavepos=0

function activate()
   vlc.msg.dbg("[remember pos] Welcome")

   local input = vlc.object.input()
   if input then
      vlc.var.add_callback(input, "intf-event", input_event_handler, "Hello world!")
   end
   datafile=vlc.misc.userdatadir().."/pos.txt"
   pcall(dofile,datafile)
   if input then input_changed() end 
end
function meta_changed()
end
function deactivate()
 vlc.msg.dbg("[remember pos] deact")
 local input = vlc.object.input()
   if input then
      vlc.var.del_callback(input, "intf-event", input_event_handler, "Hello world!")
   end
end

input=0
filelist={}
currentitem=""
function savedb()
-- save position database
 io.output(datafile)
 io.write("filelist=")
 serialize(filelist)
 io.close()
end


function input_changed()
 
        if not input== 0 then
    -- Delete old callback
           vlc.var.del_callback(input, "intf-event", input_event_handler, "Hello world!")
        end

 savedb()
 vlc.msg.dbg("[remember pos] input changed..!")
 item=vlc.item or vlc.input.item()
 currentitem=item:name()
 input = vlc.object.input()

 vlc.var.add_callback(input, "intf-event", input_event_handler, "Hello world!")

 local elapsed_time=filelist[currentitem]
 if (elapsed_time) then 
  vlc.var.set(input, "time",elapsed_time)
  vlc.msg.dbg("[remember pos] Found item in db")
 end
 lastsavepos=elapsed_time

 return false
end

function input_event_handler(var, old, new, data)
 local elapsed_time = vlc.var.get(input, "time")
-- print(input)
 filelist[currentitem]=elapsed_time
--save file every 10 seconds
 if elapsed_time>lastsavepos+10 or elapsed_time<lastsavepos then
  savedb();
  lastsavepos=elapsed_time;
 end
end
