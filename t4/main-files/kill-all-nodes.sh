#!/bin/bash

if [[ $1 == 2 || $1 == 4 || $1 == 16 || $1 == 32 ]]; then
  for i in $(seq $1)
  do
    tmp_port=$(($i + 8000-1))
    # setting default value for $2 as 'n' just to not use kill -9 as default
    if [ ${2:-n} == "f" ]; then
      printf "\t > Attempting to kill -9 PID %s on port %s \n" "$(lsof -t -i:$tmp_port -sTCP:LISTEN)" "$tmp_port"
      kill -9 $(lsof -t -i:$tmp_port -sTCP:LISTEN)
    else
      printf "\t > Attempting to kill PID %s on port %s \n" "$(lsof -t -i:$tmp_port -sTCP:LISTEN)" "$tmp_port"
      kill $(lsof -t -i:$tmp_port -sTCP:LISTEN)
    fi
  done
  printf "\n\t If processes are still alive, re-run script passing 'f' as the second argument to force kill (kill -9) \n"
  printf "\t Result of command: ps -aux | grep server.lua | wc -l (should be 1). \n\t\t Result = %s  \n" "$(ps -aux | grep server.lua | wc -l)"
fi
