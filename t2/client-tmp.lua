local luarpc = require("luarpc")
local sckt = require("socket")

local porta1 = tonumber(arg[1])
local porta2 = tonumber(arg[2])

local arq_interface = arg[3]
--local arq_interface = "/home/Marcelo/Documents/puc-tmp/ZeroBraneStudio-1.80/projects-marcelo/t2/interface.lua"

local IP = "127.0.0.1"

--local p1 = luarpc.createProxy(IP, porta1, arq_interface)
--local p2 = luarpc.createProxy(IP, porta2, arq_interface)
--local r, s = p1:foo(3, "alo", {nome = "marcelo", idade = 20, peso = 50.0}, 2)
--print("foo",r, s)
--local t = p2:boo("10")
--print("boo",t)


local p1 = luarpc.createProxy(IP, porta1, arq_interface)
local r, s = p1:foo(3, "alo", {nome = "2-ana", idade = 80, peso = 50.0}, 2)
print("2-foo1",r, s)
-- sckt.sleep(0.5)

local p2 = luarpc.createProxy(IP, porta1, arq_interface)
local r, s = p2:foo(3, "alo", {nome = "2-marina", idade = 5, peso = 50.0}, 0)
print("2-foo2",r, s)
-- sckt.sleep(0.5)
--
-- local p3 = luarpc.createProxy(IP, porta1, arq_interface)
-- local r, s = p3:foo(3, "alo", {nome = "2-marcelo", idade = 20, peso = 50.0}, 7)
-- print("2-foo3",r, s)
-- -- sckt.sleep(0.5)
--
-- local p4 = luarpc.createProxy(IP, porta1, arq_interface)
-- local r, s = p4:foo(3, "alo", {nome = "2-joao", idade = 47, peso = 50.0}, 7)
-- print("2-foo4",r, s)
sckt.sleep(1)


--local t = p1:boo(10)
--local p = p2:dummy(5, 7)
--print("dummy",p)
--local d = p1:dummy(1,2,3)
--local ez = p1:easy("hello", "world",3)
--print("easy", ez)
-- print(ez)
--local r, s = p1:foo(3, "alo", {nome = "Aaa", idade = 20, peso = 50.0})

--print(t)
--print(p1)
