import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    property var axis: null
    property string section: "center"
    property var parentScreen: null
    property real widgetThickness: 30
    property real barThickness: 48

    property Component horizontalBarPill: null
    property Component verticalBarPill: null
    property Component popoutContent: null
    property real popoutWidth: 400
    property real popoutHeight: 400

    readonly property bool isVertical: axis?.isVertical ?? false
    readonly property bool hasHorizontalPill: horizontalBarPill !== null
    readonly property bool hasVerticalPill: verticalBarPill !== null
    readonly property bool hasPopout: popoutContent !== null

    width: isVertical ? (hasVerticalPill ? verticalPill.width : 0) : (hasHorizontalPill ? horizontalPill.width : 0)
    height: isVertical ? (hasVerticalPill ? verticalPill.height : 0) : (hasHorizontalPill ? horizontalPill.height : 0)

    BaseHorizontalPill {
        id: horizontalPill
        visible: !isVertical && hasHorizontalPill
        axis: root.axis
        section: root.section
        popoutTarget: hasPopout ? pluginPopout : null
        parentScreen: root.parentScreen
        widgetThickness: root.widgetThickness
        barThickness: root.barThickness
        content: root.horizontalBarPill
        onClicked: {
            if (hasPopout) {
                pluginPopout.toggle()
            }
        }
    }

    BaseVerticalPill {
        id: verticalPill
        visible: isVertical && hasVerticalPill
        axis: root.axis
        section: root.section
        popoutTarget: hasPopout ? pluginPopout : null
        parentScreen: root.parentScreen
        widgetThickness: root.widgetThickness
        barThickness: root.barThickness
        content: root.verticalBarPill
        onClicked: {
            if (hasPopout) {
                pluginPopout.toggle()
            }
        }
    }

    PluginPopout {
        id: pluginPopout
        contentWidth: root.popoutWidth
        contentHeight: root.popoutHeight
        pluginContent: root.popoutContent
    }
}
