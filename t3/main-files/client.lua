local luarpc = require("luarpc")
local sckt = require("socket")

local arq_interface = arg[1]
local my_port = tonumber(arg[2])
local IP = "127.0.0.1"

local addresses = {
  {ip = IP, port = porta1},
  {ip = IP, port = porta2},
  {ip = IP, port = porta3},
  {ip = IP, port = porta4}
  -- TODO: should have port0 also ???
}

local p1 = luarpc.createProxy(IP, my_port, arq_interface)
local r, s = p1.execute({ip = IP, port = my_port})
print("\n RES p1.execute = ",r, s, "\n")
