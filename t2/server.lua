local luarpc = require("luarpc")

--local myobj1 = {
--  foo = function (a, s, st, n) return a*2, string.len(s) + st.idade + n end,
--  boo = function (n) return n end
--}
--local myobj2 = {
--  foo = function (a, s, st, n) return 0.0, 1 end,
--  boo = function (n) return 1 end
--}

local myobj1 = {
  foo = function (a, s, st, n) return a*2, string.len(s) + st.idade + n end,
  boo = function (n) return n end,
  dummy = function (s1,s2,s3) return s1*s2*s3 end,
  easy = function (s1,s2,s3) return s1..s2.. tostring(s3) end
}

local myobj2 = {
  foo = function (a, s, st, n) return a*2, string.len(s) + st.idade + n end,
  boo = function (n) return n end,
  dummy = function (s1,s2,s3) return s1+s2+s3 end,
  easy = function (s1,s2,s3) return s1..s2.. tostring(s3) end
}


luarpc.createServant(myobj1, "interface.lua", 8000)
luarpc.createServant(myobj2, "interface.lua", 8001)
luarpc.waitIncoming()
