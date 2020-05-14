# sistemas-distribuidos
## t1 - simple client &  server program 
- one client sending multiple requests to one server
- communication using simple TCP via lua sockets 
- Objective: compare the overhead cost caused by reopening connections vs letting the connection open 

## t2 - client & server program + RPC 
- server with multiple clients  
- communication using TCP + RPC protocol via lua sockets 
- Objective: compare servers using connection pool (to handle multiple clients simultaneously) vs server closing connection and opening connections for each request

## t3 - server's leader election program + RPC + lua coroutines
- multiple servers communicating to each other
- Objective: simulate an election alogorithm like RAFT 
- TODOs:
  - [ ] change t2 to let servers send and receive messages from each other and not just from clients
