
local luarpc = require("luarpc")
local sckt = require("socket")

local arq_interface = arg[1]
local requestID = tonumber(arg[2])
local tipo = arg[3]
local myID = tonumber(arg[4])

local IP = "127.0.0.1"

local my_port = myID + 8000
local p1 = luarpc.createProxy(IP, my_port, arq_interface)

function send_request(requestID, tipo, no_inicial, key, val)
  local ack
  if tipo == "i" then
    ack = p1.insere(no_inicial, key, val)
  else
    ack = p1.consulta(requestID, no_inicial, key)
  end
  return ack
end

local key = nil
local val = nil
if requestID == 1 then
  -- n16=0 | n32=0
  key = "melhorArea"
  val = "SistDist"

elseif requestID == 2 then
  -- n16=3 | n32=19
  key = "melhorUni"
  val = "PucRio"

elseif requestID == 3 then
  -- n16=4 | n32=20
  key = "melhorDept"
  val = "puc-INF"

elseif requestID == 4 then
  -- n16=6 | n32=22
  key = "melhorCompositor"
  val = "Chopin"

elseif requestID == 5 then
  -- n16=12 | n32=28
  key = "abcKeSs"
  val = "test5"

elseif requestID == 6 then
  -- n16=13 | n32=29
  key = "test123456789"
  val = "test6"

elseif requestID == 7 then
  -- n16=15 | n32=31
  key = "abcKeSsC"
  val = "test7"

elseif requestID == 8 then
  -- n16=4 | n32=20
  key = "abcKeSk"
  val = "test8"


else
  print("\tPlease select a valid test from 1 to 6. \n\tRun 'lua client.lua <interface file> <test requestID> <type> <init node>' \n\tOBS: <type> should be 'i' for 'Insere' and 'c' for 'Consulta'\n")
end

if (key ~= nil and val ~= nil) then
  local res = send_request(requestID, tipo, myID, key, val)
  while res == nil do
    print(string.format(" [RES %i %s]: ",requestID,tipo) .. "[___ERRORPC]: Unexpected error, probably because a coroutine was killed before sending back the ack of the request... attempting to process request again\n")
    res = send_request(requestID, tipo, myID, key, val)
  end
  print(string.format("[RES %i %s]: %s ",requestID,tipo,res))
end
