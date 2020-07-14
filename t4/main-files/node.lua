local socket = require("socket")

local NODE = {}

function NODE.newNode(nodeID, numNodes, debugLevel)
  local my_id = nodeID
  local port = nodePort
  local num_nodes = numNodes
  local data_base = {}
  local exp = math.floor(math.log(num_nodes) / math.log(2)) -- using Euler as C.: log B(A) = log C(A) / log C(B)
  local mod2n = math.pow(2, exp)
  local edges = {}
  local dist_ranges = {}

  -- create directed edges to connect nodes
  local log_msg = string.format(" >> [node %i] is connected to edges: ",my_id)
  for i=0,exp-1 do
    local exp2i = math.pow(2,i)
    local neighbor_id = (my_id + exp2i) % mod2n
    log_msg = log_msg .. string.format("%i, ",neighbor_id)
    table.insert(edges, neighbor_id)
    table.insert(dist_ranges, exp2i)
  end

  if debugLevel == "v" then
    log_msg = log_msg .. "\n\n"
    random_method = function () return 5 end
  else
    math.randomseed(os.time())
    random_method = function () return math.random(1,10)/10 end
  end

  return {
    -- Basic methods
    getID = function () return my_id end,
    getNodesNumber = function () return num_nodes end,
    insertData = function (key, value) data_base[key] = value end,
    getValue = function (key) return data_base[key] end,
    getEdges = function () return edges end,
    findNext = function (dest_id)
      local total_dist = (dest_id + mod2n - my_id) % mod2n
      local next_node
      for _,dist in pairs(dist_ranges) do
        if total_dist >= dist then
          next_node = (my_id + dist) % mod2n
        end
      end
      -- print(string.format(" >>> node %i is going to node %i",my_id,next_node)) -- [DEBUG]
      return next_node
    end,
    calc_hash = function(key)
      local bkey = 0
      for i=1,#key do
        bkey = bkey + string.byte(key:sub(i,i))
      end
      return bkey % mod2n
    end,


    getLogMsg = function () return log_msg end,
    -- getRandomWait = function () return math.random(1,10)/10 end
    -- getRandomWait = function () return math.random(2,3) end
    getRandomWait = random_method
  }
end

return NODE
