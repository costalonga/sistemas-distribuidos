-- Author: Marcelo Costalonga

local expected_string = "RBMYORLSUTLFZSBQZVEKZEFLPYEEYKBNUEAIKESMVGVSGBEIBSZBODDUQKKOVMKVVAEDPLDCASXACEERAIOPXISEEUVGBHNTEDVBMUHXZSSBDQEAAPOZDXYTDKDXOMVFODOZNUYSNKWQOEERBTPDPSVVDTYMVRAZSXXMBLKZYRWLNEISRUTQUTGAMUKBQLPBFSNEGHJCQKYLDPKFKQCAMLHYEUHPHEUHIHHCEJQDQPQOXGTQACMKPRNHPAIJFOHXUBCVZOZAVAKHFXBEBLTRXJGOPIXRMXLGFCHXRTEQVDNEEWVKWMKNATPEIWJEDQXPBFEQIRBOKEIPVDNLSBEFBNQTCBAJKFWUHYPAUTTJLPBBMLQBGHQRZBWLEJAFMZEXFBVFOLVCLPUOEGJZORFREYNLXLDADPPYVWPCKBCUKFTGLRVGLVGJNGQCXBKJRGARVVIWMFGCSZTDMRGCEWXFXOFZSXCTNMFMCCMLXBRRNLSSDQVYKDMRCSABDUISWABWNSMOWLYZRIOAHJVUVQKSZNIBXUPRFRAKXVGTMRUOKMPYAXCRMJUJBIRWKYNXOFUWKEHGGUSWCYLOBZZSAKZHOBDEKCMWCZVAQITICKYUICKUVQTXIOOXEJTAIMIQJVWPTOYNHECNZGEXSGKKSUGADIMBPYEUCBWVZSYWCYPTMHASPAVUOWDBZPTZQNIXJSCMPWHRMQUQVATCKTVKHJFEMAHRZGYOJNOLVQMNBZCLLBDLVCWSMATDONBKYHPMIBREHMDFMITWCBURPDIEDVSQABPDZOASMGHKMRKZUFFBQOVIAKMOVKBCMKIAMPESZLCURUOHPERXYHSIYALFVVNEJAVSRJGUUAWQRLZWWCTRVFLCZHQOTTFTRDTESFGEAEZYVGHPZVFZFEXYMCTUHBOLKFBGTIJRHCILQDWQPOKLTJLCWHAFCOUHVBNWZPQZXVYCBPGEYHXYLAWRNDMWFVGSMAKYNDZLHIMHDKYMGEGS"

local version = tonumber(arg[1])
local requests_num = tonumber(arg[2])

print("Starting test: V" .. version)
print("\tNumber of requests to send: " .. requests_num)

local host, port = "127.0.0.1", arg[3]
local socket = require("socket")
print("\tLuaSocket version: " .. socket._VERSION)

local i = 0
if version == 1 then
  local start = socket.gettime()  -- start time (right before client connect with server for the first time)
  
  while i < requests_num do
    local client = assert(socket.tcp())
    client:connect(host, port);
    client:send("download!\n"); -- need \n at the end
    
    local data, status = client:receive()
    if data then
      -- Obs: nunca deixe chamadas de entrada e saída dentro do trecho de código que vc está medindo
--      print(data, string.len(data)) 
      if not (data == expected_string) then
        print("ERROR did not receive full string")
        os.exit()
      end
      if not (string.len(data) == 1000) then
        print("ERROR did not receive full string")
        os.exit()
      end
      i = i + 1
    else
        print(status)
        if status == "closed" then break end
    end
    client:close()
  end
  local finish = socket.gettime() -- end time (connection ended for the last time)
  print("\t" .. requests_num .. " requests completed! Client's V1 done.")
  print("\tTotal time: " .. finish-start)

elseif version == 2 then
  local start = socket.gettime()  -- start time (right before client connect with server)
  local client = assert(socket.tcp())
  client:connect(host, port);

  while i < requests_num do
      client:send("download!\n"); -- need \n at the end
      local data, status = client:receive()
      if data then
        -- Obs: nunca deixe chamadas de entrada e saída dentro do trecho de código que vc está medindo
--        print(data, string.len(data))
        if not (data == expected_string) then
          print("ERROR did not receive full string")
          os.exit()
        end
        if not (string.len(data) == 1000) then
          print("ERROR did not receive full string")
          os.exit()
        end
        i = i + 1
      else
        print(status)
        if status == "closed" then break end
      end
  end

  client:close()
  local finish = socket.gettime() -- end time (right after connection ended)
  print("\t" .. requests_num .. " requests completed! Client's V2 done.")
  print("\tTotal time: " .. finish-start)
end
