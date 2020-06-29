local luarpc = require("luarpc")
local replic = require("replic")
local state = require("states_enum")

local IP = "127.0.0.1"
local arq_interface = "interface.lua"

-- AppendEntries RPC
-- RequestVote RPC

local my_port = tonumber(arg[1])
local n_replics = tonumber(arg[2])

-- TODO: use random times
local HEARTBEAT_TIMEOUT = tonumber(arg[3])
local WAIT_TIMEOUT = tonumber(arg[4])


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
print("My port:",my_port,"\n")
for i,j in pairs(addresses) do
  print("Other's:",j.port)
end
-- improve this


local my_replic = replic.newReplic(1 + my_port - 8000, #addresses+1)
my_replic.printReplic()

-- Stub's methods list
local myobj = {
  requestVotes = function (candidateTerm, candidateId)
    local myID = my_replic.getID()
    local curr_term = my_replic.getTerm()
    local vote_granted = false

    print(string.format(" >>> [SRV%i] - RECEIVED VOTE REQUEST: myID=%i caID=%i | myterm=%i caTerm=%i",myID,myID,candidateId,curr_term,candidateTerm))

    -- cases where vote is granted
    -- NOTE-BUG ? WHY This if clause doens't work without 'tonumber' ???
    -- "If a server receives a request with a stale (old) term number, it rejects the request."
    if tonumber(candidateTerm) > tonumber(curr_term) then -- will only vote if candidate has a greater term (that implies that no replic can vote for more than one candidate in one term)
      vote_granted = true
      curr_term = candidateTerm
      my_replic.setTerm(curr_term) -- update current term

      --  If a candidate or leader discovers discovers that its term is out of
      -- date, it immediately reverts to follower state.
      if not my_replic.isFollower() then
        my_replic.setState(state.FOLLOWER)
        my_replic.updateLastBeat() -- "reset" heartbeat due so ex-leader/candidate doesnt start new election immediately
      end
    end
    print(string.format(" >>> >>> [SRV%i] - RESULT:",myID),curr_term, vote_granted,"\n")
    return curr_term, tostring(vote_granted)
  end,

  appendEntries = function (leaderTerm, leaderId)
    local myID = my_replic.getID()
    local curr_term = my_replic.getTerm()
    local success = false

    print(string.format(" >>> [SRV%i] - HEARTBEAT RECEIVED: myID=%i ldID=%i | myTerm=%i ldTerm=%i",myID,myID,leaderId,curr_term,leaderTerm))

    if tonumber(leaderTerm) >= tonumber(curr_term) then -- will only vote if candidate has a greater term (that implies that no replic can vote for more than one candidate in one term)
      success = true -- either is a new leader or old leader
      my_replic.updateLastBeat()

      -- TODO: verificar se isso pode fazer com que um leader mais antigo perca seu posto para uma replica que virou leader mais recentemente DE MESMO TERM (o que nao deveria acontecer)
      if not my_replic.isFollower() then
        my_replic.setState(state.FOLLOWER)
      end

      if tonumber(leaderTerm) > tonumber(curr_term) then
        curr_term = leaderTerm
        my_replic.setTerm(curr_term) -- update current term
      end
    end

    return curr_term, tostring(success)
  end,

  execute = function (addresses_lst) -- TODO: FIX, change back 'addresses_lst' -> 'addresses'
    local my_proxy = luarpc.createProxy(IP, my_port, arq_interface)
    local myID = my_replic.getID()
    local proxies = {}

    my_replic.updateLastBeat() -- todo here

    for _,address in pairs(addresses) do
      print("Creating Proxy at:", address, address.ip, address.port) -- [DEBUG]
      table.insert(proxies, luarpc.createProxy(address.ip, address.port, arq_interface))
    end

    -- local heartbeat_timeout = HEARTBEAT_TIMEOUT -- TODO: get a random valid time
    local heartbeat_timeout = replic.getRandomHeartbeatDue()

    while true do
      -- local rand_wait_time = math.random(4) -- TODO: must be smaller than heartbets time
      -- local rand_wait_time = WAIT_TIMEOUT -- TODO: must be smaller than heartbets time
      -- local heartbeat_timeout = math.random(7)


      -- Send Heartbeats
      if my_replic.isLeader() then -- send heartbeats
        print(string.format("\n >>>  [SRV%i] GOING TO REQUEST HEARBEATS \t<<<",myID))

        for i=#proxies,1,-1 do
          local proxy = proxies[i]
          local ack, success = proxy.appendEntries(my_replic.getTerm(), myID)

          if ack == "__ERROR_CONN" then -- TODO: Check if this is working... probably need more assertions because crash can happen anytime... this won't solve if server crashes after connection and before answering the request"
            print(string.format(" >>>  [SRV%i] FORGETTING REPLIC\n",myID))
            table.remove(proxies,i)
            my_replic.decReplicsNumber() -- decrease the number of replics and update min_votes to become leader

          else
            local curr_term = ack
            print(string.format(" >>> >>> [SRV%i] RECEIVED:",myID), curr_term, success)
            if curr_term > my_replic.getTerm() then
              my_replic.setTerm(curr_term)
              my_replic.setState(state.FOLLOWER) -- set to follower
              my_replic.updateLastBeat() -- "reset" heartbeat due so ex-leader/candidate doesn't start new election immediately
              break
            end
          end
        end
      end

      --  TODO:  If election timeout elapses without receiving AppendEntries
      -- RPC from current leader or granting vote to candidate:
      -- convert to candidate

      -- TODO NOW!!! Adicionar um tempo para recomeçar nova eleicao em caso de empate (acho que manter estado como candidato nao resolve)

      -- Wait
      luarpc.wait(replic.getRandomWait())

      if not my_replic.isLeader() then
        -- se nao recebeu nenhum heartbeat até o tempo limite, inicia pedido de votos
        -- ou se ultima eleicao nao teve vencedor, precisa comecar uma nova -- TODO HERE CHECK WHAT TO DO IN THIS CASE
        if my_replic.isHeartbeatOverdue(heartbeat_timeout) then
          -- print(string.format(" >>>  [SRV%i] GOING TO REQUEST VOTES <<<\n",myID))

          -- TODO-V2: change 'votes_count' to local var, so it doenst need to control reset... ??
          heartbeat_timeout = replic.getRandomHeartbeatDue()

          -- start election
          my_replic.resetVotesCount() -- reset vote count from last term
          my_replic.setState(state.CANDIDATE) -- set to candidate
          my_replic.incTerm() -- increases curr term
          my_replic.incVotesCount() -- vote for itself
          -- TODO Reset election timer

          -- ask for other votes
          for i=#proxies,1,-1 do
          -- for _,proxy in pairs(proxies) do
            local proxy = proxies[i]

            print(string.format("\n >>> [SRV%i] GOING TO REQUEST VOTES \t<<<",myID))
            local ack, vote_granted = proxy.requestVotes(my_replic.getTerm(), myID)

            if ack == "__ERROR_CONN" then -- TODO: Check if this is working... probably need more assertions because crash can happen anytime... this won't solve if server crashes after connection and before answering the request"
              print(string.format(" >>>  [SRV%i] FORGETTING REPLIC <<<\n",myID))
              table.remove(proxies,i)
              my_replic.decReplicsNumber() -- decrease the number of replics and update min_votes to become leader

            else
              local curr_term = ack
              if vote_granted == "true" then
                local won_election = my_replic.incVotesCount()
                print(string.format(" >>>  [SRV%i] RECEIVED VOTE!!! Count=%i\n",myID, my_replic.getVotesCount()))
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
                my_replic.updateLastBeat()
                -- my_replic.resetVotesCount() -- XXX needed ?? XXX
                break
              end

            -- TODO: if election timeout elapses: start new election
            end
          end
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
