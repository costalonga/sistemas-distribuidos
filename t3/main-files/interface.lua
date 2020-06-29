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
    requestVotes = {
      resulttype = "boolean",
      args = {
        {direction = "inout", type = "int"},
        {direction = "in", type = "int"}
      }
    },
    appendEntries = {
      resulttype = "boolean",
      args = {
        {direction = "inout", type = "int"},
        {direction = "in", type = "int"}
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
