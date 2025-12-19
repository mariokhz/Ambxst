pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.globals
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

Item {
    id: root

    required property int workspaceId
    required property real workspaceWidth  // This is the scaled monitor width (viewport) * 2
    required property real workspaceHeight
    required property real workspacePadding
    required property real scale_
    required property int monitorId
    required property var monitorData
    required property string barPosition
    required property int barReserved
    required property var windowList
    required property bool isActive
    required property color activeBorderColor
    property string focusedWindowAddress: ""
    property string searchQuery: ""
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1

    // Callbacks for search matching (set by parent)
    property var checkWindowMatched: function(addr) { return false; }
    property var checkWindowSelected: function(addr) { return false; }

    // The visual display width in the overview (actual rendered width of this workspace)
    // This is the SCALED monitor viewport width - the actual visible area
    readonly property real displayWidth: workspaceWidth

    implicitWidth: displayWidth + workspacePadding
    implicitHeight: workspaceHeight + workspacePadding
    
    // Monitor viewport width in real (unscaled) pixels
    // Note: workspaceWidth is already doubled in the overview, so we divide by 2 first
    readonly property real scaledMonitorWidth: workspaceWidth / 2  // The actual scaled monitor width
    readonly property real realMonitorWidth: scaledMonitorWidth / scale_  // Real pixels

    // Filter windows for this workspace and monitor
    readonly property var workspaceWindows: {
        return windowList.filter(win => {
            return win?.workspace?.id === workspaceId && win.monitor === monitorId;
        });
    }

    // Calculate content bounds (min and max X positions of windows) in REAL pixels
    readonly property real minWindowX: {
        if (workspaceWindows.length === 0) return 0;
        let minX = Infinity;
        for (const win of workspaceWindows) {
            const winX = win.at[0] - (monitorData?.x || 0);
            if (winX < minX) minX = winX;
        }
        return minX === Infinity ? 0 : minX;
    }

    readonly property real maxWindowRight: {
        if (workspaceWindows.length === 0) return realMonitorWidth;
        let maxRight = 0;
        for (const win of workspaceWindows) {
            const winRight = (win.at[0] - (monitorData?.x || 0)) + win.size[0];
            if (winRight > maxRight) maxRight = winRight;
        }
        return Math.max(realMonitorWidth, maxRight);
    }

    // Total content width in SCALED pixels
    // From leftmost window (or 0) to rightmost window (or monitor width)
    readonly property real scaledContentWidth: {
        const leftBound = Math.min(0, minWindowX);
        const rightBound = Math.max(realMonitorWidth, maxWindowRight);
        return (rightBound - leftBound) * scale_;
    }
    
    // Offset to apply to window positions (to handle negative X positions)
    readonly property real contentOffsetX: Math.min(0, minWindowX) * scale_ * -1
    
    // Check if there's content outside the visible monitor viewport
    readonly property bool hasContentOutsideViewport: {
        if (workspaceWindows.length === 0) return false;
        for (const win of workspaceWindows) {
            const winX = win.at[0] - (monitorData?.x || 0);
            const winRight = winX + win.size[0];
            if (winX < 0 || winRight > realMonitorWidth) return true;
        }
        return false;
    }
    
    // Find the focused window in this workspace
    readonly property var focusedWindow: {
        if (!focusedWindowAddress) return null;
        return workspaceWindows.find(win => win?.address === focusedWindowAddress) || null;
    }
    
    // Calculate the center X of the focused window (in scaled coordinates within content)
    readonly property real focusedWindowCenterX: {
        if (!focusedWindow) return -1;
        let winX = (focusedWindow.at[0] || 0) - (monitorData?.x || 0);
        if (barPosition === "left") winX -= barReserved;
        const winCenterX = winX + (focusedWindow.size[0] || 0) / 2;
        return (winCenterX * scale_) + contentOffsetX;
    }
    
    // Calculate the center X of all windows in this workspace (for centering when no focus)
    readonly property real windowsCenterX: {
        if (workspaceWindows.length === 0) return scaledMonitorWidth / 2;
        let totalCenterX = 0;
        for (const win of workspaceWindows) {
            let winX = (win.at[0] || 0) - (monitorData?.x || 0);
            if (barPosition === "left") winX -= barReserved;
            totalCenterX += winX + (win.size[0] || 0) / 2;
        }
        return ((totalCenterX / workspaceWindows.length) * scale_) + contentOffsetX;
    }

    // Main workspace container with horizontal scroll
    Rectangle {
        id: workspaceContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: workspaceHeight + workspacePadding
        color: "transparent"
        radius: Styling.radius(1)
        border.width: dropArea.containsDrag ? 2 : 0
        border.color: dropArea.containsDrag ? Colors.outline : "transparent"
        clip: true

        // Wallpaper background
        Image {
            id: workspaceWallpaper
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true

            property string lockscreenFramePath: {
                if (!GlobalStates.wallpaperManager) return "";
                return GlobalStates.wallpaperManager.getLockscreenFramePath(GlobalStates.wallpaperManager.currentWallpaper);
            }
            source: lockscreenFramePath ? "file://" + lockscreenFramePath : ""

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        width: workspaceWallpaper.width
                        height: workspaceWallpaper.height
                        radius: Styling.radius(1)
                    }
                }
            }
        }

        // Semi-transparent overlay
        Rectangle {
            anchors.fill: parent
            radius: Styling.radius(1)
            color: Colors.background
            opacity: 0.3
        }

        // Horizontal flickable for windows tape - drag with left click to navigate
        Flickable {
            id: windowsFlickable
            anchors.fill: parent
            anchors.margins: workspacePadding / 2
            contentWidth: scaledContentWidth
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick
            interactive: true  // Enable drag to scroll
            
            // Auto-scroll to center the focused window (or center of windows)
            Component.onCompleted: scrollToCenter()
            
            function scrollToCenter() {
                let targetCenterX;
                
                if (root.focusedWindow && root.isActive) {
                    // Center on the focused window
                    targetCenterX = root.focusedWindowCenterX;
                } else if (root.workspaceWindows.length > 0) {
                    // Center on the average position of all windows
                    targetCenterX = root.windowsCenterX;
                } else {
                    // Empty workspace - center on monitor viewport
                    targetCenterX = root.contentOffsetX + (root.scaledMonitorWidth / 2);
                }
                
                // Calculate contentX to center the target in the view
                const targetX = targetCenterX - (width / 2);
                contentX = Math.max(0, Math.min(targetX, contentWidth - width));
            }

            // Windows container
            Item {
                id: windowsContainer
                width: windowsFlickable.contentWidth
                height: windowsFlickable.height
                
                // Double-click on empty space to switch workspace
                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    onDoubleTapped: {
                        Hyprland.dispatch(`workspace ${root.workspaceId}`);
                        Visibilities.setActiveModule("", true);
                    }
                }

                // Viewport indicator (shows the actual visible monitor area)
                // Only visible when there are windows outside the monitor viewport
                Rectangle {
                    id: viewportIndicator
                    visible: root.hasContentOutsideViewport
                    x: root.contentOffsetX
                    y: 0
                    width: root.scaledMonitorWidth - workspacePadding
                    height: parent.height
                    color: Colors.loaded ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08) : "transparent"
                    border.width: root.isActive ? 2 : 1
                    border.color: Colors.loaded ? (root.isActive ? Colors.primary : Colors.outline) : "white"
                    opacity: root.isActive ? 0.6 : 0.3
                    radius: Styling.radius(0)
                    z: 0
                }

                Repeater {
                    model: root.workspaceWindows

                    delegate: Item {
                        id: windowDelegate
                        required property var modelData
                        
                        readonly property var windowData: modelData
                        readonly property var toplevel: {
                            const toplevels = ToplevelManager.toplevels.values;
                            return toplevels.find(t => `0x${t.HyprlandToplevel.address}` === windowData.address) || null;
                        }

                        // Position calculations - add contentOffsetX to handle negative positions
                        readonly property real baseX: {
                            let base = (windowData?.at?.[0] || 0) - (monitorData?.x || 0);
                            if (barPosition === "left") base -= barReserved;
                            return (base * scale_) + root.contentOffsetX;
                        }
                        readonly property real baseY: {
                            let base = (windowData?.at?.[1] || 0) - (monitorData?.y || 0);
                            if (barPosition === "top") base -= barReserved;
                            return Math.max(base * scale_, 0);
                        }
                        readonly property real targetWidth: Math.round((windowData?.size[0] || 100) * scale_)
                        readonly property real targetHeight: Math.round((windowData?.size[1] || 100) * scale_)
                        readonly property bool compactMode: targetHeight < 60 || targetWidth < 60
                        readonly property string iconPath: AppSearch.guessIcon(windowData?.class || "")
                        readonly property int calculatedRadius: Styling.radius(-2)
                        readonly property bool isMatched: root.checkWindowMatched(windowData?.address)
                        readonly property bool isSelected: root.checkWindowSelected(windowData?.address)

                        x: baseX
                        y: baseY
                        width: targetWidth
                        height: targetHeight
                        z: dragArea.drag.active ? 1000 : 1

                        property bool hovered: false
                        property bool pressed: false
                        property real initX: baseX
                        property real initY: baseY

                        Drag.active: dragArea.drag.active
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2

                        Behavior on x {
                            enabled: Config.animDuration > 0 && !dragArea.drag.active
                            NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                        }
                        Behavior on y {
                            enabled: Config.animDuration > 0 && !dragArea.drag.active
                            NumberAnimation { duration: Config.animDuration; easing.type: Easing.OutQuart }
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: windowDelegate.calculatedRadius

                            ScreencopyView {
                                id: windowPreview
                                anchors.fill: parent
                                captureSource: Config.performance.windowPreview && GlobalStates.overviewOpen ? windowDelegate.toplevel : null
                                live: GlobalStates.overviewOpen
                                visible: Config.performance.windowPreview
                            }
                        }

                        // Background when no preview
                        Rectangle {
                            id: previewBackground
                            anchors.fill: parent
                            radius: windowDelegate.calculatedRadius
                            color: windowDelegate.pressed ? Colors.surfaceBright : windowDelegate.hovered ? Colors.surface : Colors.background
                            border.color: windowDelegate.isSelected ? Colors.tertiary : windowDelegate.isMatched ? Colors.primary : Colors.primary
                            border.width: windowDelegate.isSelected ? 3 : windowDelegate.isMatched ? 2 : (windowDelegate.hovered ? 2 : 0)
                            visible: !windowPreview.hasContent || !Config.performance.windowPreview

                            Behavior on color {
                                enabled: Config.animDuration > 0
                                ColorAnimation { duration: Config.animDuration / 2 }
                            }
                        }

                        // Icon
                        Image {
                            id: windowIcon
                            readonly property real iconSize: Math.round(Math.min(windowDelegate.targetWidth, windowDelegate.targetHeight) * (windowDelegate.compactMode ? 0.6 : 0.35))
                            anchors.centerIn: parent
                            width: iconSize
                            height: iconSize
                            source: Quickshell.iconPath(windowDelegate.iconPath, "image-missing")
                            sourceSize: Qt.size(iconSize, iconSize)
                            asynchronous: true
                            visible: !windowPreview.hasContent || !Config.performance.windowPreview
                            z: 10
                        }

                        // Overlay when preview is available
                        Rectangle {
                            id: previewOverlay
                            anchors.fill: parent
                            radius: windowDelegate.calculatedRadius
                            color: windowDelegate.pressed ? Qt.rgba(Colors.surfaceContainerHighest.r, Colors.surfaceContainerHighest.g, Colors.surfaceContainerHighest.b, 0.5)
                                 : windowDelegate.hovered ? Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.2)
                                 : "transparent"
                            border.color: windowDelegate.isSelected ? Colors.tertiary : windowDelegate.isMatched ? Colors.primary : Colors.primary
                            border.width: windowDelegate.isSelected ? 3 : windowDelegate.isMatched ? 2 : (windowDelegate.hovered ? 2 : 0)
                            visible: windowPreview.hasContent && Config.performance.windowPreview
                            z: 5
                        }

                        // Corner icon when preview available
                        Image {
                            visible: windowPreview.hasContent && !windowDelegate.compactMode && Config.performance.windowPreview
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: 4
                            width: 16
                            height: 16
                            source: Quickshell.iconPath(windowDelegate.iconPath, "image-missing")
                            sourceSize: Qt.size(16, 16)
                            asynchronous: true
                            opacity: 0.8
                            z: 10
                        }

                        // XWayland indicator
                        Rectangle {
                            visible: windowDelegate.windowData?.xwayland || false
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 2
                            width: 6
                            height: 6
                            radius: 3
                            color: Colors.error
                            z: 10
                        }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            drag.target: parent

                            onEntered: windowDelegate.hovered = true
                            onExited: windowDelegate.hovered = false

                            onPressed: mouse => {
                                windowDelegate.pressed = true;
                                windowDelegate.initX = windowDelegate.x;
                                windowDelegate.initY = windowDelegate.y;
                                root.draggingFromWorkspace = root.workspaceId;
                            }

                            onReleased: mouse => {
                                windowDelegate.pressed = false;
                                const targetWs = root.draggingTargetWorkspace;
                                
                                if (targetWs !== -1 && targetWs !== root.workspaceId) {
                                    Hyprland.dispatch(`movetoworkspacesilent ${targetWs}, address:${windowDelegate.windowData?.address}`);
                                }
                                
                                // Reset position
                                windowDelegate.x = windowDelegate.initX;
                                windowDelegate.y = windowDelegate.initY;
                                root.draggingFromWorkspace = -1;
                                root.draggingTargetWorkspace = -1;
                            }

                            onClicked: mouse => {
                                if (!windowDelegate.windowData) return;
                                if (mouse.button === Qt.LeftButton) {
                                    Hyprland.dispatch(`focuswindow address:${windowDelegate.windowData.address}`);
                                } else if (mouse.button === Qt.MiddleButton) {
                                    Hyprland.dispatch(`closewindow address:${windowDelegate.windowData.address}`);
                                }
                            }

                            onDoubleClicked: mouse => {
                                if (!windowDelegate.windowData) return;
                                if (mouse.button === Qt.LeftButton) {
                                    Visibilities.setActiveModule("", true);
                                    Qt.callLater(() => {
                                        Hyprland.dispatch(`focuswindow address:${windowDelegate.windowData.address}`);
                                    });
                                }
                            }
                        }

                        // Tooltip
                        Rectangle {
                            visible: dragArea.containsMouse && !dragArea.drag.active && windowDelegate.windowData
                            anchors.bottom: parent.top
                            anchors.bottomMargin: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: tooltipText.implicitWidth + 16
                            height: tooltipText.implicitHeight + 8
                            color: Colors.inverseSurface
                            radius: Styling.radius(0) / 2
                            opacity: 0.9
                            z: 1000

                            Text {
                                id: tooltipText
                                anchors.centerIn: parent
                                text: `${windowDelegate.windowData?.title || ""}\n[${windowDelegate.windowData?.class || ""}]${windowDelegate.windowData?.xwayland ? " [XWayland]" : ""}`
                                font.family: Config.theme.font
                                font.pixelSize: 10
                                color: Colors.inverseOnSurface
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }

        // Drop area for window dragging between workspaces
        DropArea {
            id: dropArea
            anchors.fill: parent
            
            onEntered: drag => {
                if (root.draggingFromWorkspace !== root.workspaceId) {
                    root.draggingTargetWorkspace = root.workspaceId;
                }
            }
            
            onExited: {
                if (root.draggingTargetWorkspace === root.workspaceId) {
                    root.draggingTargetWorkspace = -1;
                }
            }
        }
    }
}
