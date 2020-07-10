#!/bin/bash

lua client.lua interface.lua 8000 &
lua client.lua interface.lua 8001 &
lua client.lua interface.lua 8002 &
lua client.lua interface.lua 8003 &

# if (( $1 == 16 )); then
#   lua client.lua interface.lua 8000 &
#   lua client.lua interface.lua 8001 &
#   lua client.lua interface.lua 8002 &
# fi
#
# if (( $1 == 32 )); then
#   lua client.lua interface.lua 8000 &
#   lua client.lua interface.lua 8001 &
#   lua client.lua interface.lua 8002 &
#   lua client.lua interface.lua 8003 &
#   lua client.lua interface.lua 8004 &
# fi
