import QtQuick
import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets

DankModal {
    id: root

    layerNamespace: "dms:power-menu"

    property int selectedRow: 0
    property int selectedCol: 0
    property int selectedIndex: selectedRow * 3 + selectedCol
    property rect parentBounds: Qt.rect(0, 0, 0, 0)
    property var parentScreen: null

    signal powerActionRequested(string action, string title, string message)
    signal lockRequested

    function openCentered() {
        parentBounds = Qt.rect(0, 0, 0, 0)
        parentScreen = null
        backgroundOpacity = 0.5
        open()
    }

    function openFromControlCenter(bounds, targetScreen) {
        parentBounds = bounds
        parentScreen = targetScreen
        backgroundOpacity = 0
        open()
    }

    function getActionAtIndex(index) {
        const actions = ["poweroff", "lock", "suspend", "reboot", "logout", SessionService.hibernateSupported ? "hibernate" : "restart"]
        return actions[index]
    }

    function selectOption(action) {
        if (action === "lock") {
            close()
            lockRequested()
            return
        }
        if (action === "restart") {
            close()
            Quickshell.execDetached(["dms", "restart"])
            return
        }
        close()
        const actions = {
            "logout": {
                "title": I18n.tr("Log Out"),
                "message": I18n.tr("Are you sure you want to log out?")
            },
            "suspend": {
                "title": I18n.tr("Suspend"),
                "message": I18n.tr("Are you sure you want to suspend the system?")
            },
            "hibernate": {
                "title": I18n.tr("Hibernate"),
                "message": I18n.tr("Are you sure you want to hibernate the system?")
            },
            "reboot": {
                "title": I18n.tr("Reboot"),
                "message": I18n.tr("Are you sure you want to reboot the system?")
            },
            "poweroff": {
                "title": I18n.tr("Power Off"),
                "message": I18n.tr("Are you sure you want to power off the system?")
            }
        }
        const selected = actions[action]
        if (selected) {
            root.powerActionRequested(action, selected.title, selected.message)
        }
    }

    shouldBeVisible: false
    width: 550
    height: contentLoader.item ? contentLoader.item.implicitHeight : 300
    enableShadow: true
    screen: parentScreen
    positioning: parentBounds.width > 0 ? "custom" : "center"
    customPosition: {
        if (parentBounds.width > 0) {
            const centerX = parentBounds.x + (parentBounds.width - width) / 2
            const centerY = parentBounds.y + (parentBounds.height - height) / 2
            return Qt.point(centerX, centerY)
        }
        return Qt.point(0, 0)
    }
    onBackgroundClicked: () => {
                             return close()
                         }
    onOpened: () => {
                  selectedRow = 0
                  selectedCol = 1
                  Qt.callLater(() => modalFocusScope.forceActiveFocus())
              }
    modalFocusScope.Keys.onPressed: event => {
                                        switch (event.key) {
                                            case Qt.Key_Left:
                                            selectedCol = (selectedCol - 1 + 3) % 3
                                            event.accepted = true
                                            break
                                            case Qt.Key_Right:
                                            selectedCol = (selectedCol + 1) % 3
                                            event.accepted = true
                                            break
                                            case Qt.Key_Up:
                                            case Qt.Key_Backtab:
                                            selectedRow = (selectedRow - 1 + 2) % 2
                                            event.accepted = true
                                            break
                                            case Qt.Key_Down:
                                            case Qt.Key_Tab:
                                            selectedRow = (selectedRow + 1) % 2
                                            event.accepted = true
                                            break
                                            case Qt.Key_Return:
                                            case Qt.Key_Enter:
                                            selectOption(getActionAtIndex(selectedIndex))
                                            event.accepted = true
                                            break
                                            case Qt.Key_N:
                                            if (event.modifiers & Qt.ControlModifier) {
                                                selectedCol = (selectedCol + 1) % 3
                                                event.accepted = true
                                            }
                                            break
                                            case Qt.Key_P:
                                            if (event.modifiers & Qt.ControlModifier) {
                                                selectedCol = (selectedCol - 1 + 3) % 3
                                                event.accepted = true
                                            }
                                            break
                                            case Qt.Key_J:
                                            if (event.modifiers & Qt.ControlModifier) {
                                                selectedRow = (selectedRow + 1) % 2
                                                event.accepted = true
                                            }
                                            break
                                            case Qt.Key_K:
                                            if (event.modifiers & Qt.ControlModifier) {
                                                selectedRow = (selectedRow - 1 + 2) % 2
                                                event.accepted = true
                                            }
                                            break
                                        }
                                    }

    content: Component {
        Item {
            anchors.fill: parent
            implicitHeight: mainColumn.implicitHeight + Theme.spacingL * 2

            Column {
                id: mainColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Grid {
                    width: parent.width
                    columns: 3
                    columnSpacing: Theme.spacingS
                    rowSpacing: Theme.spacingS

                    Rectangle {
                        id: poweroffButton
                        width: (parent.width - Theme.spacingS * 2) / 3
                        height: 100
                        radius: Theme.cornerRadius
                        color: {
                            if (root.selectedIndex === 0) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            } else if (poweroffArea.containsMouse) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                            } else {
                                return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                            }
                        }
                        border.color: root.selectedIndex === 0 ? Theme.primary : "transparent"
                        border.width: root.selectedIndex === 0 ? 2 : 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "power_settings_new"
                                size: Theme.iconSize + 8
                                color: poweroffArea.containsMouse ? Theme.error : Theme.surfaceText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: I18n.tr("Power Off")
                                font.pixelSize: Theme.fontSizeMedium
                                color: poweroffArea.containsMouse ? Theme.error : Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: poweroffArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: () => {
                                           root.selectedRow = 0
                                           root.selectedCol = 0
                                           selectOption("poweroff")
                                       }
                        }
                    }

                    Rectangle {
                        id: lockButton
                        width: (parent.width - Theme.spacingS * 2) / 3
                        height: 100
                        radius: Theme.cornerRadius
                        color: {
                            if (root.selectedIndex === 1) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            } else if (lockArea.containsMouse) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                            } else {
                                return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                            }
                        }
                        border.color: root.selectedIndex === 1 ? Theme.primary : "transparent"
                        border.width: root.selectedIndex === 1 ? 2 : 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "lock"
                                size: Theme.iconSize + 8
                                color: Theme.surfaceText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: I18n.tr("Lock")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: lockArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: () => {
                                           root.selectedRow = 0
                                           root.selectedCol = 1
                                           selectOption("lock")
                                       }
                        }
                    }

                    Rectangle {
                        id: suspendButton
                        width: (parent.width - Theme.spacingS * 2) / 3
                        height: 100
                        radius: Theme.cornerRadius
                        color: {
                            if (root.selectedIndex === 2) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            } else if (suspendArea.containsMouse) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                            } else {
                                return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                            }
                        }
                        border.color: root.selectedIndex === 2 ? Theme.primary : "transparent"
                        border.width: root.selectedIndex === 2 ? 2 : 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "bedtime"
                                size: Theme.iconSize + 8
                                color: Theme.surfaceText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: I18n.tr("Suspend")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: suspendArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: () => {
                                           root.selectedRow = 0
                                           root.selectedCol = 2
                                           selectOption("suspend")
                                       }
                        }
                    }

                    Rectangle {
                        id: rebootButton
                        width: (parent.width - Theme.spacingS * 2) / 3
                        height: 100
                        radius: Theme.cornerRadius
                        color: {
                            if (root.selectedIndex === 3) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            } else if (rebootArea.containsMouse) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                            } else {
                                return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                            }
                        }
                        border.color: root.selectedIndex === 3 ? Theme.primary : "transparent"
                        border.width: root.selectedIndex === 3 ? 2 : 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "restart_alt"
                                size: Theme.iconSize + 8
                                color: rebootArea.containsMouse ? Theme.warning : Theme.surfaceText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: I18n.tr("Reboot")
                                font.pixelSize: Theme.fontSizeMedium
                                color: rebootArea.containsMouse ? Theme.warning : Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: rebootArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: () => {
                                           root.selectedRow = 1
                                           root.selectedCol = 0
                                           selectOption("reboot")
                                       }
                        }
                    }

                    Rectangle {
                        id: logoutButton
                        width: (parent.width - Theme.spacingS * 2) / 3
                        height: 100
                        radius: Theme.cornerRadius
                        color: {
                            if (root.selectedIndex === 4) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            } else if (logoutArea.containsMouse) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                            } else {
                                return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                            }
                        }
                        border.color: root.selectedIndex === 4 ? Theme.primary : "transparent"
                        border.width: root.selectedIndex === 4 ? 2 : 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "logout"
                                size: Theme.iconSize + 8
                                color: Theme.surfaceText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: I18n.tr("Log Out")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: logoutArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: () => {
                                           root.selectedRow = 1
                                           root.selectedCol = 1
                                           selectOption("logout")
                                       }
                        }
                    }

                    Rectangle {
                        id: hibernateOrRestartButton
                        width: (parent.width - Theme.spacingS * 2) / 3
                        height: 100
                        radius: Theme.cornerRadius
                        color: {
                            if (root.selectedIndex === 5) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            } else if (hibernateRestartArea.containsMouse) {
                                return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                            } else {
                                return Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                            }
                        }
                        border.color: root.selectedIndex === 5 ? Theme.primary : "transparent"
                        border.width: root.selectedIndex === 5 ? 2 : 0

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: SessionService.hibernateSupported ? "ac_unit" : "refresh"
                                size: Theme.iconSize + 8
                                color: Theme.surfaceText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: SessionService.hibernateSupported ? I18n.tr("Hibernate") : I18n.tr("Restart")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        MouseArea {
                            id: hibernateRestartArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: () => {
                                           root.selectedRow = 1
                                           root.selectedCol = 2
                                           selectOption(SessionService.hibernateSupported ? "hibernate" : "restart")
                                       }
                        }
                    }
                }

                Item {
                    height: Theme.spacingS
                }
            }
        }
    }
}
