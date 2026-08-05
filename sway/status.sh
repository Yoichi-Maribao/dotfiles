#!/bin/sh
# swaybar 用ステータス表示。
# config に直書きすると sway が引用符を落として sh の構文エラーになるため
# 別ファイルにしている。
while true; do
  date '+%Y-%m-%d (%a) %H:%M'
  sleep 10
done
