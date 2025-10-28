import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets

DankModal {
    id: root
    property real _maxW: Math.min(Screen.width  * 0.92, 1200)
    property real _maxH: Math.min(Screen.height * 0.92, 900)
    width:  _maxW
    height: _maxH
    onBackgroundClicked: close()

    Shortcut { sequence: "Esc"; onActivated: root.close() }

    // Add this property to DankModal
    property var groupedKeybinds: {
        const groups = {}
        const list = HyprKeybindsService.keybinds || []

        // Sort the list first
        list.sort((a, b) => {
            if (a.category !== b.category) return a.category.localeCompare(b.category);
            if (a.subcategory !== b.subcategory) return a.subcategory.localeCompare(b.subcategory);
            return a.key.localeCompare(b.key);
        });

        for (let i = 0; i < list.length; i++) {
            const item = list[i];
            const category = item.category || "Other";
            const subcategory = item.subcategory || "General";

            if (!groups[category]) {
                groups[category] = {}; // Create category object
            }
            if (!groups[category][subcategory]) {
                groups[category][subcategory] = []; // Create subcategory array
            }
            groups[category][subcategory].push(item);
        }
        return groups;
    }

    property var columns: {
        const categories = Object.keys(root.groupedKeybinds);
        const result = [[], [], [], []]; // 4 empty column arrays

        for (let i = 0; i < categories.length; i++) {
            // Distribute categories round-robin (0, 1, 2, 3, 0, 1, ...)
            result[i % 4].push(categories[i]);
        }
        return result;
    }
content: Component {
        Item {
            anchors.fill: parent

            DankFlickable {
                id: mainFlickable
                anchors.fill: parent
                anchors.margins: Theme.spacingL

                contentWidth: mainFlickable.width
                // Bind height to the new Row layout
                contentHeight: columnRow.implicitHeight
                clip: true

                Row {
                    id: columnRow
                    width: mainFlickable.width
                    spacing: Theme.spacingM

                    // LEVEL 1: Loop over the 4 column arrays
                    Repeater {
                        model: root.columns // e.g., [ ["Execute", "Workspace"], ["Monitor"], ["System"], ["Window"] ]

                        // This is one of the 4 main columns
                        Column {
                            width: (mainFlickable.width - parent.spacing * 3) / 4
                            spacing: Theme.spacingM // Space *between categories* in this column

                            // LEVEL 2: Loop over category names in this column's array
                            // modelData is now an array like ["Execute", "Workspace"]
                            Repeater {
                                model: modelData

                                // This is the Column for a single Category
                                Column {
                                    width: parent.width // Fill the main column
                                    spacing: Theme.spacingXS
                                    property string categoryName: modelData // modelData is now "Execute"

                                    // Category Title (e.g., "Window")
                                    StyledText {
                                        text: categoryName
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                    }
                                    Rectangle { width: parent.width; height: 1; color: Theme.primary; opacity: 0.3 }
                                    Item { width: 1; height: Theme.spacingS }

                                    // LEVEL 3: Loop over Subcategories
                                    Repeater {
                                        model: Object.keys(root.groupedKeybinds[categoryName])

                                        Column {
                                            width: parent.width
                                            spacing: Theme.spacingXS
                                            property string subcategoryName: modelData // modelData is "Launchers"

                                            // Subcategory Title (e.g., "Management")
                                            StyledText {
                                                text: subcategoryName
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.Bold
                                                color: Theme.surfaceVariantText
                                                opacity: 0.8
                                                leftPadding: Theme.spacingS
                                            }

                                            // LEVEL 4: Loop over Keybinds
                                            Repeater {
                                                model: root.groupedKeybinds[categoryName][subcategoryName]

                                                Row {
                                                    width: parent.width
                                                    spacing: Theme.spacingS

                                                    // Keybind (e.g., "Super+K")
                                                    StyledRect {
                                                        width: Math.min(140, parent.width * 0.42)
                                                        height: 22
                                                        radius: 4
                                                        opacity: 0.9

                                                        StyledText {
                                                            anchors.centerIn: parent
                                                            anchors.margins: 2
                                                            width: parent.width - 4
                                                            text: modelData.key
                                                            font.pixelSize: Theme.fontSizeSmall
                                                            font.weight: Font.Medium
                                                            isMonospace: true
                                                            elide: Text.ElideRight
                                                            horizontalAlignment: Text.AlignHCenter
                                                            color: Theme.secondary
                                                        }
                                                    }

                                                    // Description (e.G., "kill active win")
                                                    StyledText {
                                                        width: parent.width - 150
                                                        text: modelData.description
                                                        font.pixelSize: Theme.fontSizeSmall
                                                        opacity: 0.9
                                                        elide: Text.ElideRight
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }
                                            }

                                            Item { width: 1; height: Theme.spacingM } // Spacer between subcategories
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}
