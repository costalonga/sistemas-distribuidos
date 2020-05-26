local luarpc = require("luarpc")

local porta2 = 8002
local IP = "127.0.0.1"
local arq_interface = "interface.lua"

local myobj = {
  easy = function (s)
    print("\n\t     >>> [SVR3] RUNNING EASY = ", s, "\n")
    local msg = tostring(s) .. "_ack_from_server3"
    return msg
  end
}

luarpc.createServant(myobj, "interface.lua", porta2)
luarpc.waitIncoming()
