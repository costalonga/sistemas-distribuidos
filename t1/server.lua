-- Author: Marcelo Costalonga

local string_to_download = "RBMYORLSUTLFZSBQZVEKZEFLPYEEYKBNUEAIKESMVGVSGBEIBSZBODDUQKKOVMKVVAEDPLDCASXACEERAIOPXISEEUVGBHNTEDVBMUHXZSSBDQEAAPOZDXYTDKDXOMVFODOZNUYSNKWQOEERBTPDPSVVDTYMVRAZSXXMBLKZYRWLNEISRUTQUTGAMUKBQLPBFSNEGHJCQKYLDPKFKQCAMLHYEUHPHEUHIHHCEJQDQPQOXGTQACMKPRNHPAIJFOHXUBCVZOZAVAKHFXBEBLTRXJGOPIXRMXLGFCHXRTEQVDNEEWVKWMKNATPEIWJEDQXPBFEQIRBOKEIPVDNLSBEFBNQTCBAJKFWUHYPAUTTJLPBBMLQBGHQRZBWLEJAFMZEXFBVFOLVCLPUOEGJZORFREYNLXLDADPPYVWPCKBCUKFTGLRVGLVGJNGQCXBKJRGARVVIWMFGCSZTDMRGCEWXFXOFZSXCTNMFMCCMLXBRRNLSSDQVYKDMRCSABDUISWABWNSMOWLYZRIOAHJVUVQKSZNIBXUPRFRAKXVGTMRUOKMPYAXCRMJUJBIRWKYNXOFUWKEHGGUSWCYLOBZZSAKZHOBDEKCMWCZVAQITICKYUICKUVQTXIOOXEJTAIMIQJVWPTOYNHECNZGEXSGKKSUGADIMBPYEUCBWVZSYWCYPTMHASPAVUOWDBZPTZQNIXJSCMPWHRMQUQVATCKTVKHJFEMAHRZGYOJNOLVQMNBZCLLBDLVCWSMATDONBKYHPMIBREHMDFMITWCBURPDIEDVSQABPDZOASMGHKMRKZUFFBQOVIAKMOVKBCMKIAMPESZLCURUOHPERXYHSIYALFVVNEJAVSRJGUUAWQRLZWWCTRVFLCZHQOTTFTRDTESFGEAEZYVGHPZVFZFEXYMCTUHBOLKFBGTIJRHCILQDWQPOKLTJLCWHAFCOUHVBNWZPQZXVYCBPGEYHXYLAWRNDMWFVGSMAKYNDZLHIMHDKYMGEGS"

-- load namespace
local socket = require("socket")
print("LuaSocket version: " .. socket._VERSION)

-- create a TCP socket and bind it to the local host, at any port
local server = socket.try(socket.bind("*", 0))
--server:setoption("reuseaddr", true)

-- find out which port the OS chose for us
local ip, port = server:getsockname()
-- print a message informing what's up
print("PORT " .. port)

local version = tonumber(arg[1])
local requests_num = tonumber(arg[2])
--local requests_num = 1000
print("N_REQUESTS " .. requests_num)

-- Version 1: close connection after each request
if version == 1 then
  print("Server V1")
  while 1 do
    local i=0
    while i < requests_num do
      -- wait for a connection from any client
      local client = server:accept()
      if not client then
        print("ERROR NIL CLIENT")
      end
      -- receive the line
      local line, err = client:receive()
      -- if there was no error, and client requested string, send it back to the client
      if not err then
        client:send(string_to_download .. "\n")
--        print("\tRequest-"..i)
      else
        print(err, "ERROR")
        client:close() 
        os.exit()
      end
      -- done with request, close the connection
      i = i + 1
      client:close() 
    end
    print("Received " .. i .. "requests! Server V1: done with client")
  end

-- Version 2: Maintaing connection open
elseif version == 2 then
  while 1 do
    -- wait for a connection from any client
    local client = server:accept()

    local i = 0
    while i < requests_num do
      -- receive the line
      local line, err = client:receive()

      -- if there was no error, and client requested string, send it back to the client
      if not err then
        client:send(string_to_download .. "\n")
--        print("\tRequest-"..i)
      else
        print(err, "ERROR")
        client:close() 
        os.exit()
      end
      i = i + 1
    end
    print("Received " .. i .. "requests! Server V2: done with client")
    -- done with client, close the connection
    client:close()
  end
end
