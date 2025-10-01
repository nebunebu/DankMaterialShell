//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.Common
import qs.Modals
import qs.Modals.Clipboard
import qs.Modals.Common
import qs.Modals.Settings
import qs.Modals.Spotlight
import qs.Modules
import qs.Modules.AppDrawer
import qs.Modules.DankDash
import qs.Modules.ControlCenter
import qs.Modules.Dock
import qs.Modules.Lock
import qs.Modules.Notifications.Center
import qs.Widgets
import qs.Modules.Notifications.Popup
import qs.Modules.OSD
import qs.Modules.ProcessList
import qs.Modules.Settings
import qs.Modules.DankBar
import qs.Modules.DankBar.Popouts
import qs.Services

ShellRoot {
    id: root

    readonly property bool runGreeter: Quickshell.env("DMS_RUN_GREETER") === "1" || Quickshell.env("DMS_RUN_GREETER") === "true"

    Loader {
        id: dmsShellLoader
        asynchronous: false
        sourceComponent: DMSShell{}
        active: !root.runGreeter
    }

    Loader {
        id: dmsGreeterLoader
        asynchronous: false
        sourceComponent: DMSGreeter{}
        active: root.runGreeter
    }
}
