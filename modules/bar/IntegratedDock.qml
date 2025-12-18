pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

StyledRect {
    id: root

    required property var bar
    property string orientation: "horizontal"

    readonly property bool isVertical: orientation === "vertical"
    readonly property bool isIntegrated: (Config.dock?.theme ?? "default") === "integrated"
    readonly property string dockPosition: Config.dock?.position ?? "center"

    // Compact sizing for integrated dock
    readonly property int iconSize: 18
    readonly property int itemSpacing: 2

    visible: (Config.dock?.enabled ?? false) && isIntegrated

    variant: "bg"
    radius: Styling.radius(0)
    enableShadow: false

    implicitWidth: isVertical ? 36 : dockLayout.implicitWidth + 8
    implicitHeight: isVertical ? dockLayoutVertical.implicitHeight + 8 : 36

    // Horizontal layout
    RowLayout {
        id: dockLayout
        anchors.centerIn: parent
        spacing: root.itemSpacing
        visible: !root.isVertical

        // App buttons
        Repeater {
            model: TaskbarApps.apps

            IntegratedDockAppButton {
                required property var modelData
                appToplevel: modelData
                iconSize: root.iconSize
                Layout.alignment: Qt.AlignVCenter
                orientation: root.orientation
            }
        }
    }

    // Vertical layout
    ColumnLayout {
        id: dockLayoutVertical
        anchors.centerIn: parent
        spacing: root.itemSpacing
        visible: root.isVertical

        // App buttons
        Repeater {
            model: TaskbarApps.apps

            IntegratedDockAppButton {
                required property var modelData
                appToplevel: modelData
                iconSize: root.iconSize
                Layout.alignment: Qt.AlignHCenter
                orientation: root.orientation
            }
        }
    }
}
