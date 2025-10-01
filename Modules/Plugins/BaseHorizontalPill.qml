import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    property var axis: null
    property string section: "center"
    property var popoutTarget: null
    property var parentScreen: null
    property real widgetThickness: 30
    property real barThickness: 48
    property alias content: contentLoader.sourceComponent

    readonly property real horizontalPadding: SettingsData.dankBarNoBackground ? 0 : Math.max(Theme.spacingXS, Theme.spacingS * (widgetThickness / 30))

    signal clicked()

    width: contentLoader.item ? (contentLoader.item.implicitWidth + horizontalPadding * 2) : 0
    height: widgetThickness
    radius: SettingsData.dankBarNoBackground ? 0 : Theme.cornerRadius
    color: {
        if (SettingsData.dankBarNoBackground) {
            return "transparent"
        }

        const baseColor = mouseArea.containsMouse ? Theme.widgetBaseHoverColor : Theme.widgetBaseBackgroundColor
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency)
    }

    Loader {
        id: contentLoader
        anchors.centerIn: parent
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            if (popoutTarget && popoutTarget.setTriggerPosition) {
                const globalPos = mapToGlobal(0, 0)
                const currentScreen = parentScreen || Screen
                const pos = SettingsData.getPopupTriggerPosition(globalPos, currentScreen, barThickness, width)
                popoutTarget.setTriggerPosition(pos.x, pos.y, pos.width, section, currentScreen)
            }
            root.clicked()
        }
    }
}
