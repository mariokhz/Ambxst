import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../workspaces"
import "../theme"
import "../clock"
import "../systray"

PanelWindow {
    id: panel

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 40
    margins.top: 0
    margins.left: 0
    margins.right: 0

    Rectangle {
        id: bar
        anchors.fill: parent
        color: Colors.background
        radius: 0
        border.color: Colors.outline
        border.width: 0

        Workspaces {
            bar: QtObject {
                property var screen: panel.screen
            }
        }

        Text {
            visible: Hyprland.workspaces.length === 0
            text: "No workspaces"
            color: Colors.foreground
            font.pixelSize: 12
        }
    }
    
    SysTray {
        bar: panel
        anchors {
            right: clockComponent.left
            verticalCenter: parent.verticalCenter
            rightMargin: 16
        }
    }
    
    Clock {
        id: clockComponent
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 16
        }
    }
}
