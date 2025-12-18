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

Button {
    id: root

    required property var appToplevel
    property int lastFocused: -1
    property real iconSize: 18
    property string orientation: "horizontal"

    readonly property bool isVertical: orientation === "vertical"
    readonly property bool isSeparator: appToplevel.appId === "SEPARATOR"
    readonly property var desktopEntry: isSeparator ? null : DesktopEntries.heuristicLookup(appToplevel.appId)
    readonly property bool appIsActive: !isSeparator && appToplevel.toplevels.some(t => t.activated === true)
    readonly property bool appIsRunning: !isSeparator && appToplevel.toplevels.length > 0

    enabled: !isSeparator
    implicitWidth: isSeparator ? (isVertical ? iconSize : 2) : iconSize + 8
    implicitHeight: isSeparator ? (isVertical ? 2 : iconSize) : iconSize + 8

    padding: 0
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    background: Item {
        Rectangle {
            anchors.fill: parent
            radius: Styling.radius(-3)
            color: root.appIsActive 
                ? Colors.primary 
                : (root.hovered || root.pressed)
                    ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15)
                    : "transparent"
            opacity: root.pressed ? 1 : (root.appIsActive ? 0.3 : 0.7)

            Behavior on color {
                enabled: Config.animDuration > 0
                ColorAnimation { duration: Config.animDuration / 2 }
            }
            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: Config.animDuration / 2 }
            }
        }
    }

    contentItem: Item {
        // Separator
        Loader {
            active: root.isSeparator
            anchors.centerIn: parent
            sourceComponent: Separator {
                vert: !root.isVertical
                implicitWidth: root.isVertical ? root.iconSize : 2
                implicitHeight: root.isVertical ? 2 : root.iconSize
            }
        }

        // App icon
        Loader {
            active: !root.isSeparator
            anchors.centerIn: parent
            sourceComponent: Item {
                width: root.iconSize
                height: root.iconSize

                readonly property string iconName: {
                    if (root.desktopEntry && root.desktopEntry.icon) {
                        return root.desktopEntry.icon;
                    }
                    return AppSearch.guessIcon(root.appToplevel.appId);
                }

                Image {
                    id: appIcon
                    anchors.fill: parent
                    source: "image://icon/" + parent.iconName
                    sourceSize.width: root.iconSize * 2
                    sourceSize.height: root.iconSize * 2
                    fillMode: Image.PreserveAspectFit
                    visible: !(Config.dock?.monochromeIcons ?? false)
                }

                // Monochrome version with effect
                Image {
                    id: appIconMono
                    anchors.fill: parent
                    source: "image://icon/" + parent.iconName
                    sourceSize.width: root.iconSize * 2
                    sourceSize.height: root.iconSize * 2
                    fillMode: Image.PreserveAspectFit
                    visible: Config.dock?.monochromeIcons ?? false
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        saturation: 0
                        brightness: 0.1
                        colorization: 0.8
                        colorizationColor: Colors.primary
                    }
                }
            }
        }
    }

    // Left click: launch or cycle through windows
    onClicked: {
        if (isSeparator) return;

        if (appToplevel.toplevels.length === 0) {
            // Launch the app
            if (desktopEntry) {
                desktopEntry.execute();
            }
            return;
        }

        // Cycle through running windows
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length;
        appToplevel.toplevels[lastFocused].activate();
    }

    // Middle click: always launch new instance
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.RightButton

        onClicked: mouse => {
            if (root.isSeparator) return;

            if (mouse.button === Qt.MiddleButton) {
                // Launch new instance
                if (root.desktopEntry) {
                    root.desktopEntry.execute();
                }
            } else if (mouse.button === Qt.RightButton) {
                // Toggle pin
                TaskbarApps.togglePin(root.appToplevel.appId);
            }
        }
    }

    // Tooltip
    StyledToolTip {
        show: root.hovered && !root.isSeparator
        tooltipText: root.desktopEntry?.name ?? root.appToplevel.appId
    }
}
