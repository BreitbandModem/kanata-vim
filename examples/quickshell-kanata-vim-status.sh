#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  exit 1
fi

port="$1"

emit() {
  local text="$1"
  local tooltip="$2"
  local klass="$3"

  jq -cn \
    --arg text "$text" \
    --arg tooltip "$tooltip" \
    --arg class "$klass" \
    '{text:$text, tooltip:$tooltip, class:$class}'
}

while :; do
  if exec 3<>"/dev/tcp/localhost/$port"; then
    while IFS= read -r line <&3; do
      layer=$(jq -r '.LayerChange.new // empty' <<<"$line" 2>/dev/null || true)
      [[ -z "$layer" ]] && continue

      case "$layer" in
      insert*)
        emit "" "kanata is not in any vim layer" "insert"
        ;;
      vim-normal*)
        emit "NORMAL" "" "normal"
        ;;
      vim-visual-line*)
        emit "V-LINE" "" "visual-line"
        ;;
      vim-visual*)
        emit "VISUAL" "" "visual"
        ;;
      esac
    done

    exec 3<&-
    emit "" "kanata disconnected" "disconnected"
  else
    emit "" "kanata port $port unreachable" "disconnected"
    sleep 5
  fi
done
