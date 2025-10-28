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
        # category: (
        #   if (.dispatcher == "workspace"
        #     or .dispatcher == "movetoworkspace"
        #     or .dispatcher == "movetoworkspacesilent"
        #     or .dispatcher == "renameworkspace"
        #     or .dispatcher == "movecurrentworkspacetomonitor"
        #     or .dispatcher == "focusworkspaceoncurrentmonitor"
        #     or .dispatcher == "moveworkspacetomonitor"
        #     or .dispatcher == "swapactiveworkspaces"
        #     or .dispatcher == "togglespecialworkspace")
        #   then "workspace"
        #   elif (.dispatcher == "exec" or .dispatcher == "execr")
        #   then "exec"
        #   else null
        #   end
        # ),
        comment: (
          if .has_description then .description
          elif .dispatcher == "exec"
            then "exec " + (.arg)
          elif .dispatcher == "execr"
            then "exec raw" + (.arg)
          elif .dispatcher == "pass"
            then "pass" + (.arg)
          elif .dispatcher == "sendshortcut"
            then "sendshortcut" + (.arg)
          elif .dispatcher == "sendkeystate"
            then "sendkeystate" + (.arg)
          elif .dispatcher == "killactive"
            then "kill active win"
          elif .dispatcher == "forcekillactive"
            then "forcekill active win"
          elif .dispatcher == "signal"
            then "send signal " + (.arg) + " to active win"
            # TODO: needs to be written better
          elif .dispatcher == "signalwindow"
            then "send signal " + (.arg) + " to specified win"
          elif .dispatcher == "workspace"
            then "change to ws " + (.arg)
          else (.arg // "")
          # elif .dispatcher == "workspace"
          #   then "mv focus to ws " + (.arg)
          # elif .dispatcher == "movetoworkspace" then "mv focused win to ws " + (.arg // .params // "")
          # else (.arg // .params // "")
          end
        )
      }
  ]
}
