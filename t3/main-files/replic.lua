local states_enum = require("states_enum")
local socket = require("socket")


-- local states_enum = {}
-- states_enum.FOLLOWER = "follower"
-- states_enum.CANDIDATE = "candidate"
-- states_enum.LEADER = "leader"

local function get_majority(n)
  return math.floor(n/2)+1
end

local REPLIC = {}

function REPLIC.newReplic(replicID, numReplics)
  local curr_term = 0 -- starts at zero
  local id = replicID
  local state = states_enum.FOLLOWER -- every replic starts as a follower
  local votes_granted = 0
  local num_replics = numReplics
  local majority = get_majority(numReplics)
  local heartbeat_due = 0 -- TODO check if there's a better way to do this
  local last_beat = socket.gettime()
  local seed = os.time()
  math.randomseed(seed)


  -- local function convert_state(st)
  --   local first_char = string.sub(st,1,1):lower()
  --   if first_char == "f" then return states_enum.FOLLOWER
  --   elseif first_char == "c" then return states_enum.CANDIDATE
  --   elseif first_char == "l" then return states_enum.LEADER
  --   else
  --     print("replic.lua > [ERROR]: Replic's state must be 'Follower', 'Candidate' or 'Leader'")
  --     return nil
  --   end
  -- end

  return {
    -- Basic methods
    getID = function () return id end,
    getState = function () return state end,
    -- setState = function (st) state = convert_state(st) end, -- not needed anymore
    setState = function (st) state = st end,
    getTerm = function () return curr_term end,
    setTerm = function (term) curr_term = term end,
    incTerm = function () curr_term = curr_term + 1 end,
    isLeader = function () return state == states_enum.LEADER end,
    isFollower = function () return state == states_enum.FOLLOWER end,
    isCandidate = function () return state == states_enum.CANDIDATE end,

    -- Vote methods
    getVotesCount = function () return votes_granted end,
    resetVotesCount = function () votes_granted = 0 end,
    incVotesCount = function () -- TODO: assert replic won't receive more than N (num of replics) votes
      votes_granted = votes_granted + 1
      if votes_granted >= majority then
        print(string.format("\n\t >>> [REP%i] term = %i won election with: %i votes!!!\n",id,curr_term,votes_granted)) -- [DEBUG]
        return true -- won the election
      end
      return false
    end,

    -- Heartbeat methods
    getLastBeat = function() return last_beat end,
    updateLastBeat = function ()
      last_beat = socket.gettime()
      -- print("\n\t >>> UPDATED LAST BEAT:", socket.gettime(), "\n")
    end,
    isHeartbeatOverdue = function (hbeat_timeout)
      return socket.gettime() > (last_beat + hbeat_timeout)
    end,

    printExpirationTime = function (hbeat_timeout)
      local tmp = last_beat + hbeat_timeout
      local now = socket.gettime()
      -- print(string.format("Last Beat = %s | Time Now = %s | Heartbeat Due = %s",last_beat,now,tmp))
      print(string.format(" > Time Now >= Last Beat + Timeout ? %s \t (remaining = %s)",now >= tmp, tmp-now), state)
    end,

    -- Methods for when a replic crashes
    updateReplicsNumber = function (n)
      num_replics = n
      majority = get_majority(num_replics)
    end,
    decReplicsNumber = function ()
      num_replics = num_replics - 1
      majority = get_majority(num_replics)
    end,
    getReplicsNumber = function () return num_replics end,

    -- Wait Methods
    getRandomWait = function () return math.random(1,10)/10 end,
    getRandomHeartbeatDue = function () return math.random(30,40)/10 end,

    -- Aux methods
    printReplic = function ()
      local info = string.format("\t > id = %s\n\t > curr_term = %s\n\t > state = %s \n\t > votes = %s\n\t > majority = %s\n\t > seed = %s\n",id,curr_term,state,votes_granted,majority,tostring(seed))
      print(info)
      return info
    end
  }
end

return REPLIC
