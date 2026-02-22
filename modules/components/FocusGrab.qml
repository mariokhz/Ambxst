import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.modules.services

Item {
    id: root
    property bool active: false
    property var windows: []
    property int keyboardFocus: WlrKeyboardFocus.OnDemand
    signal cleared()

    // Hyprland specific focus grab
    Loader {
        active: CompositorService.isHyprland
        sourceComponent: HyprlandFocusGrab {
            active: root.active
            windows: root.windows
            onCleared: root.cleared()
        }
    }

    // Generic click-outside detection
    // Monitor the 'active' state of the primary window.
    // When a window loses focus (click outside), Wayland usually sets 'active' to false.
    Connections {
        target: !CompositorService.isHyprland && root.active && root.windows.length > 0 ? root.windows[0] : null
        function onActiveChanged() {
            if (root.active && target && !target.active) {
                // If the window is no longer active while focus grab is active, 
                // it's considered a "clear" event.
                root.cleared();
            }
        }
    }
}
