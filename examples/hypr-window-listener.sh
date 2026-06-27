#!/bin/bash

send_fake_key() {
  local port="$1"
  local payload="$2"

  if ! printf '%s\n' "$payload" | socat -u - "TCP:localhost:${port},connect-timeout=1" >/dev/null 2>&1; then
      printf '%s\n' "window-listener: kanata port ${port} unreachable" >&2
  fi
}

toggle_context_in_kanata() {
  local payload
  payload=$(printf '{"ActOnFakeKey": {"name": "%s", "action": "%s"}}' "$1" "$2")

  send_fake_key 10000 "$payload"
}

handle_focus_change() {
  # Disable the direct vim mode enter when a terminal window is active.
  if echo "$1" | grep -qi 'alacritty'; then
    toggle_context_in_kanata "vim-direct-enter" "Release"
  else
    toggle_context_in_kanata "vim-direct-enter" "Press"
  fi
}

# Listen to Hyprland's event socket
socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
  # Check if the event is a window focus change
  if [[ "$line" =~ ^activewindowv2\>\>[[:alnum:]]+ ]]; then
      # Extract the window data (comes after the '>>')
      window_address="${line#*>>}"
      window_data=$(
        hyprctl clients -j \
        | jq -r \
          --arg windowAddress $window_address  \
          '.[]
          | select(
            (.address | test($windowAddress;"i")))'
      )
      handle_focus_change "$window_data"
  fi
done
