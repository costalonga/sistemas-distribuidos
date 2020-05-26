local luarpc = require("luarpc")
local sckt = require("socket")

local porta1 = tonumber(arg[1])
local porta2 = tonumber(arg[2])
local arq_interface = arg[3]

local test = tonumber(arg[4])

local REQUEST_NUM = 2500
local IP = "127.0.0.1"


local p1 = luarpc.createProxy(IP, porta1, arq_interface)

local p2 = luarpc.createProxy(IP, porta2, arq_interface)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 1 server
if test == 0 then -- server makes simple call like in our first RPC version
  local r, s = p1.foo(3, "alo", {nome = "ana", idade = 20, peso = 57.0}, 2)
  print("\n RES p1.foo1 = ",r, s, "\n")

elseif test == 1 then -- server calls itself
  local r = p1.call_yourself(3, 7)
  print("\n RES p1.call_yourself(3,7) = 3x10 + 7x7 =",r,"\n")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 2 servers
elseif test == 2 then -- server 8000 makes RPC call to port 8001
  local r = p1.dummy(10)
  print("\n RES p1.dummy(10) = ",r, "\n")

  local r, s = p1.complex_foo(3, "alo", {nome = "ana", idade = 20, peso = 57.0}, 2)
  print("\n RES p1.complex_foo = ",r, s, "\n")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 3 servers
elseif test == 3 then -- server 8000 makes call to 8001 and 8001 makes call to 8002
  local r = p1.dummy2(10)
  print("\n RES p1.dummy2(10) = ",r)

else
  print("\n Please select a value between 0-3 to select the type of test you want to run")
end
