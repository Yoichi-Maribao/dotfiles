#!/bin/sh
BD="/Applications/BetterDisplay.app/Contents/MacOS/BetterDisplay"

if [ "$SENDER" = "volume_change" ]; then
  # macOSのvolume_changeイベント（内蔵スピーカー/イヤホン）
  VOLUME="$INFO"
else
  # 出力デバイスを確認
  OUTPUT="$(system_profiler SPAudioDataType 2>/dev/null | awk '/Default Output Device: Yes/{found=1} found && /Transport:/{print $2; exit}')"

  if [ "$OUTPUT" = "USB" ] || [ "$OUTPUT" = "DisplayPort" ] || [ "$OUTPUT" = "HDMI" ]; then
    # 外部モニター → BetterDisplay DDC
    RAW="$(perl -e 'alarm 3; exec @ARGV' "$BD" get -volume 2>/dev/null)"
    if [ -n "$RAW" ] && [ "$RAW" != "missing value" ]; then
      VOLUME="$(echo "$RAW" | awk '{printf "%d", $1 * 100}')"
    else
      VOLUME="-"
    fi
  else
    # 内蔵スピーカー/Bluetooth/イヤホン → macOS音量
    VOLUME="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
    [ -z "$VOLUME" ] || [ "$VOLUME" = "missing value" ] && VOLUME="-"
  fi
fi

if [ "$VOLUME" = "-" ]; then
  ICON="􀊣"
  sketchybar --set "$NAME" icon="$ICON" label="--"
else
  if [ "$VOLUME" -eq 0 ] 2>/dev/null; then
    ICON="􀊣"
  elif [ "$VOLUME" -lt 33 ] 2>/dev/null; then
    ICON="􀊥"
  elif [ "$VOLUME" -lt 66 ] 2>/dev/null; then
    ICON="􀊧"
  else
    ICON="􀊩"
  fi
  sketchybar --set "$NAME" icon="$ICON" label="${VOLUME}%"
fi
