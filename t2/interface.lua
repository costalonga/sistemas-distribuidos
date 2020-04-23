struct = { 
  name = "minhaStruct",
  fields = {
    {name = "nome", type = "string"},
    {name = "peso", type = "double"},
    {name = "idade", type = "int"}
  }
}

interface = {
  name = "minhaInt",
  methods = {
    foo = {
      resulttype = "double",
      args = {
        {direction = "in", type = "double"},
        {direction = "in", type = "string"},
        {direction = "in", type = "minhaStruct"},
        {direction = "inout", type = "int"}
      }
    },
    boo = {
      resulttype = "void",
      args = {
        {direction = "inout", type = "double"},
      }
    },
    dummy = {
      resulttype = "int",
      args = {
        {direction = "in", type = "int"},
        {direction = "in", type = "int"},
        {direction = "in", type = "int"}
      }
    },
    easy = {
      resulttype = "string",
      args = {
        {direction = "in", type = "string"},
        {direction = "in", type = "string"},
      }
    }
  }
}

--interface = {
--  methods = {
--    boo = {
--      resulttype = "void",
--      args = {
--        {direction = "inout", type = "double"},
--      }
--    },
--    dummy = {
--      resulttype = "void",
--      args = {
--        {direction = "in", type = "string"},
--      }
--    }
--  }
--}