#!/bin/bash

# lua client.lua interface.lua 1 c 3 &
# lua client.lua interface.lua 2 c 6 &
# lua client.lua interface.lua 1 i 0 &
# lua client.lua interface.lua 2 i 0 &

lua client.lua interface.lua 1 c 0 & # Faz consulta no nó 0 -> 0
lua client.lua interface.lua 2 c 2 & # Faz consulta no nó 2 -> 3
# lua client.lua interface.lua 2 c 0 & # Faz consulta no nó 0 -> 3
lua client.lua interface.lua 1 i 3 & # Insere no nó 3 -> 0
lua client.lua interface.lua 2 i 0 & # Insere no nó 0 -> 3

# NOTE: Sempre que uma ou mais consulta fica pendente corrotina  

# if [[ $1 <= 6 ]]; then
#   for i in $(seq $1)
#   do
#     tmp_port=$(($i + 8000-1))
#     lua client.lua interface.lua  $tmp_port $1 &
#     # setting default value for $2 as 'n' just to not use kill -9 as default
#     if [ ${2:-n} == "f" ]; then
#       printf "\t > Attempting to kill -9 PID %s on port %s \n" "$(lsof -t -i:$tmp_port -sTCP:LISTEN)" "$tmp_port"
#       kill -9 $(lsof -t -i:$tmp_port -sTCP:LISTEN)
#     else
#       printf "\t > Attempting to kill PID %s on port %s \n" "$(lsof -t -i:$tmp_port -sTCP:LISTEN)" "$tmp_port"
#       kill $(lsof -t -i:$tmp_port -sTCP:LISTEN)
#     fi
#   done
#   printf "\n\t If processes are still alive, re-run script passing 'f' as the second argument to force kill (kill -9) \n"
#   printf "\t Result of command: ps -aux | grep server.lua | wc -l (should be 1). \n\t\t Result = %s  \n" "$(ps -aux | grep server.lua | wc -l)"
# fi
