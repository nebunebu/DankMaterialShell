map(
  {
    key: (
      [
        (if (.modmask / 64 | floor) % 2 == 1 then "Super" else empty end),
        (if (.modmask / 8  | floor) % 2 == 1 then "Alt"   else empty end),
        (if (.modmask / 4  | floor) % 2 == 1 then "Ctrl"  else empty end),
        (if (.modmask / 1  | floor) % 2 == 1 then "Shift" else empty end)
      ] +
      [ (.key | sub("^XF86"; "")) ]
    ) | join("+"),
    description: (
      if .has_description then .description
      elif .dispatcher == "exec" or .dispatcher == "execre" then "exec " + .arg
      elif .dispatcher == "global" then "global " + .arg
      elif .dispatcher == "workspace" then "change to ws " + .arg
      elif .dispatcher == "movetoworkspace" then "move to ws " + .arg
      elif .dispatcher == "killactive" then "kill active win"
      elif .dispatcher == "focusmonitor" then "mon:" + .arg
      elif .dispatcher == "fullscreen" then "Toggle fullscreen"
      else .dispatcher + " " + .arg
      end | sub(" $"; "") # Remove trailing space if .arg was empty
    )
  } +
  (
    # 1. Execute (matches exec, execre, and global)
    if .dispatcher | test("^execr?$|global") then
      if .arg | test("wpctl|pactl|Audio") then {category: "System", subcategory: "Audio"}
      elif .arg | test("brightnessctl|light") then {category: "System", subcategory: "Brightness"}
      elif .arg | test("hyprctl") then {category: "System", subcategory: "Hyprland CLI"}
      elif .arg | test("dms ipc") then {category: "DMS", subcategory: "Modals"}
      elif .arg | test("poweroff|reboot|systemctl") then {category: "System", subcategory: "Power"}
      else {category: "Execute", subcategory: "Launchers"}
      end
    elif .dispatcher | test("togglefloating|setfloating|settiled|pin|centerwindow") then
      {category: "Window", subcategory: "Floating"}
    elif .dispatcher | test("killactive|forcekillactive|closewindow|killwindow|fullscreen|fullscreenstate|alterzorder|denywindowfromgroup|setprop|toggleswallow") then
      {category: "Window", subcategory: "Management"}
    elif .dispatcher | test("movefocus|movewindow|swapwindow|cyclenext|swapnext|focuswindow|splitratio|moveactive|resizeactive|resizewindowpixel|movewindowpixel|focuscurrentorlast|movewindoworgroup") then
      {category: "Window", subcategory: "Layout & Focus"}
    elif .dispatcher | test("workspace|movetoworkspace|movetoworkspacesilent|renameworkspace|movecurrentworkspacetomonitor|focusworkspaceoncurrentmonitor|moveworkspacetomonitor|swapactiveworkspaces|togglespecialworkspace") then
      {category: "Workspace", subcategory: "Management"}
    elif .dispatcher | test("togglegroup|changegroupactive|lockgroups|lockactivegroup|moveintogroup|moveoutofgroup|movegroupwindow|setignoregrouplock") then
      {category: "Group", subcategory: "Management"}
    elif .dispatcher | test("dpms|focusmonitor") then
      {category: "Monitor", subcategory: "Management"}
    elif .dispatcher | test("pass|sendshortcut|sendkeystate|submap") then
      {category: "Input", subcategory: "Keyboard"}
    elif .dispatcher | test("movecursortocorner|movecursor") then
      {category: "Input", subcategory: "Mouse"}
    elif .dispatcher | test("exit|forceidles|forcerendererreload") then
      {category: "System", subcategory: "Session"}
    elif .dispatcher | test("signal|signalwindow|event|focusurgentorlast") then
      {category: "System", subcategory: "Signaling"}
    elif .dispatcher | test("tagwindow") then
      {category: "Tag", subcategory: "Management"}
    else
      {category: "Other", subcategory: .dispatcher}
    end
  )
)
| group_by(.key)
| map(
  .[0] +
  {
    description: (
      map(.description) | join(" / ")
    )
  }
)
