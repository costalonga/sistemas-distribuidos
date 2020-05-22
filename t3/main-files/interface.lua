struct = {
  name = "minhaStruct",
  fields = {
    {name = "nome", type = "string"},
    {name = "peso", type = "double"},
    {name = "idade", type = "int"}
  }
}
--
-- interface = {
--   methods = {
--     foo = {
--       resulttype = "double",
--       args = {
--         {direction = "in", type = "double"},
--         {direction = "in", type = "string"},
--         {direction = "in", type = "minhaStruct"},
--         {direction = "inout", type = "int"}
--       }
--     },
--     boo = {
--       resulttype = "void",
--       args = {
--         {direction = "inout", type = "double"},
--       }
--     }
--   }
-- }

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
   complex_foo = {
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
   boo2 = {
     resulttype = "void",
     args = {
       {direction = "inout", type = "double"},
     }
   },
   dummy = {
     resulttype = "double",
     args = {
       {direction = "in", type = "double"},
     }
   },
   dummy2 = {
     resulttype = "double",
     args = {
       {direction = "in", type = "double"},
     }
   },
   easy = {
     resulttype = "string",
     args = {
       {direction = "in", type = "string"},
     }
   }
   -- easy = {
   --   resulttype = "string",
   --   args = {
   --     {direction = "in", type = "string"},
   --     {direction = "in", type = "string"},
   --     {direction = "in", type = "int"},
   --   }
   -- }
 }
}
