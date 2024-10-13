#!/bin/bash

memory_data=$(free -h | grep Mem)

memory_used=$(echo "$memory_data" | awk '{ print $4 }')
available_memory=$(echo "$memory_data" | awk '{ print $2 }')

MEMORY_PERCENT=$(echo "scale=2; $memory_used / $available_memory * 100" | bc | awk '{printf "%.0f%%\n", $1}')

sketchybar --set $NAME label="$MEMORY_PERCENT"
