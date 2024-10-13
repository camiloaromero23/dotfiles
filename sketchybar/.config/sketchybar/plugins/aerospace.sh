#!/bin/bash

source "$CONFIG_DIR/colors.sh"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME label=$1 \
                           background.color=$Surface_0 \
                           label.color=$Mauve
else
    sketchybar --set $NAME label=$1 \
                           background.color=$Crust \
                           label.color=$Text
fi
