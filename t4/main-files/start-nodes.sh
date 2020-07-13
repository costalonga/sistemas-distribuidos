#!/bin/bash

if [[ $1 == 2 || $1 == 4 || $1 == 16 || $1 == 32 ]]; then
  for i in $(seq $1)
  do
    tmp_port=$(($i + 8000-1))
    # echo $tmp_port
    lua server.lua $tmp_port $1 &
  done
fi
