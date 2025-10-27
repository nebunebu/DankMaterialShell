{
  children: [],
  keybinds: [
    .[]
    | {
        mods: [
          (if .modmask == 64 then "MainMod"
           elif .modmask == 65 then "ShiftMod"
           elif .modmask == 0 then empty
           else (.modmask | tostring)
           end)
        ],
        key: (.key | sub("^XF86"; "")),
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
