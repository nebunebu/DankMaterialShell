import QtQuick
import qs.Common
import qs.Widgets

DankPopout {
    id: root

    property var triggerScreen: null
    property Component pluginContent: null
    property real contentWidth: 400
    property real contentHeight: 400

    function setTriggerPosition(x, y, width, section, screen) {
        triggerX = x
        triggerY = y
        triggerWidth = width
        triggerSection = section
        triggerScreen = screen
    }

    popupWidth: contentWidth
    popupHeight: popoutContent.item ? popoutContent.item.implicitHeight : contentHeight
    screen: triggerScreen
    shouldBeVisible: false
    visible: shouldBeVisible

    content: Component {
        Rectangle {
            id: popoutContainer

            implicitHeight: popoutColumn.implicitHeight + Theme.spacingL * 2
            color: Theme.popupBackground()
            radius: Theme.cornerRadius
            border.width: 0
            antialiasing: true
            smooth: true
            focus: true

            Component.onCompleted: {
                if (root.shouldBeVisible) {
                    forceActiveFocus()
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }

            Connections {
                target: root
                function onShouldBeVisibleChanged() {
                    if (root.shouldBeVisible) {
                        Qt.callLater(() => {
                            popoutContainer.forceActiveFocus()
                        })
                    }
                }
            }

            Column {
                id: popoutColumn
                width: parent.width - Theme.spacingL * 2
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL

                Row {
                    width: parent.width
                    height: 32
                    visible: closeButton.visible

                    Item {
                        width: parent.width - 32
                        height: 32
                    }

                    Rectangle {
                        id: closeButton
                        width: 32
                        height: 32
                        radius: 16
                        color: closeArea.containsMouse ? Theme.errorHover : "transparent"
                        visible: true

                        DankIcon {
                            anchors.centerIn: parent
                            name: "close"
                            size: Theme.iconSize - 4
                            color: closeArea.containsMouse ? Theme.error : Theme.surfaceText
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: {
                                root.close()
                            }
                        }
                    }
                }

                Loader {
                    id: popoutContent
                    width: parent.width
                    sourceComponent: root.pluginContent
                }
            }
        }
    }
}
