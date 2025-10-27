{
  children: [],
  keybinds: [
    .[]
    | select(.dispatcher | IN(
        "exec",
        "execr",
        "pass",
        "sendshortcut",
        "centerwindow",
        "fullscreen",
        "killactive",
        "layoutmsg",
        "mouse",
        "moveactive",
        "movefocus",
        "movewindow",
        "resizeactive",
        "submap",
        "togglefloating",
        "movetoworkspace",
        "workspace"
      ))
    | {
        mods: [
          (if .modmask == 64 then "MainMod"
           elif .modmask == 65 then "ShiftMod"
           elif .modmask == 0 then empty
           else (.modmask | tostring)
           end)
        ],
        key: .key,
        dispatcher: .dispatcher,
        params: (.arg // .params // ""),
        comment: (
          if .has_description then .description
          elif .dispatcher == "workspace"
            then "change focus to workspace " + (.arg // .params // "")
          elif .dispatcher == "movetoworkspace" then "move focused window to workspace " + (.arg // .params // "")
          else (.arg // .params // "")
          end
        )
      }
  ]
}
