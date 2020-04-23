-- Author: Marcelo Costalonga

local socket = require("socket")
print("LuaSocket version: " .. socket._VERSION)

local luarpc = {}
local servants_lst = {} -- Table {server: server_obj}
local clients_lst = {}
local sockets_lst = {} -- all sockets

------------------------------------------------------------------------------------------------- Main Functions
function luarpc.createServant(obj, interface_path, port)
  local idl = {}
  local server = socket.try(socket.bind("*", port))
--    local ip, port = server:getsockname() Redundant
  print("Server is running on port: " .. port)
  
  table.insert(servants_lst, server)
  table.insert(sockets_lst, server)
  servants_lst[server] = obj
    
end


function luarpc.marshall_msg(func_name, params)
  local msg = func_name .. "\n" 
  for i=1,#params do
    if type(params[i]) == "table" then
      msg = msg .. "{ "
      for k,v in pairs(params[i]) do
        print("\n\n\t\t\t LEN:",#params[i], "\n\n")
--        msg = msg .. k .. " = "  -- TODO: CHECK WITH NOEMI [problemas em usar loadstring quando é uma table de chave = valor] [problemas anyway... nao consigo converter string para tabela com load ou loadstring ou outros metodos
        if type(v) == "string" then 
          msg = msg .. '"' .. v .. '"'
        else 
          msg = msg .. tostring(v) 
        end
        msg = msg .. ", "
      end
      if string.sub(msg,#msg-1,#msg) == ", " then
        msg = string.sub(msg,1,#msg-2) .. " }\n"
      end
    elseif type(params[i]) == "string" then
      msg = msg .. '"' .. params[i] .. '"' .. "\n"
    else
      msg = msg .. tostring(params[i]) .. "\n"
    end
  end
  msg = msg .. "-fim-\n" -- end of request
  return msg
end

--luarpc.unmarshalling_msg(msg) 
--  local obj = {}
  
  
  
--end


function luarpc.createProxy(host, port, interface_path)
  local proxy_stub = {}
--  proxy_stub
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
    

    local msg = luarpc.marshall_msg(fname, params)
    print("\n\t\tGONNA SEND [PROXY]: ",msg)
--    proxy_stub.conn:send("SENDING FROM CLIENT: "..fname.."\n"..fname.."_2ndarg\n")
--    self.conn:send("SENDING FROM CLIENT: "..fname.."\n"..fname.."_2ndarg\n")
    
    self.conn:send(msg)
    local s,m = self.conn:receive()
    print("\n\t\tMESSAGE INFO [PROXY]:",s,m,"\n")
    
    proxy_stub.conn:close()
      
    end --end of function
  end
--  proxy_stub.conn = socket.connect(host, port)
--  proxy_stub.conn:setoption("tcp-nodelay", true)
--  proxy_stub.conn:settimeout(2)
--  proxy_stub.conn:setoption("keepalive", true)
  
  return proxy_stub
end


function luarpc.check_which_socket(sckt, lst)
  for i=1,#lst do 
--    print("Socket selected: ", skct
    if sckt == lst[i] then
      return true
    end
  end
  return false
end

function luarpc.remove_socket(sckt, case)
--  TODO CHECK WITH NOEMI if there's no better way
  local status = false
  if case == "c" then -- client 
    for i=#clients_lst,1,-1 do
      if clients_lst[i] == sckt then
        table.remove(clients_lst,i)
        status = true
        break
      end
    end
  elseif case == "s" then -- servant
    for i=#servants_lst,1,-1 do
      if servants_lst[i] == sckt then
        table.remove(servants_lst,i)
        status = true
        break
      end
    end
  end
  
  if status then
    for i=#sockets_lst,1,-1 do
      if sockets_lst[i] == sckt then
        table.remove(sockets_lst,i)
        break
      end
    end
  else
    print("[ERROR] COULD NOT REMOVE SOCKET FROM sockets_lst and/or other list")
  end
end

function luarpc.waitIncoming()
  
--  luarpc.print_tables(servants_lst) -- TODO REMOVE
  
  print("Waiting for Incoming...")
  while true do
    print("BACK TO BEGIN OF WHILE, socket list len:", #sockets_lst)
    local recvt, tmp, err = socket.select(sockets_lst)
    for _, socket in ipairs(recvt) do
      
      if luarpc.check_which_socket(socket, servants_lst) then -- servant
        print("\n\tSERVER SOCKET CASE\n")
        local servant = socket
        local client = assert(servant:accept())
        print("\n\t\t\tCONNECTION ACCEPTED")
        client:settimeout(0.01)
        client:setoption("keepalive", true)
        table.insert(clients_lst, client)
        table.insert(sockets_lst, client)
      
      else                                                    -- client
        print("\n\tCLIENT SOCKET CASE\n")
        local client = socket
        local msg,err = client:receive()
        
        if err then
          print("AN ERROR OCCURRED AT waitIncoming:client:receive",err)
          luarpc.remove_socket(client,"c")
          break
        end
        
        if msg then
--          luarpc.unmarshalling_msg(msg)
          print("\n\t\tMESSAGE INFO [WAIT]:",msg, err, "\n")

        end
      
        
        if msg == "-fim-" then
          client:send("OK\n")
          client:close()
          luarpc.remove_socket(client,"c")
        end
      end
    end
  end
end

------------------------------------------------------------------------------------------------- Auxiliary Functions
function luarpc.validate_server_obj(obj, interface_path)
  return true
--  TODO: Fix function to validate it
end

function luarpc.validate_client()
  return true, "ola"
end 

function luarpc.marshling_params() -- Packing parameters into a message
  print("pass")
end

function luarpc.unmarshling_params() -- Unpacking parameters from a message
  print("pass")
end

function luarpc.print_tables(obj)
  print("\n\n\t",type(obj))
  if type(obj) == "table" then
    for i,k in pairs(obj) do
      print("\tType I:",type(i),"\n\t\t",i)
      print("\tType K:",type(k),"\n\t\t",k,"\n")
    end
  else 
    print(obj)
  end
  print("\n")
end

------------------------------------------------------------------------------------------------- Return RPC
return luarpc