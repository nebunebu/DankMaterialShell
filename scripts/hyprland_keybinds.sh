#!/usr/bin/env bash

hyprctl binds -j | jq -c -f hyprland_keybinds.jq

# # Json must be signle line
# cat <<EOF | jq -c .
# [
#   {
#     "key": "Super+Shift+Q",
#     "description": "Kill active window",
#     "category": "Window",
#     "subcategory": "Management"
#   },
#   {
#     "key": "Super+F",
#     "description": "Toggle fullscreen",
#     "category": "Window",
#     "subcategory": "Management"
#   },
#   {
#     "key": "Super+Left",
#     "description": "Move focus left",
#     "category": "Window",
#     "subcategory": "Layout"
#   },
#   {
#     "key": "Super+Right",
#     "description": "Move focus right",
#     "category": "Window",
#     "subcategory": "Layout"
#   },
#   {
#     "key": "Super+T",
#     "description": "exec kitty",
#     "category": "Execute",
#     "subcategory": "Launchers"
#   },
#   {
#     "key": "Super+E",
#     "description": "exec thunar",
#     "category": "Execute",
#     "subcategory": "Launchers"
#   },
#   {
#     "key": "Super+B",
#     "description": "exec firefox",
#     "category": "Execute",
#     "subcategory": "Launchers"
#   },
#   {
#     "key": "Super+1",
#     "description": "change to ws 1",
#     "category": "Workspace",
#     "subcategory": "Navigation"
#   },
#   {
#     "key": "Super+2",
#     "description": "change to ws 2",
#     "category": "Workspace",
#     "subcategory": "Navigation"
#   },
#   {
#     "key": "Super+3",
#     "description": "change to ws 3",
#     "category": "Workspace",
#     "subcategory": "Navigation"
#   },
#   {
#     "key": "Super+Shift+1",
#     "description": "move to ws 1",
#     "category": "Workspace",
#     "subcategory": "Navigation"
#   },
#   {
#     "key": "Super+M",
#     "description": "mon:DP-1",
#     "category": "Monitor",
#     "subcategory": "Management"
#   },
#   {
#     "key": "Alt_L+V",
#     "description": "exec wpctl set-volume ...",
#     "category": "System",
#     "subcategory": "Audio"
#   },
#   {
#     "key": "Alt_L+B",
#     "description": "exec brightnessctl set ...",
#     "category": "System",
#     "subcategory": "Brightness"
#   },
#   {
#     "key": "Alt_L+R",
#     "description": "exec hyprctl keyword ...",
#     "category": "System",
#     "subcategory": "Hyprland CLI"
#   },
#   {
#     "key": "Ctrl+Alt+Del",
#     "description": "exec systemctl poweroff",
#     "category": "System",
#     "subcategory": "Power"
#   },
#   {
#     "key": "Super+P",
#     "description": "dms ipc call powermenu toggle",
#     "category": "DMS",
#     "subcategory": "Modals"
#   },
#   {
#     "key": "Super+Space",
#     "description": "dms ipc call spotlight toggle",
#     "category": "DMS",
#     "subcategory": "Modals"
#   },
#   {
#     "key": "Ctrl+Shift+P",
#     "description": "exec screenshot.sh",
#     "category": "Execute",
#     "subcategory": "Utils"
#   },
#   {
#     "key": "Super+Alt+C",
#     "description": "exec code .",
#     "category": "Custom",
#     "subcategory": "Dev"
#   }
# ]
# EOF
