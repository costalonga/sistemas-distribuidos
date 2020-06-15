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
      resulttype = "double",
      args = {
        {direction = "in", type = "string"},
        {direction = "in", type = "string"},
        {direction = "in", type = "string"},
        {direction = "inout", type = "int"}
      }
    },
    appendEntries = {
      resulttype = "void",
      args = {
        {direction = "in", type = "string"},
        {direction = "in", type = "string"},
        {direction = "in", type = "string"},
        {direction = "inout", type = "int"}
      }
    },
    execute = {
      resulttype = "void",
      args = {
        {direction = "in", type = "addresses"}
      }
    }
  }
}
