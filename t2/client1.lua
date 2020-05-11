-- local luarpc = require("luarpc")
-- local sckt = require("socket")
--
-- local porta1 = tonumber(arg[1])
-- local porta2 = tonumber(arg[2])
--
-- local arq_interface = arg[3]
-- --local arq_interface = "/home/Marcelo/Documents/puc-tmp/ZeroBraneStudio-1.80/projects-marcelo/t2/interface.lua"
--
-- local IP = "127.0.0.1"
--
-- --local p1 = luarpc.createProxy(IP, porta1, arq_interface)
-- --local p2 = luarpc.createProxy(IP, porta2, arq_interface)
-- --local r, s = p1:foo(3, "alo", {nome = "marcelo", idade = 20, peso = 50.0}, 2)
-- --print("foo",r, s)
-- --local t = p2:boo("10")
-- --print("boo",t)
--
-- local p1 = luarpc.createProxy(IP, porta1, arq_interface)
-- local p2 = luarpc.createProxy(IP, porta1, arq_interface)
-- local p3 = luarpc.createProxy(IP, porta1, arq_interface)
-- local p4 = luarpc.createProxy(IP, porta1, arq_interface)
--
-- local ez
-- local i = 1
-- while true do
--   ez = p1:easy("p1", "req",i)
--   print("p1-easy", ez)
--   sckt.sleep(1)
--
--   ez = p2:easy("p2", "req",i)
--   print("p2-easy", ez)
--   sckt.sleep(1)
--
--   ez = p3:easy("p3", "req",i)
--   print("p3-easy", ez)
--   sckt.sleep(1)
--
--   ez = p4:easy("p4", "req",i)
--   print("p4-easy", ez)
--   sckt.sleep(1)
--   i = i + 1
-- end
--
-- -- local t = p1:boo(10)
-- -- local p = p2:dummy(5, 7)
-- -- print("dummy",p)
-- -- local d = p1:dummy(1,2,3)
-- --
-- --
-- -- local r, s = p1:foo(3, "alo", {nome = "Aaa", idade = 20, peso = 50.0})
--
-- --print(t)
-- --print(p1)


local luarpc = require("luarpc")
local sckt = require("socket")

local porta1 = tonumber(arg[1])
local porta2 = tonumber(arg[2])

local arq_interface = arg[3]
--local arq_interface = "/home/Marcelo/Documents/puc-tmp/ZeroBraneStudio-1.80/projects-marcelo/t2/interface.lua"

local IP = "127.0.0.1"

-- sckt.sleep(2) -- here
local p1 = luarpc.createProxy(IP, porta1, arq_interface)
local p2 = luarpc.createProxy(IP, porta1, arq_interface)
local p3 = luarpc.createProxy(IP, porta1, arq_interface)

local r, s = p1:foo(3, "alo", {nome = "ana", idade = 20, peso = 50.0}, 2)
print("foo1",r, s)

local t = p1:boo(61)
print("boo1",t)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local r, s = p2:foo(3, "alo", {nome = "marina", idade = 5, peso = 50.0}, 0)
print("foo2",r, s)

local t = p2:boo(62)
print("boo2",t)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local r, s = p3:foo(3, "alo", {nome = "marcelo", idade = 20, peso = 50.0}, 7)
print("foo3",r, s)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- local t = p2:boo(62)
-- print("boo2",t)


-- sckt.sleep(6) -- here
sckt.sleep(2)


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
