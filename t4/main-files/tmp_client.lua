
local luarpc = require("luarpc")
local sckt = require("socket")

local arq_interface = arg[1]
local my_port = tonumber(arg[2])
local tipo = arg[3]

local IP = "127.0.0.1"

local p1 = luarpc.createProxy(IP, my_port, arq_interface)
local myID = my_port - 8000

-- local r, s = p1.insere(1, "k1", "v1")
-- print("\n RES p1.execute = ",r, s, "\n")

if tipo == "i" then
  local r, s = p1.insere(myID, "melhorUni", "PUC-Rio")
  print("\n RES p1.insere = ",r, s, "\n")
end

if tipo == "c" then
  local r, s = p1.consulta(1, myID, "melhorUni")
  print("\n RES p1.consulta = ",r,s, "\n")
end


-- local r, s = p1.consulta(1, 1, "k1")
-- print("\n RES p1.execute = ",r, s, "\n")
-- local r, s = p1.consulta(2, 3, "k3")
-- print("\n RES p1.execute = ",r, s, "\n")


-- local r, s = p1.insere(2, "k2", "v2")
-- print("\n RES p1.execute = ",r, s, "\n")
-- local r, s = p1.consulta(3, 2, "k2")
-- print("\n RES p1.execute = ",r, s, "\n")



-- local r, s = p1.consulta(3, 2, "k2")
-- print("\n RES p1.execute = ",r, s, "\n")
