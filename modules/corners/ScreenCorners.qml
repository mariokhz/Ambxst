import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.modules.services
import qs.modules.services.compositor

PanelWindow {
    id: screenCorners

    readonly property var monitor: Hyprland.monitorFor(screen);

    // Fullscreen detection
    readonly property bool activeWindowFullscreen: {
        if (!monitor)
            return false;

        const activeWorkspaceId = monitor.activeWorkspace.id;
        const monId = monitor.id;

        // Check active toplevel first (fast path)
        const toplevel = ToplevelManager.activeToplevel;
        if (toplevel && toplevel.fullscreen && Hyprland.focusedMonitor.id === monId) {
            return true;
        }

        // Check all windows on this monitor (robust path)
        const wins = CompositorService.windowList;
        for (let i = 0; i < wins.length; i++) {
            if (wins[i].output === monitor.name && wins[i].fullscreen && wins[i].workspaceId === activeWorkspaceId) {
                return true;
            }
        }
        return false;
    }

    visible: Config.theme.enableCorners && Config.roundness > 0 && !activeWindowFullscreen

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "ambxst:screenCorners"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {
        item: null
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    ScreenCornersContent {
        id: cornersContent
        anchors.fill: parent
        hasFullscreenWindow: screenCorners.activeWindowFullscreen
    }
}
