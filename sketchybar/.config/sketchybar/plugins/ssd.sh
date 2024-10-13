#!/bin/bash

SSD_PERCENT=$(diskutil info / | awk '/Free/ { free = $4 } /Total/ { total = $4 } END { printf "%.0f%%\n", (100 - (free/total) * 100)"%"  }')

sketchybar --set $NAME label="$SSD_PERCENT"
