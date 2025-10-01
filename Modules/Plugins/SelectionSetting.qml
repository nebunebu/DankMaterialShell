import QtQuick
import qs.Common
import qs.Widgets

Column {
    id: root

    required property string settingKey
    required property string label
    property string description: ""
    required property var options
    property string defaultValue: ""
    property string value: defaultValue

    width: parent.width
    spacing: Theme.spacingS

    readonly property var optionLabels: {
        const labels = []
        for (let i = 0; i < options.length; i++) {
            labels.push(options[i].label || options[i])
        }
        return labels
    }

    readonly property var valueToLabel: {
        const map = {}
        for (let i = 0; i < options.length; i++) {
            const opt = options[i]
            if (typeof opt === 'object') {
                map[opt.value] = opt.label
            } else {
                map[opt] = opt
            }
        }
        return map
    }

    readonly property var labelToValue: {
        const map = {}
        for (let i = 0; i < options.length; i++) {
            const opt = options[i]
            if (typeof opt === 'object') {
                map[opt.label] = opt.value
            } else {
                map[opt] = opt
            }
        }
        return map
    }

    Component.onCompleted: {
        const settings = findSettings()
        if (settings) {
            value = settings.loadValue(settingKey, defaultValue)
        }
    }

    onValueChanged: {
        const settings = findSettings()
        if (settings) {
            settings.saveValue(settingKey, value)
        }
    }

    function findSettings() {
        let item = parent
        while (item) {
            if (item.saveValue !== undefined && item.loadValue !== undefined) {
                return item
            }
            item = item.parent
        }
        return null
    }

    Row {
        width: parent.width
        spacing: Theme.spacingM

        Column {
            width: parent.width * 0.4
            spacing: Theme.spacingXS
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: root.label
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            StyledText {
                text: root.description
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                width: parent.width
                wrapMode: Text.WordWrap
                visible: root.description !== ""
            }
        }

        DankDropdown {
            width: parent.width * 0.6 - Theme.spacingM
            anchors.verticalCenter: parent.verticalCenter
            currentValue: root.valueToLabel[root.value] || root.value
            options: root.optionLabels
            onValueChanged: newValue => {
                root.value = root.labelToValue[newValue] || newValue
            }
        }
    }
}
