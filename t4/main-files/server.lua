local luarpc = require("luarpc")
local node = require("node")

local IP = "127.0.0.1"
local arq_interface = "interface.lua"

local my_port = tonumber(arg[1])
local num_nodes = tonumber(arg[2])
local debug_level = arg[3]

if debug_level == "v" then -- verbose then
  --   Same file as "luarpc.lua" but with more log messages to help debugging,
  -- adding os.time() at prints and using bigger time for wait() method, just so
  -- coroutines doesn't print "waiting value to be inserted" multiple times
  luarpc = require("luarpc_debug")
end



local my_node = node.newNode(my_port - 8000, num_nodes, debug_level)
local myID = my_node.getID()

-- Build table with IP / Port from all nodes
local addresses = {}

for i=0,num_nodes-1 do
  addresses[i] = {ip = IP, port = 8000+i}
end
local log_msg1 = string.format(" >> [node %i] #addresses = %i",myID,#addresses)
local log_msg2 = string.format(" | ports: %s ... %s | ",addresses[0].port,addresses[#addresses].port)
print(log_msg1 .. log_msg2 .. my_node.getLogMsg())

local proxies = {}
for _,edge in pairs(my_node.getEdges()) do
  local address = addresses[edge]
  -- print(string.format("[node %i] Creating Proxy at:",myID), address, address.ip, address.port) -- [DEBUG]
  proxies[edge] = luarpc.createProxy(address.ip, address.port, arq_interface)
  -- table.insert(proxies, luarpc.createProxy(address.ip, address.port, arq_interface))
end


-- Stub's methods list
local myobj = {

  insere = function(init_node, key, value)
    print(string.format("\t >>> >>> [node %i] - RECEIVED INSERT REQUEST (init:%i k:%s v:%s)\t",myID,init_node,key,value))
    local destID = my_node.calc_hash(key)
    if destID == myID then
      my_node.insertData(key,value)
      local log = string.format("\t Par <%s : %s> enviado ao nó %i: foi armazenado no nó %i", key, value, init_node, destID)
      print(string.format("\t >>> >>> [node %i]",myID) .. log .. "\n")
      return log
    else
      local nextID = my_node.findNext(destID)
      local proxy = proxies[nextID]
      local ack = proxy.insere(init_node,key,value)
      print(string.format("\t >>> >>> [node %i] - INSERT REQUEST (init:%i k:%s v:%s) | Ack: %s ",myID,init_node,key,value,ack))
      return ack
    end
  end,

  consulta = function(query_id, init_node, key)
    print(string.format("\t >>> >>> [node %i] - RECEIVED QUERY REQUEST: queryID:%i init:%i k:%s\t",myID, query_id,init_node,key))
    local destID = my_node.calc_hash(key)
    if destID == myID then
      local value
      repeat
        value = my_node.getValue(key)
        if value == nil then
          print(string.format("\t >>> >>> [node %i] - QUERYID %i WAITING FOR VALUE TO BE INSERTED",myID, query_id))
          luarpc.wait(my_node.getRandomWait())
        end
      until value ~= nil
      local log = string.format("\t Consulta %i enviada ao nó %i: valor para '%s' armazenado no nó %i: '%s'",query_id, init_node, key, destID, value)
      print(string.format("\t >>> >>> [node %i]",myID) .. log .. "\n")
      return log
    else
      local nextID = my_node.findNext(destID)
      local proxy = proxies[nextID]
      local ack = proxy.consulta(query_id,init_node,key)
      print(string.format("\t >>> >>> [node %i] - QUERY REQUEST (init:%i k:%s) | Ack: %s ",myID,init_node,key,ack))
      return ack
    end
  end
}

luarpc.createServant(myobj, "interface.lua", my_port)
luarpc.waitIncoming()
