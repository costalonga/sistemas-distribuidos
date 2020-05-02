local luarpc = require("luarpc")
local sckt = require("socket")

local porta1 = tonumber(arg[1])
local porta2 = tonumber(arg[2])

local arq_interface = arg[3]
--local arq_interface = "/home/Marcelo/Documents/puc-tmp/ZeroBraneStudio-1.80/projects-marcelo/t2/interface.lua"

local IP = "127.0.0.1"


local p1 = luarpc.createProxy(IP, porta1, arq_interface)
local p2 = luarpc.createProxy(IP, porta1, arq_interface)
local p3 = luarpc.createProxy(IP, porta1, arq_interface)
local p4 = luarpc.createProxy(IP, porta1, arq_interface)

local ez
local i = 1
while i < 5 do
  ez = p1:easy("p1", "req",i)
  print("p1-easy", ez)
  sckt.sleep(1)

  ez = p2:easy("p2", "req",i)
  print("p2-easy", ez)
  sckt.sleep(1)

  ez = p3:easy("p3", "req",i)
  print("p3-easy", ez)
  sckt.sleep(1)

  ez = p4:easy("p4", "req",i)
  print("p4-easy", ez)
  sckt.sleep(1)

  i = i + 1
end
