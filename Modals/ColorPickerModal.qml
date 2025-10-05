import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: colorPickerModal

    property string availablePicker: "zenity"

    signal colorSelected(color selectedColor)

    function show() {
        if (availablePicker === "kcolorchooser") {
            kcolorchooserProcess.running = true
        } else {
            zenityProcess.running = true
        }
    }

    function hide() {
        kcolorchooserProcess.running = false
        zenityProcess.running = false
    }

    function copyColorToClipboard(colorValue) {
        Quickshell.execDetached(["sh", "-c", `echo "${colorValue}" | wl-copy`])
        ToastService.showInfo(`Color ${colorValue} copied`)
    }

    Process {
        id: kcolorDetector
        running: false
        command: ["which", "kcolorchooser"]

        onExited: (code, status) => {
            if (code === 0) {
                availablePicker = "kcolorchooser"
            }
        }
    }

    Process {
        id: kcolorchooserProcess
        running: false
        command: ["kcolorchooser", "--print"]

        stdout: SplitParser {
            onRead: data => {
                const colorValue = data.trim()
                if (colorValue.length > 0) {
                    copyColorToClipboard(colorValue)
                    colorSelected(colorValue)
                }
            }
        }
    }

    Process {
        id: zenityProcess
        running: false
        command: ["zenity", "--color-selection", "--show-palette"]

        stdout: SplitParser {
            onRead: data => {
                const colorValue = data.trim()
                if (colorValue.length > 0) {
                    copyColorToClipboard(colorValue)
                    colorSelected(colorValue)
                }
            }
        }
    }

    Component.onCompleted: {
        kcolorDetector.running = true
    }
}