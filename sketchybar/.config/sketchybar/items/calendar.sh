#!/bin/bash

sketchybar --add item calendar right \
           --set calendar update_freq=1 script="$PLUGIN_DIR/calendar.sh" \
