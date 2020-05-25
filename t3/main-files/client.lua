local luarpc = require("luarpc")
local sckt = require("socket")

local porta1 = tonumber(arg[1])
local porta2 = tonumber(arg[2])
local arq_interface = arg[3]

local REQUEST_NUM = 2500
local IP = "127.0.0.1"


local p1 = luarpc.createProxy(IP, porta1, arq_interface)

local p2 = luarpc.createProxy(IP, porta2, arq_interface)

-- print("\n[INSIDE CLIENT.lua] gonna call p2.boo(5)")
-- local r = p2.boo(5)
-- print("\n[INSIDE CLIENT.lua] RESULT of p2.boo(5) = ",r)

-- 1 server
local r, s = p1.foo(3, "alo", {nome = "ana", idade = 20, peso = 57.0}, 2)
print("\n RES foo1-p1",r, s, "\n")
--
-- -- local r, s = p1.foo(10, "alo", {nome = "ana", idade = 20, peso = 57.0}, 2)
-- -- print("foo1-p1",r, s)

-- 2 servers
local r = p1.dummy(10)
print("\n RES p1.dummy(10) = ",r, "\n")

local r, s = p1.complex_foo(3, "alo", {nome = "ana", idade = 20, peso = 57.0}, 2)
print("\n RES complex-foo-p1",r, s, "\n")

-- -- 3 servers
local r = p1.dummy2(10)
print("p1.dummy2(10,10,10) = ",r)
