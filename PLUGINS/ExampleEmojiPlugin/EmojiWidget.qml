import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var pluginService: null

    // Load settings from PluginService
    property var enabledEmojis: pluginService ? pluginService.loadPluginData("exampleEmojiPlugin", "emojis", ["😊", "😢", "❤️"]) : ["😊", "😢", "❤️"]
    property int cycleInterval: pluginService ? pluginService.loadPluginData("exampleEmojiPlugin", "cycleInterval", 3000) : 3000
    property int maxBarEmojis: pluginService ? pluginService.loadPluginData("exampleEmojiPlugin", "maxBarEmojis", 3) : 3

    // Current state for cycling through emojis
    property int currentIndex: 0
    property var displayedEmojis: []

    // Timer to cycle through emojis at the configured interval
    Timer {
        interval: root.cycleInterval
        running: true
        repeat: true
        onTriggered: {
            if (root.enabledEmojis.length > 0) {
                root.currentIndex = (root.currentIndex + 1) % root.enabledEmojis.length
                root.updateDisplayedEmojis()
            }
        }
    }

    // Update the emojis shown in the bar when settings or index changes
    function updateDisplayedEmojis() {
        const maxToShow = Math.min(root.maxBarEmojis, root.enabledEmojis.length)
        let emojis = []
        for (let i = 0; i < maxToShow; i++) {
            const idx = (root.currentIndex + i) % root.enabledEmojis.length
            emojis.push(root.enabledEmojis[idx])
        }
        root.displayedEmojis = emojis
    }

    Component.onCompleted: {
        updateDisplayedEmojis()
    }

    onEnabledEmojisChanged: updateDisplayedEmojis()
    onMaxBarEmojisChanged: updateDisplayedEmojis()

    horizontalBarPill: Component {
        StyledRect {
            width: emojiRow.implicitWidth + Theme.spacingM * 2
            height: parent.widgetThickness
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Row {
                id: emojiRow
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                Repeater {
                    model: root.displayedEmojis
                    StyledText {
                        text: modelData
                        font.pixelSize: Theme.fontSizeLarge
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        StyledRect {
            width: parent.widgetThickness
            height: emojiColumn.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh

            Column {
                id: emojiColumn
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                Repeater {
                    model: root.displayedEmojis
                    StyledText {
                        text: modelData
                        font.pixelSize: Theme.fontSizeMedium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }

    popoutContent: Component {
        Item {
            width: parent.width
            height: parent.height

            // A grid of 120+ emojis for the user to pick from
            property var allEmojis: [
                "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃",
                "😉", "😊", "😇", "🥰", "😍", "🤩", "😘", "😗", "😚", "😙",
                "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔",
                "🤐", "🤨", "😐", "😑", "😶", "😏", "😒", "🙄", "😬", "🤥",
                "😌", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕", "🤢", "🤮",
                "🤧", "🥵", "🥶", "😶‍🌫️", "😵", "😵‍💫", "🤯", "🤠", "🥳", "😎",
                "🤓", "🧐", "😕", "😟", "🙁", "☹️", "😮", "😯", "😲", "😳",
                "🥺", "😦", "😧", "😨", "😰", "😥", "😢", "😭", "😱", "😖",
                "😣", "😞", "😓", "😩", "😫", "🥱", "😤", "😡", "😠", "🤬",
                "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔",
                "❤️‍🔥", "❤️‍🩹", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟",
                "👍", "👎", "👊", "✊", "🤛", "🤜", "🤞", "✌️", "🤟", "🤘",
                "👌", "🤌", "🤏", "👈", "👉", "👆", "👇", "☝️", "✋", "🤚"
            ]

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingM

                StyledText {
                    text: "Click an emoji to copy it!"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                DankFlickable {
                    width: parent.width
                    height: parent.height - parent.spacing - 30
                    contentWidth: emojiGrid.width
                    contentHeight: emojiGrid.height
                    clip: true

                    Grid {
                        id: emojiGrid
                        width: parent.width - Theme.spacingM
                        columns: 8
                        spacing: Theme.spacingS

                        Repeater {
                            model: allEmojis

                            StyledRect {
                                width: 45
                                height: 45
                                radius: Theme.cornerRadius
                                color: emojiMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                                border.width: 0

                                StyledText {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.pixelSize: Theme.fontSizeXLarge
                                }

                                MouseArea {
                                    id: emojiMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        Quickshell.execDetached(["sh", "-c", "echo -n '" + modelData + "' | wl-copy"])
                                        ToastService.show("Copied " + modelData + " to clipboard", 2000)
                                        root.closePopout()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: 500
}
