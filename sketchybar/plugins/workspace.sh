#!/bin/sh

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  FOCUSED="$FOCUSED_WORKSPACE"
else
  FOCUSED="$(aerospace list-workspaces --focused)"
fi

sketchybar --set "$NAME" label="$FOCUSED"
