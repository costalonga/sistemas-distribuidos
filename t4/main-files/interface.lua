struct = {
  name = "minhaStruct",
  fields = {
    {name = "nome", type = "string"},
    {name = "peso", type = "double"},
    {name = "idade", type = "int"}
  },

  name = "addresses",
  fields = {
    {name = "ip", type = "string"},
    {name = "port", type = "int"}
  }
}

interface = {
  methods = {
    insere = {
      resulttype = "boolean",
      args = {
        {direction = "in", type = "int"},
        {direction = "in", type = "string"},
        {direction = "in", type = "string"}
      }
    },
    consulta = {
      resulttype = "string",
      args = {
        {direction = "in", type = "int"},
        {direction = "in", type = "int"},
        {direction = "in", type = "string"}
        -- {direction = "out", type = "void"}
      }
    },
    execute = {
      resulttype = "void",
      args = {
        {direction = "out", type = "void"}
      }
    }
  }
}
