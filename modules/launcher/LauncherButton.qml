import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../workspaces"

Button {
    id: root
    
    implicitWidth: 36
    implicitHeight: 36
    
    background: Rectangle {
        color: root.pressed ? Colors.primary : (root.hovered ? Colors.surface : "transparent")
        radius: 8
        border.color: root.hovered ? Colors.outline : "transparent"
        border.width: 1
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }
    
    contentItem: Text {
        text: "⚬"
        font.pixelSize: 20
        color: root.pressed ? Colors.onPrimary : Colors.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    onClicked: {
        // Toggle launcher
        GlobalStates.launcherOpen = !GlobalStates.launcherOpen
    }
    
    ToolTip.visible: hovered
    ToolTip.text: "Open Application Launcher"
    ToolTip.delay: 1000
}