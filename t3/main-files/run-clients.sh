#!/bin/bash

if (( $1 == 3 )); then
  lua client.lua interface.lua 8000 &
  lua client.lua interface.lua 8001 &
  lua client.lua interface.lua 8002 &
fi

if (( $1 == 5 )); then
  lua client.lua interface.lua 8000 &
  lua client.lua interface.lua 8001 &
  lua client.lua interface.lua 8002 &
  lua client.lua interface.lua 8003 &
  lua client.lua interface.lua 8004 &
fi
