-- Author: Marcelo Costalonga
-- WITH CONECTION POOL
local socket = require("socket")
local validator = require("validation")
local marshall = require("marshalling")
print("LuaSocket version: " .. socket._VERSION)

local luarpc = {}
------------------------------------------------------------------------------------------------- Main Functions
-- Main Data Structures
local servants_lst = {} -- Table/Dict with -> servers_sockets.obj and servers_sockets.interface
local sockets_lst = {} -- Array with all sockets
local clients_lst = {} -- Table/Dict for clients
-- clients_lst = {
--    client_socket = {
--        request = { func_name, arg1, agr2 ... }
--        servant = servant_socket
--    }
-- }

local MAX_POOL_SIZE = 4 -- Change number of how many clients a servant can handle simultaneously

-------------------------------------------------------------------------------- Main Functions
function luarpc.createServant(obj, interface_path, port)
  local server = socket.try(socket.bind("*", port))
  print("Server is running on port: " .. port)
  table.insert(sockets_lst, server) -- insert at socket_lst
  servants_lst[server] = {}
  servants_lst[server]["obj"] = obj
  servants_lst[server]["interface"] = interface_path

  -- [V2]
  servants_lst[server]["pool_queue"] = {}
end


function luarpc.createProxy(host, port, interface_path)
  local proxy_stub = {}
  dofile(interface_path)
  proxy_stub["conn"] = nil
  for fname, fmethod in pairs(interface.methods) do
    proxy_stub[fname] = function(self, ...)
      params = {...}

      local isValid, params, reasons = validator.validate_client(params,fname,fmethod.args)
      if not isValid and #reasons > 0 then
        return "[ERROR]: Invalid request. Reason: \n" .. reasons
      end

      if proxy_stub.conn == nil then -- creates a connection if its the first request from this client
        proxy_stub.conn = luarpc.create_client_stub_conn(host, port)
      end

      local msg = marshall.marshalling(params)
      msg = fname .. "\n" .. msg -- add method's name followed by parameteers (according to the protocol)
      local ack,err
      local returns = {}

      proxy_stub.conn:send(msg)
      ack,err = proxy_stub.conn:receive()
      if err then
        if err == "closed" then -- check if connection is still closed
          -- local wait_time = 0.05 -- TODO HERE
          -- local retries = 0
          -- local min = 10
          repeat
            proxy_stub.conn:close()

            -- socket.sleep(0.05) -- TODO HERE
            -- if (retries > min) then
            --   print("WAIT ", 0.05 + wait_time)
            --   socket.sleep(wait_time) -- TODO HERE
            --   wait_time = wait_time + retries/10000
            --   min = min + min
            -- else
            --   print("WAIT 0.05")
            -- end

            -- local info_log = " > Connection was closed due to connection pool's size."
            -- info_log = info_log .. " Reconnecting and sending request."
            -- print(info_log)
            proxy_stub.conn = luarpc.create_client_stub_conn(host, port)
            proxy_stub.conn:send(msg)
            ack,err = proxy_stub.conn:receive()
            if ack ~= nil and ack ~= "-fim-" then
              table.insert(returns,ack)
            else
              print("[ERROR] Unexpected... cause:", err)
            end
            -- retries = 1 + retries -- TODO HERE
          until err ~= "closed" and ack ~= nil
        else
          print("[ERROR] Unexpected... cause:", err)
        end

      elseif ack ~= nil and ack ~= "-fim-" then
        table.insert(returns,ack)
      end

      repeat
        ack,err = proxy_stub.conn:receive()
        if err then
          print("[ERROR] Unexpected... cause:", err)
          break
        end
        if ack ~= nil and ack ~= "-fim-" then
          table.insert(returns,ack)
          -- print("\n\t\tMESSAGE INFO [PROXY]:",ack,err,"\n")
        end
      until ack == "-fim-"
      local res = marshall.unmarshalling(returns, interface_path)
      return table.unpack(res)
    end --end of function
  end -- end of for
  return proxy_stub
end


function luarpc.update_pool_queue(servant, client)
  table.insert(servants_lst[servant]["pool_queue"], client)
  local pool_size = #servants_lst[servant]["pool_queue"]
  if pool_size > MAX_POOL_SIZE then
    -- print("CONNECTION EXCEED!! CLOSING CLIENTS TO MAKE ROOM FOR CLIENT: ", client)
    -- print("Pool size = ", pool_size)
    local diff = pool_size - MAX_POOL_SIZE
    for i=1,diff do
      local oldest_client = table.remove(servants_lst[servant]["pool_queue"], 1) -- pop index 1
      -- oldest_client:close() -- NOTE: WAY WORSE
      oldest_client:shutdown() -- NOTE: SO MUCH IMPROVMENT (BUT WHY?)
      -- print(string.format("\t >>> Client %s closed!", oldest_client))
    end
    -- print("\n")
  end
end


local function deal_with_request(client)
  local msg,err
  repeat
    msg,err = client:receive()
    if err then
      if err == "closed" then
        -- print("\t >>> Connection closed! Removing client... ", client)
        luarpc.remove_socket(client,"c")
      else
        print("[ERROR] Unexpected error occurred at waitIncoming... cause:", err)
        luarpc.remove_socket(client,"c")
      end
      break
    end

    if msg then
      if msg == "-fim-" then
        -- print(" End of message:",clients_lst[client]["request"], "\n")
        -- luarpc.print_tables(clients_lst[client]["request"]) -- [print] here
        -- print("\n")
        local result = luarpc.process_request(client)
        -- print(string.format("Result of request, for client %s :",client))
        -- print(result)
        clients_lst[client]["request"] = {} -- clear message queue to prepare for next request
        client:send(result)
      else
        table.insert(clients_lst[client]["request"], msg)
      end
    end
  until msg == "-fim-"
end


function luarpc.waitIncoming()
  print("Waiting for Incoming... [WITH POOL]")
  while true do
--    print("BACK TO BEGIN OF WHILE, socket list len:", #sockets_lst)
    local recvt, tmp, err = socket.select(sockets_lst)
    for _, socket in ipairs(recvt) do

      if luarpc.check_which_socket(socket, servants_lst) then -- servant
--        print("\n\tSERVER SOCKET CASE 1\n")
        local servant = socket
        local client = assert(servant:accept())
        -- client:settimeout(0.01)
        client:setoption("keepalive", true)
        clients_lst[client] = {}
        clients_lst[client]["request"] = {}
        clients_lst[client]["servant"] = servant
        table.insert(sockets_lst, client)
        luarpc.update_pool_queue(servant, client)
        deal_with_request(client)

      else                                                    -- client
       -- print("\n\t\t\tCLIENT SOCKET CASE 2\n")
        local client = socket
        deal_with_request(client) -- does socket:receive() and send results to client
      end
    end
  end
end

-------------------------------------------------------------------------------- MARSHALLING/UNMARSHALLING
function luarpc.process_request(client)
  local request_msg = clients_lst[client]["request"]
  local func_name = table.remove(request_msg, 1) -- pop index 1
  -- print("\t >> FNAME :",func_name) -- [print] here
  local servant = clients_lst[client]["servant"]
  local params = marshall.unmarshalling(request_msg, servants_lst[servant]["interface"])
  -- print(luarpc.print_tables(params))  -- [print] here

  local result = table.pack(servants_lst[servant]["obj"][func_name](table.unpack(params)))
  return marshall.marshalling(result)
end


-------------------------------------------------------------------------------- Auxiliary Functions

function luarpc.create_client_stub_conn(host, port)
  local conn = socket.connect(host, port)
  conn:setoption("tcp-nodelay", true)
  -- conn:settimeout(2)
  conn:setoption("keepalive", true)
  conn:setoption("reuseaddr", true)
  return conn
end

function luarpc.remove_socket(sckt, case)
  local status = false
  local client_server = nil
  if case == "c" then -- client
    for i,_ in pairs(clients_lst) do
      if i == sckt then
        client_server = clients_lst[i]["servant"]
        clients_lst[i] = nil -- deleting key from table
        status = true
        break
      end
    end
  elseif case == "s" then -- servant
    for i,_ in pairs(servants_lst) do
      if i == sckt then
        servants_lst[i] = nil -- deleting key from table
        status = true
        break
      end
    end
  end
  if status then
    for i=#sockets_lst,1,-1 do -- iterating backwards to avoid errors
      if sockets_lst[i] == sckt then
        table.remove(sockets_lst,i)
        break
      end
    end

    -- [V2]
    if case == 'c' and client_server ~= nil then
      for i=#servants_lst[client_server]["pool_queue"],1,-1 do -- iterating backwards to avoid errors
        if servants_lst[client_server]["pool_queue"][i] == sckt then
          table.remove(servants_lst[client_server]["pool_queue"],i)
          break
        end
      end
    end
  else
    print("[ERROR] COULD NOT REMOVE SOCKET FROM sockets_lst and/or other list")
  end
end

function luarpc.check_which_socket(sckt, lst)
  for i,_ in pairs(lst) do
--    print("Socket selected: ", skct
    if sckt == i then
      return true
    end
  end
  return false
end

function luarpc.print_tables(obj)
  print("\t >> PARAMS:")
  if type(obj) == "table" then
    for i,k in pairs(obj) do
      if type(k) == "table" then
        for v,j in pairs(k) do
          print("\t >> ",v,"=",j)
        end
      else
        print("\t >> ",k)
      end
    end
  else
    print(obj)
  end
  print("\n")
end

-------------------------------------------------------------------------------- Return RPC
return luarpc
