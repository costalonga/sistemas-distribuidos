local luarpc = require("luarpc")
local sckt = require("socket")

local porta1 = tonumber(arg[1])
local porta2 = tonumber(arg[2])
local arq_interface = arg[3]

local REQUEST_NUM = 2500
local IP = "127.0.0.1"

local p1 = luarpc.createProxy(IP, porta1, arq_interface)
local p2 = luarpc.createProxy(IP, porta2, arq_interface)

local t = p1:boo(61)
print("boo1-p1",t)
if t ~= 61.0 then print("[ERROR] boo1-p1 FAILED!") end


-- local start = socket.gettime() -- start time (right after connection ended)
-- for i=1,REQUEST_NUM do
--   -- local p1 = luarpc.createProxy(IP, porta1, arq_interface)
--   local r, s = p1:foo(3, "alo", {nome = "ana", idade = 20, peso = 57.0}, 2)
--   -- print("foo1-p1",r, s)
--   if r ~= 6.0 or s ~= 25 then print("[ERROR] foo1-p1 FAILED!") end
--
--   local r, s = p2:foo(4.5, "alo", {nome = "joao", idade = 5, peso = 15.0}, 0)
--   -- print("foo1-p2",r, s)
--   if r ~= 9.0 or s ~= 8 then print("[ERROR] foo1-p2 FAILED!") end
--   -- sckt.sleep(0.03) -- here
--
--   local t = p1:boo(61)
--   -- print("boo1-p1",t)
--   if t ~= 61.0 then print("[ERROR] boo1-p1 FAILED!") end
--
--   local t = p2:boo(62)
--   -- print("boo1-p2",t)
--   if t ~= 62.0 then print("[ERROR] boo1-p2 FAILED!") end
--   -- sckt.sleep(0.03) -- here
--
-- end
-- local finish = socket.gettime() -- end time (right after connection ended)
-- print("\tTotal time: " .. finish-start)
