import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules

Variants {
    model: {
        if (SessionData.isGreeterMode) {
            return Quickshell.screens
        }
        return SettingsData.getFilteredScreens("wallpaper")
    }

    PanelWindow {
        id: blurWallpaperWindow

        required property var modelData

        screen: modelData

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "dms:blurwallpaper"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        color: "transparent"

        Item {
            id: root
            anchors.fill: parent

            property string source: SessionData.getMonitorWallpaper(modelData.name) || ""
            property bool isColorSource: source.startsWith("#")

            Connections {
                target: SessionData
                function onIsLightModeChanged() {
                    if (SessionData.perModeWallpaper) {
                        var newSource = SessionData.getMonitorWallpaper(modelData.name) || ""
                        if (newSource !== root.source) {
                            root.source = newSource
                        }
                    }
                }
            }

            function getFillMode(modeName) {
                switch(modeName) {
                    case "Stretch": return Image.Stretch
                    case "Fit":
                    case "PreserveAspectFit": return Image.PreserveAspectFit
                    case "Fill":
                    case "PreserveAspectCrop": return Image.PreserveAspectCrop
                    case "Tile": return Image.Tile
                    case "TileVertically": return Image.TileVertically
                    case "TileHorizontally": return Image.TileHorizontally
                    case "Pad": return Image.Pad
                    default: return Image.PreserveAspectCrop
                }
            }

            WallpaperEngineProc {
                id: weProc
                monitor: modelData.name
            }

            Component.onCompleted: {
                if (source) {
                    const formattedSource = source.startsWith("file://") ? source : "file://" + source
                    wallpaperImage.source = formattedSource
                }
            }

            Component.onDestruction: {
                weProc.stop()
            }

            onSourceChanged: {
                const isWE = source.startsWith("we:")
                const isColor = source.startsWith("#")

                if (isWE) {
                    wallpaperImage.source = ""
                    weProc.start(source.substring(3))
                } else {
                    weProc.stop()
                    if (!source) {
                        wallpaperImage.source = ""
                    } else if (isColor) {
                        wallpaperImage.source = ""
                    } else {
                        wallpaperImage.source = source.startsWith("file://") ? source : "file://" + source
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: !root.source || root.isColorSource
                asynchronous: true

                sourceComponent: DankBackdrop {
                    screenName: modelData.name
                }
            }

            Image {
                id: wallpaperImage
                anchors.fill: parent
                visible: false
                asynchronous: true
                smooth: true
                cache: true
                fillMode: root.getFillMode(SettingsData.wallpaperFillMode)
            }

            MultiEffect {
                anchors.fill: parent
                source: wallpaperImage
                blurEnabled: true
                blur: 0.8
                blurMax: 75
            }
        }
    }
}
