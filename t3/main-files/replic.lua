local states_enum = require("states_enum")

-- local states_enum = {}
-- states_enum.FOLLOWER = "follower"
-- states_enum.CANDIDATE = "candidate"
-- states_enum.LEADER = "leader"

local REPLIC = {}

function REPLIC.newReplic(replicID)
  local term = 0 -- starts at zero
  local id = replicID
  local state = states_enum.FOLLOWER -- every replic starts as a follower
  local votes_granted = 0

  -- TODO: Find a way to make each replic vote only in one candidate per election
  local has_voted_this_term = false
  local list_replics = {} -- TODO: Necessary?? class instance having access to every replic may solve this

  local function convert_state(st)
    local first_char = string.sub(st,1,1):lower()
    if first_char == "f" then return states_enum.FOLLOWER
    elseif first_char == "c" then return states_enum.CANDIDATE
    elseif first_char == "l" then return states_enum.LEADER
    else
      print("replic.lua > [ERROR]: Replic's state must be 'Follower', 'Candidate' or 'Leader'")
      return nil
    end
  end

  return {
    getID = function () return id end,
    getState = function () return state end,
    setState = function (st) state = convert_state(st) end,
    getTerm = function () return term end,
    setTerm = function (t) term = t end,
    incTerm = function () term = term + 1 end,
    getVotesCount = function () return votes_granted end,
    isLeader = function () return state == states_enum.LEADER end,

    hasVoted = function () return has_voted_this_term end, -- one vote per term, or per election timeout ?
    grantVote = function () has_voted_this_term = true end,

    resetVotesCount = function ()
      votes_granted = 0
      has_voted_this_term = false
    end,

    incVotesCount = function () -- TODO: assert replic won't receive more than N (num of replics) votes
      votes_granted = votes_granted + 1
    end,

    printReplic = function ()
      local info = string.format("\t > term = %s\n\t > id = %s\n\t > state = %s \n\t > votes = %s\n",term,id,state,votes_granted)
      print(info)
      return info
    end
  }
end

return REPLIC
