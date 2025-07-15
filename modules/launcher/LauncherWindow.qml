import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../workspaces"

PanelWindow {
    id: root
    
    visible: GlobalStates.launcherOpen
    
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    
    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: GlobalStates.launcherOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    
    color: "transparent"
    
    // Background overlay
    Rectangle {
        anchors.fill: parent
        color: "#80000000" // Semi-transparent black
        opacity: GlobalStates.launcherOpen ? 1 : 0
        visible: opacity > 0
        
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuart }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: GlobalStates.launcherOpen = false
        }
    }
    
    // Launcher content
    Item {
        anchors.centerIn: parent
        width: launcher.width
        height: launcher.height
        
        scale: GlobalStates.launcherOpen ? 1 : 0.8
        opacity: GlobalStates.launcherOpen ? 1 : 0
        
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuart }
        }
        
        LauncherSearch {
            id: launcher
            anchors.centerIn: parent
            
            onItemSelected: {
                GlobalStates.launcherOpen = false
            }
        }
        
        // Drop shadow
        Rectangle {
            anchors.fill: launcher
            anchors.margins: -10
            radius: launcher.radius + 10
            color: "transparent"
            border.color: "#40000000"
            border.width: 10
            z: -1
        }
    }
    
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.launcherOpen = false
        }
    }
}