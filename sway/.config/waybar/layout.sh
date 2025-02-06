#!/bin/sh
# Get the active layout name using swaymsg and jq
active_layout=$(swaymsg -t get_inputs | jq -r 'map(select(has("xkb_active_layout_name")))[0].xkb_active_layout_name')

# Print the JSON output with the active layout name
printf '{"text":"%s"}\n' "$active_layout"

