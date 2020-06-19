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
local n_replics = tonumber(arg[2])

-- local addresses = {{ip = IP, port = porta1}}

-- local addresses = {
--   {ip = IP, port = porta0},
--   {ip = IP, port = porta2},
--   {ip = IP, port = porta3},
--   {ip = IP, port = porta4}
-- }

-- TODO: improve this
local addresses = {}
for i=0,n_replics-1 do
  table.insert(addresses, {ip = IP, port = 8000+i})
end
for i=#addresses,1,-1 do
  if addresses[i].port == my_port then
    table.remove(addresses,i)
  end
end

print("ADDRESSES:")
print(0,my_port,"\n")
for i,j in pairs(addresses) do
  print(i,j.port)
end
-- improve this


local my_replic = replic.newReplic(1 + my_port - 8000, #addresses+1)
my_replic.printReplic()

local myobj = {
  requestVotes = function (candidateTerm, candidateId)
    print("TODO - RECEIVED VOTE REQUEST")
    local myID = my_replic.getID()
    local curr_term = my_replic.getTerm()
    local vote_granted = false

    print(string.format("\t\t >>> [SRV%i] - VOTE: myID=%i caID=%i | myterm=%i caTerm=%i",myID,myID,candidateId,curr_term,candidateTerm))

    -- cases where vote is granted
    -- NOTE-BUG ? WHY This if clause doens't work without 'tonumber' ???
    -- "If a server receives a request with a stale (old) term number, it rejects the request."
    if tonumber(candidateTerm) > tonumber(curr_term) then -- will only vote if candidate has a greater term (that implies that no replic can vote for more than one candidate in one term)
      curr_term = candidateTerm
      my_replic.setTerm(curr_term) -- update current term

      --  If a candidate or leader discovers discovers that its term is out of
      -- date, it immediately reverts to follower state.
      local my_state = my_replic.getState()
      if my_state == state.CANDIDATE or my_state == state.LEADER then
        my_replic.setState(state.FOLLOWER)
        my_replic.resetVotesCount() -- XXX needed ?? XXX
      end

      if my_replic.getState() == state.FOLLOWER then
        vote_granted = true
      end
    end
    print(curr_term, vote_granted)
    return curr_term, vote_granted
  end,

  appendEntries = function (leaderTerm, leaderId)
    print("TODO - sending heartbeats...")
    local myID = my_replic.getID()
    local curr_term = my_replic.getTerm()
    local success = false

    print(string.format("\t\t >>> [SRV%i] - HEARTBEAT: myID=%i ldID=%i | myTerm=%i ldTerm=%i",myID,myID,leaderId,curr_term,leaderTerm))

    if tonumber(leaderTerm) >= tonumber(curr_term) then -- will only vote if candidate has a greater term (that implies that no replic can vote for more than one candidate in one term)
      success = true -- either is a new leader or old leader
      if tonumber(leaderTerm) > tonumber(curr_term) then
        curr_term = leaderTerm
        my_replic.setTerm(curr_term) -- update current term
      end
    end

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

    local heartbeat_timeout = 45 -- TODO: get a random valid time -- TODO começar testes com valores grandes
    local last_heartbeat_occurance = socket.gettime() -- TODO: get a random valid time

    while true do
      -- local rand_wait_time = math.random(4) -- TODO: must be smaller than heartbets time
      local rand_wait_time = 0.000001 -- TODO: must be smaller than heartbets time
      -- local heartbeat_timeout = math.random(7)


      -- print(string.format("\t\t >>> [SRV%i] execute - before wait(%s) >>>",myID,rand_wait_time))
      luarpc.wait(rand_wait_time)
      -- print(string.format("\t\t  <<< [SRV%i] execute - after wait(%s) <<<\n",myID,rand_wait_time))

      if my_replic.isLeader() then -- send heartbeats
        for _,proxy in pairs(proxies) do
          local curr_term, success = proxy.appendEntries(my_replic.getTerm(), myID)
          -- if success then ... end TODO: do something? -- NOTE: I think this would only be used if we were considering using the Log Entries...
          if curr_term > my_replic.getTerm() then
            my_replic.setTerm(curr_term)
            my_replic.setState(state.FOLLOWER) -- set to follower
            break
          end
        end

      --  TODO:  If election timeout elapses without receiving AppendEntries
      -- RPC from current leader or granting vote to candidate:
      -- convert to candidate

      else
        -- se nao recebeu nenhum heartbeat até o tempo limite, inicia pedido de votos
        if socket.gettime() >= last_heartbeat_occurance + heartbeat_timeout then
          print(string.format("\t\t >>>  [SRV%i] GOING TO REQUEST VOTES <<<\n",myID,rand_wait_time))

          -- TODO-V2: change 'votes_count' to local var, so it doenst need to control reset... ??

          -- start election
          my_replic.resetVotesCount() -- reset vote count from last term
          my_replic.setState(state.CANDIDATE) -- set to candidate
          my_replic.incTerm() -- increases curr term
          my_replic.incVotesCount() -- vote for itself
          -- TODO Reset election timer

          -- ask for other votes
          for _,proxy in pairs(proxies) do
            local curr_term, vote_granted = proxy.requestVotes(my_replic.getTerm(), myID)
            print(string.format("\t\t >>>  [SRV%i] GOING TO REQUEST VOTES <<<\n",myID))
            if vote_granted then
              print(string.format("\t\t >>>  [SRV%i] RECEIVED VOTE!!! #%s <<<\n",myID, my_replic.getVotesCount()),vote_granted)
              local won_election = my_replic.incVotesCount()

              if won_election then
                my_replic.setState(state.LEADER) -- set to candidate
                -- TODO: Checkout 'rand_wait_time' so elected leader go right after to AppendEntries()
                break
              end
            end

            --   "If a candidate or leader discovers that its term is out of
            -- date, it immediately reverts to follower state."
            if curr_term > my_replic.getTerm() then
              my_replic.setTerm(curr_term)
              my_replic.setState(state.FOLLOWER) -- set to follower
              my_replic.resetVotesCount() -- XXX needed ?? XXX
              break
            end

            -- TODO: if election timeout elapses: start new election

          end

          last_heartbeat_occurance = socket.gettime() -- TODO-testing: fix this (should not be here)!!

        end
      end
    end
  end
}

luarpc.createServant(myobj, "interface.lua", my_port)
luarpc.waitIncoming()





-- NOTE: Notes from Raft's Arctile:
--   "If a candidate or leader discovers that its term is out of date,
-- it immediately reverts to follower state."
--  "If a server receives a request with a stale (old) term
-- number, it rejects the request."

-- While waiting for votes, a candidate may receive an
-- AppendEntries RPC from another server claiming to be leader.
  --   If the leader’s term (included in its RPC) is at least
  -- as large as the candidate’s current term, then the candidate
  -- recognizes the leader as legitimate and returns to follower
  -- state.

  --   If the term in the RPC is smaller than the candidate’s
  -- current term, then the candidate rejects the RPC and con-
  -- tinues in candidate state.

  --   The third possible outcome is that a candidate neither
  -- wins nor loses the election:
