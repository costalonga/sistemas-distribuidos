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
local clients_lst = {} -- Table/Dict for clients
-- clients_lst = {
--    client_socket = {
--        request = { func_name, arg1, agr2 ... }
--        servant = servant_socket
--    }
-- }

-- [TODO:T3]
local coroutines_by_socket = {} -- < socket:coroutine >

-------------------------------------------------------------------------------- Auxiliary Functions
local function deal_with_request(client)
  local msg,err
  repeat
    msg,err = client:receive()

    if err then
      print("[ERROR] Unexpected error occurred at waitIncoming > deal_with_request... cause:", err)
      break

    elseif msg then
      if msg == "-fim-" then
        local result = luarpc.process_request(client)
        clients_lst[client]["request"] = {} -- clear message queue to prepare for next request
        client:send(result)
        client:close()
      else
        table.insert(clients_lst[client]["request"], msg)
      end

    else
      print("[ERROR] NIL MESSAGE at waitIncoming > deal_with_request...:", msg, err)
    end

  until msg == "-fim-"
end

local function add_new_client(client, servant)
  client:setoption("keepalive", true)
  clients_lst[client] = {}
  clients_lst[client]["request"] = {}
  clients_lst[client]["servant"] = servant
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


-- NOTE: coroutine.running ()::Returns the running coroutine or nil if called in the main thread.
-- so the idea is...
  -- if nil -> is a client -> server case
  -- else  ->  is a server -> server case
-- didnt work... why??
    -- function luarpc.createProxy()
    --   local a,b = coroutine.running()
    --   print(a,b)
    -- end
-- log:
-- thread: 0x559be342a268	true

function luarpc.createProxy_for_client(host, port, interface_path)
  local proxy_stub = {}
  dofile(interface_path)
  for fname, fmethod in pairs(interface.methods) do

    proxy_stub[fname] = function(self, ...)
      params = {...}
			valida_params(params)

			-- abre nova conexao e envia request
      proxy_stub.conn = luarpc.create_client_stub_conn(host, port)
      local msg = marshall.create_protocol_msg(fname, params)
      proxy_stub.conn:send(msg)

			-- espera pela resposta do request
      local returns = {}
      repeat
        local ack,err = proxy_stub.conn:receive()
        table.insert(returns,ack)
      until ack == "-fim-"

      proxy_stub.conn:close() -- fecha conexao
      local res = marshall.unmarshalling(returns, interface_path) -- converte string para table com results
      return table.unpack(res) -- retorna results
    end --end of function
  end -- end of for
  return proxy_stub
end

function luarpc.createProxy_for_server(host, port, interface_path)
  local proxy_stub = {}
  dofile(interface_path)
  for fname, fmethod in pairs(interface.methods) do
    proxy_stub[fname] = function(self, ...)
      params = {...}

      -- valida_params(params) [TODO]

			-- abre nova conexao e envia request
			proxy_stub.conn = luarpc.create_client_stub_conn(host, port)

      local curr_co = coroutine.running() -- pega running coroutine
      coroutines_by_socket[proxy_stub.conn] = curr_co -- registra na tabela
      table.insert(sockets_lst, proxy_stub.conn) -- insere na tabela global

      local msg = marshall.create_protocol_msg(fname, params)
      proxy_stub.conn:send(msg) -- envia peiddo RPC

      local r1, r2 = coroutine.yield() -- faz yield
      coroutines_by_socket[proxy_stub.conn] = nil -- desregistra da tabela
			-- sockets_lst[proxy_stub.conn] = nil

      -- TODO HOW TO GET THE RETURN VALUE BACK ?????

			-- espera pela resposta do request
			local returns = {}
			repeat
				-- RECEIVE NAO PARECE FUNCIONAR
				-- TODO: Verificar se ha algum retorno usando um timeout(0)
				local ack,err = proxy_stub.conn:receive()
				table.insert(returns,ack)
			until ack == "-fim-"

			proxy_stub.conn:close() -- fecha conexao

			-- NAO CHEGA NESSE RETURN
			local res = marshall.unmarshalling(returns, interface_path) -- converte string para table com results
			return table.unpack(res) -- retorna results

			-- return 100

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

        -- Cria nova conexao
        local client = assert(servant:accept())
        add_new_client(client, servant)
        -- table.insert(sockets_lst, client)

        -- [TODO:T3]
        -- cria nova corrotina e invoca ela para fazer o receive
        local co = coroutine.create(
          function(client)

            local msg,err
            repeat
              msg,err = client:receive()
              if err then
                break
              elseif msg then
                if msg == "-fim-" then
                  local result = luarpc.process_request(client)
                  clients_lst[client]["request"] = {} -- clear message queue to prepare for next request
                  client:send(result) -- envia resultado para outra ponta do socket
                  client:close() -- fecha conexao
									-- remove from table ?
                else
                  table.insert(clients_lst[client]["request"], msg)
                end
              end
            until msg == "-fim-"
          end)

        coroutine.resume(co, client) -- invoca a corotina

      else                                                    -- client
        -- para cada cliente ativo... aplicar reumse() em corrotina indicada pela tabela global
        local co = coroutines_by_socket[sckt]

        if co ~= nil then
          coroutine.resume(co)
        -- else
          -- TODO NEED TO REMOVE sckt from select list in this case
        end

      end -- end if
    end -- end for
  end -- end while
end


-------------------------------------------------------------------------------- MARSHALLING/UNMARSHALLING
function luarpc.process_request(client)
  local request_msg = clients_lst[client]["request"]
  local func_name = table.remove(request_msg, 1) -- pop index 1
  local servant = clients_lst[client]["servant"]
  local params = marshall.unmarshalling(request_msg, servants_lst[servant]["interface"])

  -- invoke the method passed in the request with all it's parameters and get the result
  local result = table.pack(servants_lst[servant]["obj"][func_name](table.unpack(params)))

  return marshall.marshalling(result)
end

-------------------------------------------------------------------------------- Auxiliary Functions
function luarpc.create_client_stub_conn(host, port)
  local conn = socket.connect(host, port)
  conn:setoption("tcp-nodelay", true)
  -- conn:timeout(0) -- do not block
  conn:setoption("keepalive", true)
  conn:setoption("reuseaddr", true)
  return conn
end

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

-------------------------------------------------------------------------------- Return RPC
return luarpc
