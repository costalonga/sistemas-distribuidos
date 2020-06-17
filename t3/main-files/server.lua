local luarpc = require("luarpc")
local replic = require("replic")
local socket = require("socket")
local state = require("states_enum")

local porta0 = 8000
local porta1 = 8001
local porta2 = 8002
local porta3 = 8003
local porta4 = 8004

local IP = "127.0.0.1"
local arq_interface = "interface.lua"

-- AppendEntries RPC
-- RequestVote RPC

local my_port = tonumber(arg[1])

-- local addresses = {{ip = IP, port = porta1}}

-- TODO: Temp for testing... delete
local tmp_port
if my_port == 8000 then tmp_port = 8001 else tmp_port = 8001 end
local addresses = {{ip = IP, port = tmp_port}}

-- local addresses = {
--   {ip = IP, port = porta0},
--   {ip = IP, port = porta2},
--   {ip = IP, port = porta3},
--   {ip = IP, port = porta4}
--   -- TODO: should have port0 also ???
-- }


local my_replic = replic.newReplic(1 + my_port - 8000)
my_replic.printReplic()

local myobj = {
  requestVotes = function (candidateTerm, candidateId)
    print("TODO - requesting votes...")
    local caID = candidateId
    local caTerm = candidateTerm
    local myID = my_replic.getID()
    local curr_term = my_replic.getTerm()
    local vote_granted = false

    print(string.format("[SRV%i] myID=%i caID=%i | myterm=%i caTerm=%i",myID,myID,caID,curr_term,caTerm))

    -- cases where vote is granted
    -- NOTE-BUG ? WHY This if clause doens't work without 'tonumber' ???
    if tonumber(caTerm) > tonumber(curr_term) then -- candidate has a better rank -- BUG?
      curr_term = caTerm -- TODO-V3-tests check if this assertion wont fail in case Ex2* (mudar o term da eleição de outro candidato?)
      if my_replic.getState() == state.FOLLOWER then -- must be a follower
        if not my_replic.hasVoted() then -- must not have voted this election
          my_replic.grantVote()
          vote_granted = true
        end
      end
    end
    -- TODO-V3-tests: O que deve acontecer no caso de duas eleições simultaneas??
        -- Ex: No github -> Ambos os candidatos estão no mesmo Term -> replicas votam em que chegar primeiro
        -- Ex2*: Candidatos estão em Terms diferentes -> escolhe quem estiver em maior term ou quem chegar primeiro ?

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
    local myID = my_replic.getID()
    local proxies = {}

    for _,address in pairs(addresses) do
      print(address, address.ip, address.port)
      table.insert(proxies, luarpc.createProxy(address.ip, address.port, arq_interface))
    end

    local heartbeat_timeout = 5 -- TODO: get a random valid time
    local last_heartbeat_occurance = socket.gettime() -- TODO: get a random valid time

    while true do
      -- local rand_wait_time = math.random(4) -- TODO: must be smaller than heartbets time
      local rand_wait_time = 5 -- TODO: must be smaller than heartbets time
      -- local heartbeat_timeout = math.random(7)


      print(string.format("\t\t >>> [SRV%i] execute - before wait(%i) >>>",myID,rand_wait_time))
      luarpc.wait(rand_wait_time)
      print(string.format("\t\t  <<< [SRV%i] execute - after wait(%i) <<<\n",myID,rand_wait_time))

      if my_replic.isLeader() then
        my_proxy.appendEntries() -- send heartbeats

      else
        -- se nao recebeu nenhum heartbeat até o tempo limite, inicia pedido de votos
        if socket.gettime() >= last_heartbeat_occurance + heartbeat_timeout then
          print(string.format("\n\n\t\t  <<< [SRV%i] GOING TO REQUEST VOTES <<<\n",myID,rand_wait_time))

          my_replic.resetVotesCount() -- reset vote count from last term
          my_replic.setState("c") -- set to candidate
          my_replic.incTerm() -- vote for itself
          for _,proxy in pairs(proxies) do

            local curr_term, vote_granted = proxy.requestVotes(my_replic.getTerm(), myID)
            if vote_granted then my_replic.incVotesCount() end
            if curr_term ~= my_replic.getTerm() then my_replic.setTerm(curr_term) end -- is it possible to change a term in the middle of an election
          end

          last_heartbeat_occurance = socket.gettime() -- TODO-testing: fix this (should not be here)!!

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
