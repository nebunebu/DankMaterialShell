{
  children: [],
  keybinds: [
    .[]
    | {
        mods: [
          (if .modmask == 0 then empty
           elif .modmask == 1 then "Shift"
           elif .modmask == 4 then "Ctrl"
           elif .modmask == 8 then "Alt_L"
           elif .modmask == 64 then "Super"
           elif .modmask == 65 then "SuperShift"
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
