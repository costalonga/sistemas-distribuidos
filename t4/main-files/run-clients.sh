#!/bin/bash

if [[ $1 == 16 ]]; then
  lua client.lua interface.lua 2 c 7 &
  lua client.lua interface.lua 1 i 1 &
  lua client.lua interface.lua 8 i 6 & # nó 6 -> 4 insere
  lua client.lua interface.lua 5 i 7 &
  lua client.lua interface.lua 2 i 5 &
  lua client.lua interface.lua 1 c 2 &
  lua client.lua interface.lua 8 c 8 &

elif [[ $1 == 32 ]]; then
  lua client.lua interface.lua 2 i 3 &
  lua client.lua interface.lua 2 c 26 &
  lua client.lua interface.lua 1 i 1 &
  lua client.lua interface.lua 8 i 23 & # nó 23 -> 20 insere
  lua client.lua interface.lua 5 i 29 &
  lua client.lua interface.lua 5 c 7 &
  lua client.lua interface.lua 1 c 2 &
  lua client.lua interface.lua 8 c 25 &
fi
