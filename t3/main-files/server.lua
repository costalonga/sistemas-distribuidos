local luarpc = require("luarpc")

local porta0 = 8000
local porta1 = 8001
local porta2 = 8002

local IP = "127.0.0.1"
local arq_interface = "interface.lua"
local my_port = porta0

-- AppendEntries RPC
-- RequestVote RPC


local addresses = {
  {ip = IP, port = porta1},
  {ip = IP, port = porta2}
  -- TODO: should have port0 also ???
}


local myobj = {
  requestVotes = function (candidateTerm, candidateId, lastLogIndex, lastLogTerm)
    print("TODO - requesting votes...")
    local curr_term
    local vote_granted
    return curr_term, vote_granted
  end,

  appendEntries = function (leaderTerm, leaderId, prevLogIndex, entries, leaderCommit)
    print("TODO - sending heartbeats...")
    local curr_term
    local success
    return curr_term, success
  end,

  execute = function (addresses_lst) -- TODO: FIX, change back 'addresses_lst' -> 'addresses'
    local is_leader = true -- TODO: fix, this was used just for testing

    local p = luarpc.createProxy(IP, my_port, arq_interface)
    local proxies = {}
    for _,address in addresses do
      table.insert(proxies, luarpc.createProxy(address.ip, address.port, arq_interface))
    end

    while true do
      local rand_time = math.random(1,4) -- TODO: must be smaller than heartbets time
      print(string.format(" >>> [SERV] execute - before wait(%i) >>>",rand_time))
      luarpc.wait(rand_time)
      print(string.format(" <<< [SERV] execute - after wait(%i) <<<\n",rand_time))

      if is_learder then
        p.appendEntries() -- send heartbeats


      else
        is_leader = not is_leader -- TODO: fix, this was used just for testing
        if heartbeat_timeout <= last_heartbeat_occurance then
          for _,proxy in proxies do
            local ack = proxy.requestVotes()
            -- TODO: should request vote for itself also?
            treat_ack(ack)
            check_if_is_leader(ack)
          end
        end
      end
    end
  end
}

luarpc.createServant(myobj, "interface.lua", porta0)
luarpc.waitIncoming()




  --
  -- local wait = function (seg)
  --   local wait_time = socket.gettime() + seg
  --   local curr_co = coroutine.running()
  --   table.insert(co_awake_lst, 1, {co = curr_co, wait = wait_time})
  --   coroutine.yield()
  -- end
  -- local function execute()
  --   while true do
  --     for i = #a,1,-1 do
  --       if a[i].waitting <= co_awake_lst[i].getWaitTime() then
  --         local awaken_co = table.remove(a,i)
  --         -- print("REMOVED",j, j.co, j.waitting)
  --       else -- doesnt need to check anymore coroutines
  --         break
  --       end
  --     end
  --     local random_time = random_int(a,b) -- get random number between [a:b]
  --     wait(random_time)
  --   end
  -- end
  --
  --
  -- for i = #co_awake_lst,1,-1 do
  --   if co_awake_lst[i].getWaitTime() <= nowTime then
  --     local status = "time_to_wake_up"
  --     local co_to_wake = table.remove(request_msg, 1) -- pop index 1
  --   end
  -- end
  --

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
