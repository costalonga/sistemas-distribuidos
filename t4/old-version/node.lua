local socket = require("socket")
-- local state = require("states_enum") -- TODO: use to show whether or not node is waiting for obj to be inserted ??

local NODE = {}

function NODE.newNode(nodeID, numNodes, randomSeed)
  local id = nodeID
  local num_nodes = numNodes
  local last_beat = socket.gettime()
  local seed
  local data_base = {}
  local edges = {}

  if not randomSeed or type(randomSeed) ~= "number"then
    seed = os.time()
  else
    seed = randomSeed
  end
  math.randomseed(seed)

  return {
    -- Basic methods
    getID = function () return id end,
    getNodesNumber = function () return num_nodes end,
    insertData = function (key, value) data_base[key] = value end,
    getValue = function (key) return data_base[key] end,

    -- TODO: delete
    -- getRandomWait = function () return math.random(1,10)/10 end
    getRandomWait = function () return 1 end
  }
end

return NODE
