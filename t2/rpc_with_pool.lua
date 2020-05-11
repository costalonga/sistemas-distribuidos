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

local MAX_POOL_SIZE = 1 -- Change number of how many clients a servant can handle simultaneously

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

      local swagger_struct = {} -- converting to math.types
      for i=1,#struct.fields do
        local tmp_type = struct.fields[i].type
        if tmp_type == "double" then
           tmp_type = "float"
        elseif tmp_type == "int" then
          tmp_type = "integer"
        end
        swagger_struct[struct.fields[i].name] = tmp_type
      end
      local isValid, params, reasons = luarpc.validate_client(params,fname,fmethod.args,swagger_struct)
      if not isValid and #reasons > 0 then
        return "[ERROR]: Invalid request. Reason: \n" .. reasons
      end

      if proxy_stub.conn == nil then -- creates a connection if its the first request from this client
        proxy_stub.conn = luarpc.create_client_stub_conn(host, port)
      end

      local msg = luarpc.marshalling(params)
      msg = fname .. "\n" .. msg -- add method's name followed by parameteers (according to the protocol)
      local ack,err
      local returns = {}

      proxy_stub.conn:send(msg)
      ack,err = proxy_stub.conn:receive()
      if err then
        if err == "closed" then -- check if connection is still closed
          repeat
            proxy_stub.conn:close()
            local info_log = " > Connection was closed due to connection pool's size."
            info_log = info_log .. " Reconnecting and sending request."
            print(info_log)
            proxy_stub.conn = luarpc.create_client_stub_conn(host, port)
            proxy_stub.conn:send(msg)
            ack,err = proxy_stub.conn:receive()
            if ack ~= nil and ack ~= "-fim-" then
              table.insert(returns,ack)
            else
              print("ELSE",ack, err)
            end
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
      local res = luarpc.unmarshalling(returns, interface_path)
      return table.unpack(res)
    end --end of function
  end -- end of for
  return proxy_stub
end


function luarpc.update_pool_queue(servant, client)
  table.insert(servants_lst[servant]["pool_queue"], client)
  local pool_size = #servants_lst[servant]["pool_queue"]
  if pool_size > MAX_POOL_SIZE then
    print("CONNECTION EXCEED!! CLOSING CLIENTS TO MAKE ROOM FOR CLIENT: ", client)
    print("Pool size = ", pool_size)
    local diff = pool_size - MAX_POOL_SIZE
    for i=1,diff do
      local oldest_client = table.remove(servants_lst[servant]["pool_queue"], 1) -- pop index 1
      oldest_client:close()
      print(string.format("\t >>> Client %s closed!", oldest_client))
    end
    print("\n")
  end
end


function luarpc.waitIncoming()
  print("Waiting for Incoming...")
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
        luarpc.deal_with_request(client)

      else                                                    -- client
       -- print("\n\t\t\tCLIENT SOCKET CASE 2\n")
        local client = socket
        luarpc.deal_with_request(client) -- does socket:receive() and send results to client
      end
    end
  end
end

-------------------------------------------------------------------------------- MARSHALLING/UNMARSHALLING
function luarpc.process_request(client)
  local request_msg = clients_lst[client]["request"]
  local func_name = table.remove(request_msg, 1) -- pop index 1
  print("\t >> FNAME :",func_name) -- [print] here
  local servant = clients_lst[client]["servant"]
  local params = luarpc.unmarshalling(request_msg, servants_lst[servant]["interface"])
  print(luarpc.print_tables(params))  -- [print] here

  local result = table.pack(servants_lst[servant]["obj"][func_name](table.unpack(params)))
  return luarpc.marshalling(result)
end

function luarpc.unmarshalling(request_params, interface)
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
    value = param:sub(2,#param-1) -- exclui '{' e '}' do primeiro e ultimo char da string
  elseif first_char == "{" then --    table
    local str_struct = param:sub(2,#param-1)
    value = luarpc.tostruct(str_struct, interface)
  else --                             number
    value = tonumber(param)
    if math.type(value) == "integer" then
      tmp_type = "int"
    else
      tmp_type = "double"
    end
  end
  return value, tmp_type
end

-- Recebe uma string do tipo "'Ana', 20, 50.0" e constroi uma tabela do tipo {nome='Ana', idade=20, peso=50.0} baseada na itnerface do servant stub
function luarpc.tostruct(str_struct, interface)
  local tab_struct = {}
  dofile(interface)
  for expression in str_struct:gmatch("([^, ]+)") do -- faz split por ", " e acha expressoes como: nome='Ana'

    local equal_sign = expression:find("=")
    local str_key = expression:sub(1, equal_sign-1)
    local str_value = expression:sub(equal_sign+1, #expression)

    local value, tmp_type = luarpc.convert_param(str_value, interface)
    local field_name
    for i=1,#struct.fields do
      if struct.fields[i].name == str_key then
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
        msg = msg .. k .. "="
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
function luarpc.deal_with_request(client)
  local msg,err
  repeat
    msg,err = client:receive()
    if err then
      if err == "closed" then
        print("\t >>> Connection closed! Removing client... ", client)
      else
        print("[ERROR] Unexpected error occurred at waitIncoming... cause:", err)
      end
      luarpc.remove_socket(client,"c")
      break
    end

    if msg then
      if msg == "-fim-" then
        -- print(" End of message:",clients_lst[client]["request"], "\n")
        -- luarpc.print_tables(clients_lst[client]["request"]) -- [print] here
        -- print("\n")
        local result = luarpc.process_request(client)
        print(string.format("Result of request, for client %s :",client))
        print(result)
        clients_lst[client]["request"] = {} -- clear message queue to prepare for next request
        client:send(result)
      else
        table.insert(clients_lst[client]["request"], msg)
      end
    end
  until msg == "-fim-"
end

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

function luarpc.validate_client(params,fname,iface_args,swagger_struct)
  local valid = true
  local inputs = {}
  local reasons = ""
  for i=1,#iface_args do
    local arg_direc = iface_args[i].direction
    if arg_direc == "in" or arg_direc == "inout" then
      local arg_type = iface_args[i].type
      table.insert(inputs,arg_type)
    end
  end
  if not (#params == #inputs) then
    local reason = string.format("Method '%s' should receive %i args, but only receive %i",fname,#inputs,#params)
    -- -- print("[ERROR] Invalid request! " .. reason)
    valid = false
    reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
  else
    for i=1,#inputs do
      if inputs[i] == "int" or inputs[i] == "double" then -- number case
        local inner_valid = true
        if type(params[i]) ~= "number" then
          local tmp = tonumber(params[i])
          if tmp == nil then
            local reason = string.format("#%i arg of method '%s' must be a valid number format and not %s",i,fname,type(params[i]))
            -- print("[ERROR] Invalid request! " .. reason)
            valid = false
            inner_valid = false
            reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
          else
            params[i] = tmp
          end
        end
        if inner_valid then
          if math.type(params[i]) == "integer" and inputs[i] == "double" then -- convert int to double
            params[i] = params[i] + .0
          elseif math.type(params[i]) == "float" and inputs[i] == "int" then -- convert double to int
            params[i] = math.floor(params[i])
          end
        end
      elseif inputs[i] == "string" then -- string case
        if type(params[i]) ~= "string" and type(params[i]) ~= "number" then
          local reason = string.format("#%i arg of method '%s' must be a valid string, can't convert %s to string...",i,fname,type(params[i]))
          -- print("[ERROR] Invalid request! " .. reason)
          valid = false
          reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
        else
          params[i] = tostring(params[i])
        end
      elseif inputs[i] == "minhaStruct" then -- table case
        local reason = ""
        if type(params[i]) ~= "table" then
          reason = string.format("#%i arg of method '%s' must be a table and not %s",i,fname,type(params[i]))
        else
          for k,_ in pairs(params[i]) do
            if k ~= "nome" and k ~= "peso" and k ~= "idade" then
              reason = reason .. string.format("\n\t  #%i arg of method '%s' contains invalid keys! minhaStruct table does not support '%s' key",i,fname,k)
            end
          end

          if type(params[i].nome) ~= swagger_struct.nome then
            reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'nome' of type string and not %s",i,fname,type(params[i].nome))
          end

          if tonumber(params[i].peso) == nil then
            reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'peso' of type double. Can't convert '%s' to number",i,fname,params[i].peso)
          else
            params[i].peso = tonumber(params[i].peso)
            if math.type(params[i].peso) ~= swagger_struct.peso then
              reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'peso' of type double and not %s",i,fname,type(params[i].peso))
            end
          end

          if tonumber(params[i].idade) == nil then
            reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'idade' of type int. Can't convert '%s' to number",i,fname,params[i].idade)
          else
            params[i].idade = tonumber(params[i].idade)
            if math.type(params[i].idade) ~= swagger_struct.idade then
              reason = reason .. string.format("\n\t  #%i arg of method '%s' must be a table with 'idade' of type int and not %s",i,fname,type(params[i].idade))
            end
          end
        end
        if #reason > 0 then
          -- print("[ERROR] Invalid request! " .. reason)
          valid = false
          reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
        end
      else -- invalid
        local reason = string.format("#%i arg of method '%s' has type %s not supported",i,fname,type(params[i]))
        -- print("[ERROR] Invalid request! " .. reason)
        valid = false
        reasons = reasons .. "___ERRORPC: " .. reason .. "\n"
      end
    end
  end
  return valid, params, reasons
end

-------------------------------------------------------------------------------- Return RPC
return luarpc
