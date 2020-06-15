local luarpc = require("luarpc")
local sckt = require("socket")

local porta0 = 8000
local porta1 = 8001
local porta2 = 8002

local arq_interface = arg[1]
local test = tonumber(arg[2])

local IP = "127.0.0.1"


local addresses_lst = {
  {ip = IP, port = porta1},
  {ip = IP, port = porta2}
  -- TODO: should have port0 also ???
}

local p1 = luarpc.createProxy(IP, porta0, arq_interface)

-- local p2 = luarpc.createProxy(IP, porta1, arq_interface)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 1 server
if test == 0 then -- server makes simple call like in our first RPC version
  local r, s = p1.execute({ip = IP, port = porta0})
  print("\n RES p1.execute = ",r, s, "\n")

elseif test == 1 then -- server calls itself
  -- local r = p1.call_yourself(3, 7)
  -- print("\n RES p1.call_yourself(3,7) = 3x10 + 7x7 =",r,"\n")
  print("pass")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 2 servers
elseif test == 2 then -- server 8000 makes RPC call to port 8001
  -- local r = p1.dummy(10,10,10)
  -- print("\n RES p1.dummy(10) = ",r, "\n")
  --
  -- local r, s = p1.complex_foo(3, "alo", {nome = "ana", idade = 20, peso = 57.0}, 2)
  -- print("\n RES p1.complex_foo = ",r, s, "\n")
  print("pass")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 3 servers
elseif test == 3 then -- server 8000 makes call to 8001 and 8001 makes call to 8002
  -- local r = p1.dummy2(10)
  -- print("\n RES p1.dummy2(10) = ",r)
  print("pass")

else
  print("\n Please select a value between 0-3 to select the type of test you want to run")
end
