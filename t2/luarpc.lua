-- Author: Marcelo Costalonga

local socket = require("socket")
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

-------------------------------------------------------------------------------- Main Functions
function luarpc.createServant(obj, interface_path, port)
  local server = socket.try(socket.bind("*", port))
--    local ip, port = server:getsockname() Redundant
  print("Server is running on port: " .. port)

  table.insert(sockets_lst, server) -- insert at socket_lst
  servants_lst[server] = {}
  servants_lst[server]["obj"] = obj
  servants_lst[server]["interface"] = interface_path
end


function luarpc.createProxy(host, port, interface_path)
  local proxy_stub = {}
  dofile(interface_path)
--  TODO: Validate: obj
  for fname, fmethod in pairs(interface.methods) do
    proxy_stub[fname] = function(self, ...)
      params = {...} -- TODO usar do args[2] em diante args[1] é uma tab

--      local isValid, params = luarpc.validate_client() -- TODO implement
--      if isValid then
--        local msg = interface
--      end

    proxy_stub.conn = socket.connect(host, port)
    proxy_stub.conn:setoption("tcp-nodelay", true)
    proxy_stub.conn:settimeout(2)
    proxy_stub.conn:setoption("keepalive", true)
    proxy_stub.conn:setoption("reuseaddr", true)

    local msg = luarpc.marshalling(params)
    msg = fname .. "\n" .. msg
    -- print("\n\t\tGONNA SEND [PROXY]: ",msg)
    self.conn:send(msg)
    local ack,err
    local returns = {}
    repeat
      ack,err = self.conn:receive()
      if err then
        print("[ERROR]", err)
        break
      end
      if ack ~= nil and ack ~= "-fim-" then
        table.insert(returns,ack)
        -- print("\n\t\tMESSAGE INFO [PROXY]:",ack,err,"\n")
      end
    until ack == "-fim-"
    proxy_stub.conn:close()
    local res = luarpc.unmarshalling(returns, interface_path)
    return table.unpack(res)
    end --end of function
  end
--  proxy_stub.conn = socket.connect(host, port)
  return proxy_stub
end


function luarpc.waitIncoming()
  print("Waiting for Incoming...")
  while true do
--    print("BACK TO BEGIN OF WHILE, socket list len:", #sockets_lst)
    local recvt, tmp, err = socket.select(sockets_lst)
    for _, socket in ipairs(recvt) do

      if luarpc.check_which_socket(socket, servants_lst) then -- servant
--        print("\n\tSERVER SOCKET CASE\n")
        local servant = socket
        local client = assert(servant:accept())
--        print("\n\t\t\tCONNECTION ACCEPTED")
        client:settimeout(0.01)
        client:setoption("keepalive", true)

        clients_lst[client] = {}
        clients_lst[client]["request"] = {}
        clients_lst[client]["servant"] = servant
        table.insert(sockets_lst, client)

      else                                                    -- client
--        print("\n\t\t\tCLIENT SOCKET CASE\n")
        local client = socket
        local msg,err = client:receive()

        if err then
          print("AN ERROR OCCURRED AT waitIncoming:client:receive",err)
          luarpc.remove_socket(client,"c")
          break
        end

        if msg then
          if msg == "-fim-" then
            print("\n\t\tALL MSG:",clients_lst[client]["request"], err, "\n")
            luarpc.print_tables(clients_lst[client]["request"])
            print("\n")
            local result = luarpc.process_request(client)
            -- luarpc.process_request(client)
            print("\t\t >RES:",result)
            -- client:send("OK\n")
            client:send(result)
            client:close()
            luarpc.remove_socket(client,"c")
          else
            table.insert(clients_lst[client]["request"], msg)
          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------- MARSHALLING/UNMARSHALLING
function luarpc.process_request(client)
  local request_msg = clients_lst[client]["request"]
  local func_name = table.remove(request_msg, 1) -- pop index 1
  print("\t >> FNAME :",func_name)
  -- print("\t >> SERVER:",clients_lst[client]["servant"])
  local servant = clients_lst[client]["servant"]
  -- print("\t >> FUNC:",servants_lst[servant][func_name])
  local params = luarpc.unmarshalling(request_msg, servants_lst[servant]["interface"])
  print("\t >> NAME :",func_name)
  print(luarpc.print_tables(params))
  local result = table.pack(servants_lst[servant]["obj"][func_name](table.unpack(params)))
  print("\t >> RESULT:")
  -- print(table.unpack(result))
  return luarpc.marshalling(result)
end

function luarpc.unmarshalling(request_params, interface)
  -- print("\n\t UNMARSHALLING :")
  local params = {}
  for _,param in pairs(request_params) do
    value = luarpc.convert_param(param, interface)
    table.insert(params,value)
  end
  return params
end

function luarpc.convert_param(param, interface)
  local value
  local first_char = param:sub(1,1)
  local tmp_type = type(param)
  if first_char == "'" then --        string
    value = param:sub(2,#param-1)
    -- print("\t\t >>STRING",value)
  elseif first_char == "{" then --    table
    local str_struct = param:sub(2,#param-1)
    value = luarpc.tostruct(str_struct, interface)
    -- print("\t\t >>TABLE", value)
  else --                             number
    value = tonumber(param)
    if math.type(value) == "integer" then
      tmp_type = "int"
    else
      tmp_type = "double"
    end
    -- print("\t\t >>NUMBER", value, tmp_type)
  end
  return value, tmp_type
end

-- Recebe uma string do tipo "'Ana', 20, 50.0" e constroi uma tabela do tipo {nome='Ana', idade=20, peso=50.0} baseada na itnerface do servant stub
function luarpc.tostruct(str_struct, interface)
  local tab_struct = {}
  for param in str_struct:gmatch("([^, ]+)") do -- faz split por ", "
    dofile(interface)
    local value, tmp_type = luarpc.convert_param(param, interface)
    local field_name
    for i=1,#struct.fields do
      if struct.fields[i].type == tmp_type then
        field_name = struct.fields[i].name
        break
      end
    end
    tab_struct[field_name] = value
  end
  return tab_struct
end

function luarpc.marshalling(request_params_table)
  -- local msg = func_name .. "\n"
  local msg = ""
  for i=1,#request_params_table do
    if type(request_params_table[i]) == "table" then
      msg = msg .. "{"
      for k,v in pairs(request_params_table[i]) do
        if type(v) == "string" then
          msg = msg .. "'" .. v .. "'"
        else
          msg = msg .. tostring(v)
        end
        msg = msg .. ", "
      end
      if string.sub(msg,#msg-1,#msg) == ", " then
        msg = string.sub(msg,1,#msg-2) .. "}\n"
      end
    elseif type(request_params_table[i]) == "string" then
      msg = msg .. "'" .. request_params_table[i] .. "'" .. "\n"
    else
      msg = msg .. tostring(request_params_table[i]) .. "\n"
    end
  end
  msg = msg .. "-fim-\n" -- end of request
  return msg
end

-------------------------------------------------------------------------------- Auxiliary Functions
function luarpc.remove_socket(sckt, case)
  local status = false
  if case == "c" then -- client
    for i,_ in pairs(clients_lst) do
      if i == sckt then
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

function luarpc.validate_client()
  return true
end

-------------------------------------------------------------------------------------------------

function luarpc.marshling_params() -- Packing parameters into a message
  print("pass")
end

function luarpc.unmarshling_params() -- Unpacking parameters from a message
  print("pass")
end



-------------------------------------------------------------------------------- Return RPC
return luarpc
