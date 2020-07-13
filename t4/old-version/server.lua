local luarpc = require("luarpc")
local node = require("node")
local state = require("states_enum")

local IP = "127.0.0.1"
local arq_interface = "interface.lua"

local my_port = tonumber(arg[1])
-- local n_nodes = tonumber(arg[2])
-- local seed = tonumber(arg[3])
-- local timeout = tonumber(arg[4])


-- Build table with IP / Port from all nodes
local addresses = {}

if my_port ~= 8003 then
  table.insert(addresses, {ip = IP, port = my_port+1})
else
  table.insert(addresses, {ip = IP, port = 8000})
end
-- for i=0,n_nodes-1 do
--   table.insert(addresses, {ip = IP, port = 8000+i})
-- end
-- for i=#addresses,1,-1 do
--   if addresses[i].port == my_port then
--     table.remove(addresses,i)
--   end
-- end

print("ADDRESSES:")
print("My port:",my_port,"\n")
for i,j in pairs(addresses) do
  print("Other's:",j.port)
end

-- Remove node's self IP and Port from table
local my_node = node.newNode(my_port - 8000, #addresses+1, seed)
-- my_node.printNode()

local proxies = {}
for _,address in pairs(addresses) do
  print("Creating Proxy at:", address, address.ip, address.port) -- [DEBUG]
  table.insert(proxies, luarpc.createProxy(address.ip, address.port, arq_interface))
end
local myID = my_node.getID()

-- Stub's methods list
local myobj = {

  insere = function(init_node, key, value)
    print(string.format("\n >>> [SRV%i] - RECEIVED INSERT REQUEST\t",myID),init_node,key,value,"\n")
    if init_node == my_node.getID() then -- TODO: Use hash function
      my_node.insertData(key,value)
      return string.format("[200] Inseriu par <%s : %s> no node %i",key,value,init_node)
    else
      for i=#proxies,1,-1 do
        local proxy = proxies[i]
        local ack = proxy.insere(init_node,key,value)
        return ack
      end
    end
  end,

  consulta = function(query_id, init_node, key)
    print(string.format("\n >>> [SRV%i] - RECEIVED QUERY #%i REQUEST\t",myID, query_id),init_node,key,"\n")
    if init_node == my_node.getID() then -- TODO: Use hash function
      local value
      repeat
        value = my_node.getValue(key)
        if value == nil then
          print(string.format("\n >>> [SRV%i] - RECEIVED QUERY %i WAITING FOR VALUE TO BE INSERTED",myID, query_id),"\n")
          luarpc.wait(my_node.getRandomWait())
        end
      until value ~= nil

      print(string.format("\n >>> [SRV%i] - RETURN QUERY #%i RESULT = ",myID, query_id),value,"\n")
      return string.format("[200] Consulta %i enviada ao nó %i: valor para '%s' armazenado no nó %i: '%s'",query_id, init_node, key, init_node, value)
    else
      for i=#proxies,1,-1 do
        local proxy = proxies[i]
        local ack = proxy.consulta(query_id,init_node,key)
        print(string.format("\n >>> [SRV%i] - RETURN QUERY #%i RESULT = ",myID, query_id),ack,"\n")
        return ack
      end
    end
  end
}

luarpc.createServant(myobj, "interface.lua", my_port)
luarpc.waitIncoming()
