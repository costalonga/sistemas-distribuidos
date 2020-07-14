#!/bin/bash

if [[ $1 == 2 || $1 == 4 || $1 == 16 || $1 == 32 ]]; then
  for i in $(seq $1)
  do
    tmp_port=$(($i + 8000-1))
    if [[ ${2:-n} == "v" ]]; then
      lua server.lua $tmp_port $1 v &
    else
      lua server.lua $tmp_port $1 &
    fi
  done
fi
