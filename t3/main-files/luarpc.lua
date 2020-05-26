-- Author: Marcelo Costalonga
-- RPC + COROUTINES
-- NOTE: good docs: https://www.lua.org/pil/9.4.html

local socket = require("socket")
local validator = require("validator")
local marshall = require("marshalling")
print("LuaSocket version: " .. socket._VERSION)

local luarpc = {}
-------------------------------------------------------------------------------- Main Data Structures
local servants_lst = {} -- Table/Dict with -> servers_sockets.obj and servers_sockets.interface
local sockets_lst = {} -- Array with all sockets
local coroutines_by_socket = {} -- < socket:coroutine >
-- local clients_lst = {} -- Not being used any more

-------------------------------------------------------------------------------- Auxiliary Functions
local function add_new_client(client, servant)
  client:setoption("keepalive", true)
  -- clients_lst[client] = {}
  -- clients_lst[client]["request"] = {}
  -- clients_lst[client]["servant"] = servant
  table.insert(sockets_lst, client) -- insert at sockets_lst
end

-------------------------------------------------------------------------------- Main Functions
function luarpc.createServant(obj, interface_path, port)
  local server = socket.try(socket.bind("*", port))
  print("Server is running on port: " .. port)
  table.insert(sockets_lst, server) -- insert at sockets_lst
  servants_lst[server] = {}
  servants_lst[server]["obj"] = obj
  servants_lst[server]["interface"] = interface_path
end

function luarpc.createProxy(host, port, interface_path)
  local proxy_stub = {}
  dofile(interface_path)
  for fname, fmethod in pairs(interface.methods) do
    proxy_stub[fname] = function(...)
      local params = {...}

      -- valida_params(params) [TODO]
      local msg = marshall.create_protocol_msg(fname, params)

      -- abre nova conexao e envia request
      if coroutine.isyieldable() then -- coroutine-client
        proxy_stub.conn = luarpc.create_client_stub_conn(host, port, true)
        -- print("\n\t     >>> [cli] createProxy CASE 1", "\n") -- [DEBUG]
        local curr_co = coroutine.running()
        print("\t     >>> CO RUNNING:", curr_co, "\n")

        coroutines_by_socket[proxy_stub.conn] = curr_co -- registra na tabela
        table.insert(sockets_lst, proxy_stub.conn) -- insere no array do select

        -- print("\n\n\t\t >>>>>> [CLT -> SVR] MSG TO BE SENT 1:",msg) -- [DEBUG]
        proxy_stub.conn:send(msg) -- envia peiddo RPC
        local r1, r2 = coroutine.yield() -- CREATE PROXY

      else
        -- print("\n\t     >>> [cli] createProxy CASE 2", "\n") -- [DEBUG]
        proxy_stub.conn = luarpc.create_client_stub_conn(host, port, false)
        -- print("\n\n\t\t >>>>>> [CLT -> SVR] MSG TO BE SENT 2:",msg) -- [DEBUG]
        proxy_stub.conn:send(msg) -- envia peiddo RPC
      end

      -- print("\n\t\t >>>>>> [cli] WAITING TO RECEIVE!!!") -- [DEBUG]
      coroutines_by_socket[proxy_stub.conn] = nil -- desregistra da tabela

      -- espera pela resposta do request
      local returns = {}
      repeat
        ack,err = proxy_stub.conn:receive() -- SERVER IS EXITING HERE
        -- print("[receive loop]: ack,err = ",ack,err) -- [DEBUG]
        if err then
          print("[ERROR] Unexpected... cause:", err)
          break
        end
        if ack ~= nil and ack ~= "-fim-" then
          table.insert(returns,ack)
        end
      until ack == "-fim-"

      proxy_stub.conn:close() -- fecha conexao

      local res = marshall.unmarshalling(returns, interface_path) -- converte string para table com results
      return table.unpack(res) -- retorna results

    end --end of function
  end -- end of for
  return proxy_stub
end

function luarpc.waitIncoming()

  print("Waiting for Incoming...")
  while true do
    local recvt, tmp, err = socket.select(sockets_lst)
    for _, sckt in ipairs(recvt) do

      if luarpc.check_which_socket(sckt, servants_lst) then -- servant
        local servant = sckt
        -- print(">>> [SVR] locked on ACCEPT !!!!!!!!\n") -- [DEBUG]

        -- Cria nova conexao
        local client = assert(servant:accept()) -- ponta do socket do server p/ client
        add_new_client(client, servant)
        client:setoption("tcp-nodelay", true)

        -- cria nova corrotina e a invoca para fazer o receive
        local co = coroutine.create(
          function(client, servant)
            local request_raw = {}
            local msg,err
            repeat
              -- print(">>> [SVR] locked on RECEIVE !!!!!!!!\n") -- [DEBUG]
              msg,err = client:receive()
              -- print("\t >>> >>> '[SVR] RECEIVED'",msg,err) -- [DEBUG]
              if err then
                print("[ERROR] Unexpected error occurred at waitIncoming... cause:", err)
                break
              end
              if msg then
                if msg == "-fim-" then
                  local result = luarpc.process_request(client, request_raw, servant)
                  client:send(result) -- SERVER envia resultado de volta para CLIENT
                  client:close() -- como server ja processou totalmente o request fecha essa ponta do socket
                else
                  table.insert(request_raw, msg)
                end
              end
            until msg == "-fim-"
          end)

        print("\t >>> '[SVR] CO RESUME 1'- START",coroutine.status(co),co,sckt)
        coroutine.resume(co, client, servant) -- inicia a corotina
        print("\t >>> '[SVR] CO RESUME 2'- STOP",coroutine.status(co),co,sckt)

      else                                                    -- client
        -- para cada cliente ativo... aplicar reumse() em corrotina indicada pela tabela global
        local co = coroutines_by_socket[sckt]
        if co ~= nil and coroutine.status(co) ~= "dead" then
          print("\t >>> '[CLT] CO RESUME 1'- START",coroutine.status(co),co,sckt)
          coroutine.resume(co)
          print("\t >>> '[CLT] CO RESUME 2'- STOP",coroutine.status(co),co,sckt)
        end
        if coroutine.status(co) == "dead" then
          luarpc.remove_socket(sckt) -- remove socket cliente do array do select()
        end
      end -- end if
    end -- end for
  end -- end while
end


-------------------------------------------------------------------------------- MARSHALLING/UNMARSHALLING
function luarpc.process_request(client, request_msg, servant)
  local func_name = table.remove(request_msg, 1) -- pop index 1
  local params = marshall.unmarshalling(request_msg, servants_lst[servant]["interface"])

  -- check if server's object has this method
  if servants_lst[servant]["obj"][func_name] == nil then
    local error_msg = string.format("___ERRORPC: Server attempt to call unkown method '%s'.\n",func_name)
    error_msg = error_msg .. "Check server.lua files to see if it's object contains this method"
    print(error_msg)
    return error_msg
  end

  -- invoke the method passed in the request with all its parameters and get the result
  local result = table.pack(servants_lst[servant]["obj"][func_name](table.unpack(params)))
  local msg_to_send = marshall.marshalling(result)
  -- print("\n\n\t\t >>>>>> [SVR -> CLT] MSG TO BE SENT FROM SERVER:",msg_to_send) -- [DEBUG]
  return msg_to_send
end

-------------------------------------------------------------------------------- Auxiliary Functions
function luarpc.create_client_stub_conn(host, port, timeout)
  local conn = socket.connect(host, port)
  conn:setoption("tcp-nodelay", true)
  if timeout ~= false then
    conn:settimeout(0) -- do not block  -- TODO TESTING
  end
  -- conn:setoption("keepalive", true)
  conn:setoption("reuseaddr", true)
  return conn
end

function luarpc.remove_socket(sckt)
  for i=#sockets_lst,1,-1 do -- iterating backwards to avoid errors
    if sockets_lst[i] == sckt then
      table.remove(sockets_lst,i)
      break
    end
  end
  -- local status = false
  -- elseif case == "s" then -- servant
  --   for i,_ in pairs(servants_lst) do
  --     if i == sckt then
  --       servants_lst[i] = nil -- deleting key from table
  --       status = true
  --       break
  --     end
  --   end
  -- end
end

function luarpc.check_which_socket(sckt, lst)
  for i,_ in pairs(lst) do
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
