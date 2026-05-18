#!/bin/sh
RESULT="$($CONFIG_DIR/helpers/zmk_battery 2>/dev/null)"

if echo "$RESULT" | grep -q "^error:"; then
  sketchybar --set "$NAME" label="--"
  exit 0
fi

CENTRAL="$(echo "$RESULT" | cut -d, -f1)"
PERIPHERAL="$(echo "$RESULT" | cut -d, -f2)"

LABEL="C:${CENTRAL}% P:${PERIPHERAL}%"
sketchybar --set "$NAME" label="$LABEL"
