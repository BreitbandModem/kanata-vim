#!/bin/bash
# Invoke with kanata port on arg1
lockfile="/tmp/waybar-kanata.lock"
exec 9>"$lockfile"

while :; do
  if exec 3<>/dev/tcp/localhost/$1; then
    while IFS= read -r line <&3; do
      flock 9

      layer=$(echo $line | jq .LayerChange.new | tr -d '"')
      printf '%s' "$layer" > /tmp/kanata-layer-$1

      # check for layer names with wildcard to account for the -override layers (e.g. vim-normal-override)
      case "$layer" in
      insert*)
        echo '{ "text": "", "tooltip": "kanata is not in any vim layer", "class": "" }'
        ;;
      vim-normal*)
        echo '{ "text": "NORMAL", "tooltip": "", "class": "normal" }'
        ;;
      vim-visual-line*)
        echo '{ "text": "V-LINE", "tooltip": "", "class": "visual-line" }'
        ;;
      vim-visual*)
        echo '{ "text": "VISUAL", "tooltip": "", "class": "visual" }'
        ;;
      esac

      flock -u 9
    done
    exec 3<&-
    printf 'disconnected' > /tmp/kanata-layer-$1
    # if keyboard disconnects - retry
  else
    sleep 5
  fi
done
