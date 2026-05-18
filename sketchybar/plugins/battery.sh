#!/bin/sh
PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ -n "$CHARGING" ]; then
  ICON="􀢋"
else
  if [ "$PERCENTAGE" -gt 80 ]; then
    ICON="􀛨"
  elif [ "$PERCENTAGE" -gt 60 ]; then
    ICON="􀺸"
  elif [ "$PERCENTAGE" -gt 40 ]; then
    ICON="􀺶"
  elif [ "$PERCENTAGE" -gt 20 ]; then
    ICON="􀛩"
  else
    ICON="􀛪"
  fi
fi

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
