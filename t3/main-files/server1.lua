local luarpc = require("luarpc")
local replic = require("replic")
local socket = require("socket")

local porta0 = 8000
local porta1 = 8001
local porta2 = 8002
local porta3 = 8003
local porta4 = 8004

local IP = "127.0.0.1"
local arq_interface = "interface.lua"

-- AppendEntries RPC
-- RequestVote RPC

local my_port = porta1

local addresses = {{ip = IP, port = porta0}}


-- local addresses = {
--   {ip = IP, port = porta0},
--   {ip = IP, port = porta2},
--   {ip = IP, port = porta3},
--   {ip = IP, port = porta4}
--   -- TODO: should have port0 also ???
-- }


local my_replic = replic.newReplic(1 + my_port - 8000)

local myobj = {
  requestVotes = function (candidateTerm, candidateId)
    print("TODO - requesting votes...")
    local caID = candidateId
    local caTerm = candidateTerm
    local myID = my_replic.getID()
    local myterm = my_replic.getTerm()
    print(string.format("[SVR2] myID=%i caID=%i | myTerm=%i caTerm=%i",myID,caID,myterm,caTerm))
    local curr_term
    local vote_granted
    return curr_term, vote_granted
  end,

  appendEntries = function (leaderTerm, leaderId)
    print("TODO - sending heartbeats...")
    local curr_term
    local success
    return curr_term, success
  end,

  execute = function (addresses_lst) -- TODO: FIX, change back 'addresses_lst' -> 'addresses'
    local is_leader = true -- TODO: fix, this was used just for testing
    -- local my_replic = replic.newReplic(1 + my_port - 8000)
    local my_proxy = luarpc.createProxy(IP, my_port, arq_interface)
    local proxies = {}

    for _,address in addresses do
      table.insert(proxies, luarpc.createProxy(address.ip, address.port, arq_interface))
    end

    while true do
      local rand_wait_time = math.random(2) -- TODO: must be smaller than heartbets time
      -- local heartbeat_timeout = math.random(7)
      local heartbeat_timeout = 7
      local last_heartbeat_occurance = socket.gettime() + 6

      print(string.format(" >>> [SRV2] execute - before wait(%i) >>>",rand_wait_time))
      luarpc.wait(rand_wait_time)
      print(string.format(" <<< [SRV2] execute - after wait(%i) <<<\n",rand_wait_time))

      if my_replic.isLeader() then
        my_proxy.appendEntries() -- send heartbeats

      else
        -- se nao recebeu nenhum heartbeat até o tempo limite, inicia pedido de votos
        if heartbeat_timeout + socket.gettime() <= last_heartbeat_occurance then
          my_replic.resetVotesCount() -- reset vote count from last term
          my_replic.setState("c") -- set to candidate
          my_replic.incTerm() -- vote for itself
          for _,proxy in proxies do
            local vote_granted = proxy.requestVotes(my_replic.getTerm(), my_replic.getID())
            if vote_granted then my_replic.incVotesCount() end
            -- TODO: should request vote for itself also?
            -- treat_ack(ack)
            -- check_if_is_leader(ack)
          end
        end
      end
    end
  end
}

luarpc.createServant(myobj, "interface.lua", my_port)
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
