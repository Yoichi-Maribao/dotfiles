#!/bin/bash
# tmux status-left helper: dirname | repo | branch

pane_path=$(tmux display-message -p -t "${TMUX_PANE}" '#{pane_current_path}' 2>/dev/null)
if [ -z "$pane_path" ]; then
  pane_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
fi
if [ -z "$pane_path" ]; then
  echo " ~ "
  exit 0
fi

# Nerd Font icons (macOS default bash lacks \u support, use python3)
GITHUB_ICON=$(python3 -c "print('\uf09b', end='')")
BRANCH_ICON=$(python3 -c "print('\ue0a0', end='')")

# Directory name
dirname=$(basename "$pane_path")

# Git info
cd "$pane_path" 2>/dev/null || exit 0

branch=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --exact-match 2>/dev/null)

if [ -n "$branch" ]; then
  # Repository name from remote or top-level dir
  repo=$(git remote get-url origin 2>/dev/null | sed 's/.*[:/]\([^/]*\)\.git$/\1/' | sed 's/.*[:/]\([^/]*\)$/\1/')
  if [ -z "$repo" ]; then
    repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
  fi
  echo " ${dirname} #[fg=white]|#[fg=magenta] ${GITHUB_ICON} ${repo} #[fg=white]|#[fg=green] ${BRANCH_ICON} ${branch} "
else
  echo " ${dirname} "
fi
