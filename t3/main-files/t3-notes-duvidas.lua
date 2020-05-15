lua: attempt to yield from outside a coroutine
stack traceback:
	[C]: in function 'coroutine.yield'
	./luarpc.lua:155: in field 'dummy'
	./luarpc.lua:61: in upvalue 'fake_call'
	./luarpc.lua:195: in function 'luarpc.waitIncoming'
	server.lua:32: in main chunk
	[C]: in ?

--------------------------------------------------------------------------------

function luarpc.createProxy(host, port, interface_path)
  local proxy_stub = {}
  dofile(interface_path)
  for fname, fmethod in pairs(interface.methods) do
    proxy_stub[fname] = function(self, ...)
      params = {...}

      -- validation(params) XXX
      proxy_stub.conn = luarpc.create_client_stub_conn(host, port)
      local curr_co = coroutine.running()
      print("\tCO RUNNING:", curr_co, "\n")
      coroutines_by_socket[proxy_stub.conn] = curr_co -- registra na tabela
      table.insert(sockets_lst, proxy_stub.conn) -- insert at socket_lst

      -- marshalling(msg) XXX
      local msg = fname.."\n10\n-fim-\n"
      proxy_stub.conn:send(msg) -- envia peiddo RPC

      local r1, r2 = coroutine.yield() -- NOTE: FAILED HERE (but shouldnt it be curr_co) ??
      print("\t >> r1 , r2:", r1, r2, "\n")
