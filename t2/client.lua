local luarpc = require("luarpc")

local porta1 = tonumber(arg[1])
local porta2 = tonumber(arg[2])

--local arq_interface = arg[3] TODO FIX IT
local arq_interface = "/home/Marcelo/Documents/puc-tmp/ZeroBraneStudio-1.80/projects-marcelo/t2/interface.lua"

local IP = "127.0.0.1"

local p1 = luarpc.createProxy(IP, porta1, arq_interface)
local p2 = luarpc.createProxy(IP, porta2, arq_interface)
local r, s = p1:foo(3, "alo", {nome = "Aaa", idade = 20, peso = 50.0}, 2)
print("foo",r, s)
local t = p2:boo(10)
print("boo",t)

--local t = p1:boo(10)
local p = p2:dummy(5, 7, 8)
print("dummy",p)
--local d = p1:dummy(1,2,3)
local ez = p1:easy("hello", "world",3)
print("easy", ez)
-- print(ez)
--local r, s = p1:foo(3, "alo", {nome = "Aaa", idade = 20, peso = 50.0})

--print(t)
--print(p1)
