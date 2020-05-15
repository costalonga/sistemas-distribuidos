local luarpc = require("luarpc")
local sckt = require("socket")

local porta1 = tonumber(arg[1])
local porta2 = tonumber(arg[2])
local arq_interface = arg[3]

local REQUEST_NUM = 2500
local IP = "127.0.0.1"

-- QUESTION: need a new createProxy method?
-- local p1 = luarpc.createProxy(IP, porta1, arq_interface)
local p1 = luarpc.createProxy_for_client(IP, porta1, arq_interface)

local r = p1:dummy(10)
print("RES p1.f1(3) = ",r)
