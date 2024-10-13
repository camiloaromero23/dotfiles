#!/bin/bash

CPU_PERCENT=$(top -R -F -n 0 -l 2 -s 0 | grep -E "^CPU" | tail -1 | awk '{ printf "%.0f%%", $3 + $5"" }')

sketchybar --set $NAME label="$CPU_PERCENT"
