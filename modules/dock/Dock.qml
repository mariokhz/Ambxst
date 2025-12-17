pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.modules.globals
import qs.config

Scope {
    id: root
    
    property bool pinned: Config.dock?.pinnedOnStartup ?? false

    // Position configuration with fallback logic to avoid bar collision
    readonly property string userPosition: Config.dock?.position ?? "bottom"
    readonly property string barPosition: Config.bar?.position ?? "top"
    
    // Effective position: if dock and bar are on the same side, dock moves to fallback
    readonly property string position: {
        if (userPosition !== barPosition) {
            return userPosition;
        }
        // Collision detected - apply fallback
        switch (userPosition) {
            case "bottom": return "left";
            case "left": return "right";
            case "right": return "left";
            case "top": return "bottom";
            default: return "bottom";
        }
    }
    
    readonly property bool isBottom: position === "bottom"
    readonly property bool isLeft: position === "left"
    readonly property bool isRight: position === "right"
    readonly property bool isVertical: isLeft || isRight

    // Margin calculations
    readonly property int dockMargin: Config.dock?.margin ?? 8
    readonly property int hyprlandGapsOut: Config.hyprland?.gapsOut ?? 4
    // Side facing windows needs to subtract gapsOut to maintain visual consistency
    // But only if margin > 0, otherwise both sides are 0
    readonly property int windowSideMargin: dockMargin > 0 ? Math.max(0, dockMargin - hyprlandGapsOut) : 0
    readonly property int edgeSideMargin: dockMargin

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.dock?.screenList ?? [];
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        PanelWindow {
            id: dockWindow
            
            required property ShellScreen modelData
            screen: modelData
            visible: Config.dock?.enabled ?? false

            // Reveal logic: pinned, hover, no active window
            property bool reveal: root.pinned || 
                (Config.dock?.hoverToReveal && dockMouseArea.containsMouse) || 
                !ToplevelManager.activeToplevel?.activated

            anchors {
                bottom: root.isBottom
                left: root.isLeft
                right: root.isRight
            }

            // Total margin includes dock + margins (window side + edge side)
            readonly property int totalMargin: root.windowSideMargin + root.edgeSideMargin
            readonly property int shadowSpace: 32
            readonly property int dockSize: Config.dock?.height ?? 56
            
            // Reserve space when pinned (without shadow space to not push windows too far)
            exclusiveZone: root.pinned ? dockSize + totalMargin : 0

            implicitWidth: root.isVertical 
                ? dockSize + totalMargin + shadowSpace * 2
                : dockContent.implicitWidth + shadowSpace * 2
            implicitHeight: root.isVertical
                ? dockContent.implicitHeight + shadowSpace * 2
                : dockSize + totalMargin + shadowSpace * 2
            
            WlrLayershell.namespace: "quickshell:dock"
            color: "transparent"

            mask: Region {
                item: dockMouseArea
            }

            // Content sizing helper
            Item {
                id: dockContent
                implicitWidth: root.isVertical ? dockWindow.dockSize : dockLayoutHorizontal.implicitWidth + 16
                implicitHeight: root.isVertical ? dockLayoutVertical.implicitHeight + 16 : dockWindow.dockSize
            }

            MouseArea {
                id: dockMouseArea
                hoverEnabled: true
                
                // Size
                width: root.isVertical 
                    ? (dockWindow.reveal ? dockWindow.dockSize + dockWindow.totalMargin + dockWindow.shadowSpace : (Config.dock?.hoverRegionHeight ?? 4))
                    : dockContent.implicitWidth + 20
                height: root.isVertical
                    ? dockContent.implicitHeight + 20
                    : (dockWindow.reveal ? dockWindow.dockSize + dockWindow.totalMargin + dockWindow.shadowSpace : (Config.dock?.hoverRegionHeight ?? 4))

                // Position using x/y instead of anchors to avoid sticky anchor issues
                x: root.isBottom 
                    ? (parent.width - width) / 2
                    : (root.isLeft ? 0 : parent.width - width)
                y: root.isVertical 
                    ? (parent.height - height) / 2
                    : parent.height - height

                Behavior on x {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: Config.animDuration / 4; easing.type: Easing.OutCubic }
                }
                Behavior on y {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: Config.animDuration / 4; easing.type: Easing.OutCubic }
                }

                Behavior on width {
                    enabled: Config.animDuration > 0 && root.isVertical
                    NumberAnimation { duration: Config.animDuration / 4; easing.type: Easing.OutCubic }
                }

                Behavior on height {
                    enabled: Config.animDuration > 0 && !root.isVertical
                    NumberAnimation { duration: Config.animDuration / 4; easing.type: Easing.OutCubic }
                }

                // Dock container
                Item {
                    id: dockContainer
                    
                    // Size
                    width: dockContent.implicitWidth
                    height: dockContent.implicitHeight
                    
                    // Position using x/y
                    x: root.isBottom 
                        ? (parent.width - width) / 2
                        : (root.isLeft ? root.edgeSideMargin : parent.width - width - root.edgeSideMargin)
                    y: root.isVertical 
                        ? (parent.height - height) / 2
                        : parent.height - height - root.edgeSideMargin

                    Behavior on x {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration / 4; easing.type: Easing.OutCubic }
                    }
                    Behavior on y {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration / 4; easing.type: Easing.OutCubic }
                    }

                    // Animation for dock reveal
                    opacity: dockWindow.reveal ? 1 : 0
                    Behavior on opacity {
                        enabled: Config.animDuration > 0
                        NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                    }

                    // Slide animation
                    transform: Translate {
                        x: root.isVertical 
                            ? (dockWindow.reveal ? 0 : (root.isLeft ? -(dockContainer.width + root.edgeSideMargin) : (dockContainer.width + root.edgeSideMargin)))
                            : 0
                        y: root.isBottom 
                            ? (dockWindow.reveal ? 0 : (dockContainer.height + root.edgeSideMargin))
                            : 0
                        Behavior on x {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                        }
                        Behavior on y {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: Config.animDuration / 2; easing.type: Easing.OutCubic }
                        }
                    }

                    // Background
                    StyledRect {
                        id: dockBackground
                        anchors.fill: parent
                        variant: "bg"
                        enableShadow: true
                        radius: Styling.radius(4)
                        
                        implicitWidth: root.isVertical 
                            ? dockWindow.dockSize 
                            : dockLayoutHorizontal.implicitWidth + 16
                        implicitHeight: root.isVertical 
                            ? dockLayoutVertical.implicitHeight + 16 
                            : dockWindow.dockSize
                    }

                    // Horizontal layout (bottom dock)
                    RowLayout {
                        id: dockLayoutHorizontal
                        anchors.centerIn: parent
                        spacing: Config.dock?.spacing ?? 4
                        visible: !root.isVertical
                        
                        // Pin button
                        Loader {
                            active: Config.dock?.showPinButton ?? true
                            Layout.alignment: Qt.AlignVCenter
                            
                            sourceComponent: Button {
                                id: pinButton
                                implicitWidth: 32
                                implicitHeight: 32
                                
                                background: Rectangle {
                                    radius: Styling.radius(-2)
                                    color: root.pinned ? 
                                        Colors.primary : 
                                        (pinButton.hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15) : "transparent")
                                    
                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                contentItem: Text {
                                    text: Icons.pin
                                    font.family: Icons.font
                                    font.pixelSize: 16
                                    color: root.pinned ? Colors.overPrimary : Colors.overBackground
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    
                                    rotation: root.pinned ? 0 : 45
                                    Behavior on rotation {
                                        enabled: Config.animDuration > 0
                                        NumberAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                onClicked: root.pinned = !root.pinned
                                
                                StyledToolTip {
                                    show: pinButton.hovered
                                    tooltipText: root.pinned ? "Unpin dock" : "Pin dock"
                                }
                            }
                        }

                        // Separator after pin button
                        Loader {
                            active: Config.dock?.showPinButton ?? true
                            Layout.alignment: Qt.AlignVCenter
                            
                            sourceComponent: Separator {
                                vert: true
                                implicitHeight: (Config.dock?.iconSize ?? 40) * 0.6
                            }
                        }

                        // App buttons
                        Repeater {
                            model: TaskbarApps.apps
                            
                            DockAppButton {
                                required property var modelData
                                appToplevel: modelData
                                Layout.alignment: Qt.AlignVCenter
                                dockPosition: "bottom"
                            }
                        }

                        // Separator before overview button
                        Loader {
                            active: Config.dock?.showOverviewButton ?? true
                            Layout.alignment: Qt.AlignVCenter
                            
                            sourceComponent: Separator {
                                vert: true
                                implicitHeight: (Config.dock?.iconSize ?? 40) * 0.6
                            }
                        }

                        // Overview button
                        Loader {
                            active: Config.dock?.showOverviewButton ?? true
                            Layout.alignment: Qt.AlignVCenter
                            
                            sourceComponent: Button {
                                id: overviewButton
                                implicitWidth: 32
                                implicitHeight: 32
                                
                                background: Rectangle {
                                    radius: Styling.radius(-2)
                                    color: overviewButton.hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15) : "transparent"
                                    
                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                contentItem: Text {
                                    text: Icons.apps
                                    font.family: Icons.font
                                    font.pixelSize: 18
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                onClicked: {
                                    // Toggle overview on the current screen
                                    let visibilities = Visibilities.getForScreen(dockWindow.screen.name);
                                    if (visibilities) {
                                        visibilities.overview = !visibilities.overview;
                                    }
                                }
                                
                                StyledToolTip {
                                    show: overviewButton.hovered
                                    tooltipText: "Overview"
                                }
                            }
                        }
                    }

                    // Vertical layout (left/right dock)
                    ColumnLayout {
                        id: dockLayoutVertical
                        anchors.centerIn: parent
                        spacing: Config.dock?.spacing ?? 4
                        visible: root.isVertical
                        
                        // Pin button
                        Loader {
                            active: Config.dock?.showPinButton ?? true
                            Layout.alignment: Qt.AlignHCenter
                            
                            sourceComponent: Button {
                                id: pinButtonV
                                implicitWidth: 32
                                implicitHeight: 32
                                
                                background: Rectangle {
                                    radius: Styling.radius(-2)
                                    color: root.pinned ? 
                                        Colors.primary : 
                                        (pinButtonV.hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15) : "transparent")
                                    
                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                contentItem: Text {
                                    text: Icons.pin
                                    font.family: Icons.font
                                    font.pixelSize: 16
                                    color: root.pinned ? Colors.overPrimary : Colors.overBackground
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    
                                    rotation: root.pinned ? 0 : 45
                                    Behavior on rotation {
                                        enabled: Config.animDuration > 0
                                        NumberAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                onClicked: root.pinned = !root.pinned
                                
                                StyledToolTip {
                                    show: pinButtonV.hovered
                                    tooltipText: root.pinned ? "Unpin dock" : "Pin dock"
                                }
                            }
                        }

                        // Separator after pin button
                        Loader {
                            active: Config.dock?.showPinButton ?? true
                            Layout.alignment: Qt.AlignHCenter
                            
                            sourceComponent: Separator {
                                vert: false
                                implicitWidth: (Config.dock?.iconSize ?? 40) * 0.6
                            }
                        }

                        // App buttons
                        Repeater {
                            model: TaskbarApps.apps
                            
                            DockAppButton {
                                required property var modelData
                                appToplevel: modelData
                                Layout.alignment: Qt.AlignHCenter
                                dockPosition: root.position
                            }
                        }

                        // Separator before overview button
                        Loader {
                            active: Config.dock?.showOverviewButton ?? true
                            Layout.alignment: Qt.AlignHCenter
                            
                            sourceComponent: Separator {
                                vert: false
                                implicitWidth: (Config.dock?.iconSize ?? 40) * 0.6
                            }
                        }

                        // Overview button
                        Loader {
                            active: Config.dock?.showOverviewButton ?? true
                            Layout.alignment: Qt.AlignHCenter
                            
                            sourceComponent: Button {
                                id: overviewButtonV
                                implicitWidth: 32
                                implicitHeight: 32
                                
                                background: Rectangle {
                                    radius: Styling.radius(-2)
                                    color: overviewButtonV.hovered ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.15) : "transparent"
                                    
                                    Behavior on color {
                                        enabled: Config.animDuration > 0
                                        ColorAnimation { duration: Config.animDuration / 2 }
                                    }
                                }
                                
                                contentItem: Text {
                                    text: Icons.apps
                                    font.family: Icons.font
                                    font.pixelSize: 18
                                    color: Colors.overBackground
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                
                                onClicked: {
                                    // Toggle overview on the current screen
                                    let visibilities = Visibilities.getForScreen(dockWindow.screen.name);
                                    if (visibilities) {
                                        visibilities.overview = !visibilities.overview;
                                    }
                                }
                                
                                StyledToolTip {
                                    show: overviewButtonV.hovered
                                    tooltipText: "Overview"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
