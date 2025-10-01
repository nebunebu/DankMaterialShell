import QtQuick
import qs.Common
import qs.Services

Item {
    id: root

    required property string pluginId
    property var pluginService: null
    default property alias content: settingsColumn.children

    implicitHeight: settingsColumn.implicitHeight
    height: implicitHeight

    function saveValue(key, value) {
        if (pluginService && pluginService.savePluginData) {
            pluginService.savePluginData(pluginId, key, value)
        }
    }

    function loadValue(key, defaultValue) {
        if (pluginService && pluginService.loadPluginData) {
            return pluginService.loadPluginData(pluginId, key, defaultValue)
        }
        return defaultValue
    }

    Column {
        id: settingsColumn
        width: parent.width
        spacing: Theme.spacingM
    }
}
