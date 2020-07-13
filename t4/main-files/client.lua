
local luarpc = require("luarpc")
local sckt = require("socket")

local arq_interface = arg[1]
local case = tonumber(arg[2])
local tipo = arg[3]
local myID = tonumber(arg[4])

local IP = "127.0.0.1"

local my_port = myID + 8000
local p1 = luarpc.createProxy(IP, my_port, arq_interface)

function send_request(case, tipo, no_inicial, key, val)
  local ack
  if tipo == "i" then
    ack = p1.insere(no_inicial, key, val)
  else
    ack = p1.consulta(case, no_inicial, key)
  end
  return ack
end

local key = nil
local val = nil
if case == 1 then
  key = "melhorArea"
  val = "SistDist"

elseif case == 2 then
  key = "melhorUni"
  val = "PucRio"

elseif case == 3 then
  key = "melhorDept"
  val = "puc-INF"

elseif case == 4 then
  key = "melhorCompositor"
  val = "Chopin"

elseif case == 5 then
  key = "abcKey"
  val = "EfGhVal"

elseif case == 6 then
  key = "zzz-key"
  val = "zzz-Val"

else
  print("\tPlease select a valid test from 1 to 6. \n\tRun 'lua client.lua <interface file> <test case> <type> <init node>' \n\tOBS: <type> should be 'i' for 'Insere' and 'c' for 'Consulta'\n")
end

if (key ~= nil and val ~= nil) then
  local res = send_request(case, tipo, myID, key, val)
  while res == nil do
    print(string.format(" [RES %i %s]: ",case,tipo) .. "[___ERRORPC]: Unexpected error, probably because a coroutine was killed before sending back the ack of the request... attempting to process request again\n")
    res = send_request(case, tipo, myID, key, val)
  end
  print(string.format("[RES %i %s]: %s ",case,tipo,res))
end
