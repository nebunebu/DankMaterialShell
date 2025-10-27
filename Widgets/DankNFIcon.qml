import QtQuick
import qs.Common

Item {
    id: root

    property string name: ""
    property alias size: icon.font.pixelSize
    property alias color: icon.color

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    readonly property var iconMap: ({
                                        "docker": "\uf21f"
                                    })

    FontLoader {
        id: firaCodeFont
        source: Qt.resolvedUrl("../assets/fonts/nerd-fonts/FiraCodeNerdFont-Regular.ttf")
    }

    StyledText {
        id: icon

        anchors.fill: parent

        font.family: firaCodeFont.name
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.surfaceText
        text: root.iconMap[root.name] || ""
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        renderType: Text.NativeRendering
        antialiasing: true
    }
}
