import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

PanelWindow {
    id: screenshotPopup
    
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // Visible only when explicitly opened
    visible: state !== "idle"
    exclusionMode: ExclusionMode.Ignore

    property string state: "idle" // idle, loading, active, processing
    property string currentMode: "region" // region, window, screen
    property var activeWindows: []

    function open() {
        screenshotPopup.state = "loading"
        screenshotService.freezeScreen()
    }

    function close() {
        screenshotPopup.state = "idle"
    }
    
    function executeCapture() {
        if (screenshotPopup.currentMode === "screen") {
            screenshotService.processFullscreen()
            screenshotPopup.close()
        } else if (screenshotPopup.currentMode === "region") {
            // Check if rect exists
            if (selectionRect.width > 0) {
                screenshotService.processRegion(selectionRect.x, selectionRect.y, selectionRect.width, selectionRect.height)
                screenshotPopup.close()
            }
        } else if (screenshotPopup.currentMode === "window") {
            // If enter pressed in window mode, maybe capture the one under cursor?
        }
    }

    // Service
    Screenshot {
        id: screenshotService
        onScreenshotCaptured: path => {
            previewImage.source = ""
            previewImage.source = "file://" + path
            screenshotPopup.state = "active"
            // Reset selection
            selectionRect.width = 0
            selectionRect.height = 0
            // Fetch windows if we are in window mode, or pre-fetch
            screenshotService.fetchWindows()
            
            // Force focus on the overlay window content
            mainFocusScope.forceActiveFocus()
        }
        onWindowListReady: windows => {
            screenshotPopup.activeWindows = windows
        }
        onErrorOccurred: msg => {
            console.warn("Screenshot Error:", msg)
            screenshotPopup.close()
        }
    }

    // Mask to capture input on the entire window when open
    mask: Region {
        item: screenshotPopup.visible ? fullMask : emptyMask
    }

    Item {
        id: fullMask
        anchors.fill: parent
    }

    Item {
        id: emptyMask
        width: 0
        height: 0
    }

    // Focus grabber
    HyprlandFocusGrab {
        id: focusGrab
        windows: [screenshotPopup]
        active: screenshotPopup.visible
    }

    // Main Content
    FocusScope {
        id: mainFocusScope
        anchors.fill: parent
        focus: true
        
        Keys.onEscapePressed: screenshotPopup.close()
        Keys.onLeftPressed: modeSelector.cycle(-1)
        Keys.onRightPressed: modeSelector.cycle(1)
        Keys.onReturnPressed: screenshotPopup.executeCapture()
        
        // 1. The "Frozen" Image
        Image {
            id: previewImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            visible: screenshotPopup.state === "active"
        }

        // 2. Dimmer (Dark overlay)
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: screenshotPopup.state === "active" ? 0.4 : 0
            visible: screenshotPopup.state === "active" && screenshotPopup.currentMode !== "screen"
        }
        
        // 3. Window Selection Highlights
        Item {
            anchors.fill: parent
            visible: screenshotPopup.state === "active" && screenshotPopup.currentMode === "window"
            
            Repeater {
                model: screenshotPopup.activeWindows
                delegate: Rectangle {
                    x: modelData.at[0]
                    y: modelData.at[1]
                    width: modelData.size[0]
                    height: modelData.size[1]
                    color: "transparent"
                    border.color: hoverHandler.hovered ? Colors.primary : "transparent"
                    border.width: 2
                    
                    Rectangle {
                        anchors.fill: parent
                        color: Colors.primary
                        opacity: hoverHandler.hovered ? 0.2 : 0
                    }

                    HoverHandler {
                        id: hoverHandler
                    }
                    
                    TapHandler {
                        onTapped: {
                            screenshotService.processRegion(parent.x, parent.y, parent.width, parent.height)
                            screenshotPopup.close()
                        }
                    }
                }
            }
        }

        // 4. Region Selection (Drag) and Screen Capture (Click)
        MouseArea {
            id: regionArea
            anchors.fill: parent
            enabled: screenshotPopup.state === "active" && (screenshotPopup.currentMode === "region" || screenshotPopup.currentMode === "screen")
            hoverEnabled: true
            cursorShape: screenshotPopup.currentMode === "region" ? Qt.CrossCursor : Qt.ArrowCursor

            property point startPoint: Qt.point(0, 0)
            property bool selecting: false

            onPressed: mouse => {
                if (screenshotPopup.currentMode === "screen") {
                    // Immediate capture for screen mode
                    return
                }
                
                startPoint = Qt.point(mouse.x, mouse.y)
                selectionRect.x = mouse.x
                selectionRect.y = mouse.y
                selectionRect.width = 0
                selectionRect.height = 0
                selecting = true
            }

            onClicked: {
                if (screenshotPopup.currentMode === "screen") {
                    screenshotService.processFullscreen()
                    screenshotPopup.close()
                }
            }

            onPositionChanged: mouse => {
                if (!selecting) return
                
                var x = Math.min(startPoint.x, mouse.x)
                var y = Math.min(startPoint.y, mouse.y)
                var w = Math.abs(startPoint.x - mouse.x)
                var h = Math.abs(startPoint.y - mouse.y)
                
                selectionRect.x = x
                selectionRect.y = y
                selectionRect.width = w
                selectionRect.height = h
            }

            onReleased: {
                if (!selecting) return // for screen mode click
                
                selecting = false
                // Auto capture on release? Or wait for confirm? 
                // Usually region drag ends in capture.
                if (selectionRect.width > 5 && selectionRect.height > 5) {
                    screenshotService.processRegion(selectionRect.x, selectionRect.y, selectionRect.width, selectionRect.height)
                    screenshotPopup.close()
                }
            }
        }
        
        // Visual Selection Rect
        Rectangle {
            id: selectionRect
            visible: screenshotPopup.state === "active" && screenshotPopup.currentMode === "region"
            color: "transparent"
            border.color: Colors.primary
            border.width: 2
            
            Rectangle {
                anchors.fill: parent
                color: Colors.primary
                opacity: 0.2
            }
        }

        // 5. Controls UI (Bottom Bar)
        Rectangle {
            id: controlsBar
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 50
            
            // Padding of 16px around the content
            width: modeRow.width + 32
            height: modeRow.height + 32
            
            radius: Styling.radius(20)
            color: Colors.background
            border.color: Colors.surface
            border.width: 1
            visible: screenshotPopup.state === "active"
            
            // Catch-all MouseArea
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
            }
            
            // Highlight que se desplaza
            StyledRect {
                variant: "primary"
                id: highlight
                radius: Styling.radius(4)
                z: 0 
                
                property Item targetItem: modeRepeater.itemAt(modeSelector.currentIndex)
                visible: targetItem !== null

                // Target values relative to modeRow (container)
                property real tx: targetItem ? targetItem.x : 0
                property real ty: targetItem ? targetItem.y : 0
                property real tw: targetItem ? targetItem.width : 0
                property real th: targetItem ? targetItem.height : 0

                // Tracker 1 (Fast / Lead)
                property real t1x: tx; property real t1y: ty; property real t1w: tw; property real t1h: th
                Behavior on t1x { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration / 3; easing.type: Easing.OutSine } }
                Behavior on t1y { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration / 3; easing.type: Easing.OutSine } }
                Behavior on t1w { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration / 3; easing.type: Easing.OutSine } }
                Behavior on t1h { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration / 3; easing.type: Easing.OutSine } }

                // Tracker 2 (Slow / Follow)
                property real t2x: tx; property real t2y: ty; property real t2w: tw; property real t2h: th
                Behavior on t2x { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutSine } }
                Behavior on t2y { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutSine } }
                Behavior on t2w { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutSine } }
                Behavior on t2h { enabled: Config.animDuration > 0; NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutSine } }

                // Elastic effect + Container offset
                x: Math.min(t1x, t2x) + modeRow.x
                y: Math.min(t1y, t2y) + modeRow.y
                width: Math.max(t1x + t1w, t2x + t2w) - Math.min(t1x, t2x)
                height: Math.max(t1y + t1h, t2y + t2h) - Math.min(t1y, t2y)
            }

            Row {
                id: modeRow
                anchors.centerIn: parent
                spacing: 10
                
                // Logic wrapper for index management
                QtObject {
                    id: modeSelector
                    property int currentIndex: 0
                    property var modes: [
                        { name: "region", icon: Icons.regionScreenshot, label: "Region" }, 
                        { name: "window", icon: Icons.windowScreenshot, label: "Window" }, 
                        { name: "screen", icon: Icons.fullScreenshot, label: "Screen" }
                    ]
                    
                    function cycle(direction) {
                        currentIndex = (currentIndex + direction + modes.length) % modes.length
                        screenshotPopup.currentMode = modes[currentIndex].name
                    }
                }

                Repeater {
                    id: modeRepeater
                    model: modeSelector.modes
                    delegate: Item {
                        width: 48
                        height: 48
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                modeSelector.currentIndex = index
                                screenshotPopup.currentMode = modelData.name
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Icons.font
                            font.pixelSize: 24
                            color: (index === modeSelector.currentIndex) 
                                ? Config.resolveColor(Config.theme.srPrimary.itemColor)
                                : Colors.overBackground
                            
                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation { duration: Config.animDuration / 2 }
                            }
                        }

                        StyledToolTip {
                            visible: parent.hovered
                            tooltipText: modelData.label
                            delay: 100
                        }
                    }
                }
            }
        }
    }
}
