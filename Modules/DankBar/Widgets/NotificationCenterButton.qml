import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

BasePill {
    id: root

    property bool hasUnread: false
    property bool isActive: false

    content: Component {
        Item {
            implicitWidth: root.widgetThickness - root.horizontalPadding * 2
            implicitHeight: root.widgetThickness - root.horizontalPadding * 2

            DankIcon {
                anchors.centerIn: parent
                name: SessionData.doNotDisturb ? "notifications_off" : "notifications"
                size: Theme.barIconSize(root.barThickness, -4)
                color: SessionData.doNotDisturb ? Theme.error : (root.isActive ? Theme.primary : Theme.surfaceText)
            }

            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: Theme.error
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: SettingsData.dankBarNoBackground ? 0 : 6
                anchors.topMargin: SettingsData.dankBarNoBackground ? 0 : 6
                visible: root.hasUnread
            }
        }
    }
}
