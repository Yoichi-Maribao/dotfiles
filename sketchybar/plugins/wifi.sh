#!/bin/sh
SSID="$(ipconfig getsummary en0 2>/dev/null | awk -F ' : ' '/SSID/{print $2}' | head -1)"

if [ -n "$SSID" ]; then
  ICON="􀙇"
else
  ICON="􀙈"
fi

sketchybar --set "$NAME" icon="$ICON" label.drawing=off
