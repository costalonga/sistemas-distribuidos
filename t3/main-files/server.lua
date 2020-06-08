local luarpc = require("luarpc")

local porta0 = 8000
local porta1 = 8001
local porta2 = 8002

local IP = "127.0.0.1"
local arq_interface = "interface.lua"

-- AppendEntries RPC
-- RequestVote RPC

local myobj = {
  -- dummy = function (n)
  --   local n2 = n*n
  --   local p = luarpc.createProxy_for_server(IP, porta1, arq_interface) -- never enters but never leaves ??
  --   local r1 = p.boo(n2)
	-- 	return r1
  -- end,
  execute = function (addresses)
    luarpc.wait()
  end,
  send_heartbeat() print("TODO - sending heartbeats...") end,
  request_votes() print("TODO - requesting votes...") end
}

luarpc.createServant(myobj, "interface.lua", porta0)
luarpc.waitIncoming()





  local wait = function (seg)
    local wait_time = socket.gettime() + seg
    local curr_co = coroutine.running()
    table.insert(co_awake_lst, 1, {co = curr_co, wait = wait_time})
    coroutine.yield()
  end
  local function execute()
    while true do
      for i = #a,1,-1 do
        if a[i].waitting <= co_awake_lst[i].getWaitTime() then
          local awaken_co = table.remove(a,i)
          -- print("REMOVED",j, j.co, j.waitting)
        else -- doesnt need to check anymore coroutines
          break
        end
      end
      local random_time = random_int(a,b) -- get random number between [a:b]
      wait(random_time)
    end
  end


  for i = #co_awake_lst,1,-1 do
    if co_awake_lst[i].getWaitTime() <= nowTime then
      local status = "time_to_wake_up"
      local co_to_wake = table.remove(request_msg, 1) -- pop index 1
    end
  end


-- a = {}
-- table.insert(a,1,b)
-- table.insert(a,1,c)
-- table.insert(a,1,d)
-- table.insert(a,1,e)
--
--
-- for i = #a,1,-1 do
--   if a[i].waitting <= 17 then
--     local j = table.remove(a,i)
--     print("REMOVED",j, j.co, j.waitting)
--   else
--     print("OKAY",a[i], a[i].co, a[i].waitting)
--     break
--   end
-- end
