#!/usr/bin/env bash

hyprctl binds -j | jq -c -f hyprland_keybinds.jq
