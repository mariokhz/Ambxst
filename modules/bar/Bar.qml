import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../workspaces"
import "../theme"
import "../clock"
import "../systray"
import "../launcher"

PanelWindow {
    id: panel

    anchors {
        top: true
        left: true
        right: true
    }

    color: "transparent"

    implicitHeight: 44

    Rectangle {
        id: bar
        anchors.fill: parent
        anchors.centerIn: parent
        anchors.margins: 0
        color: "transparent"
        radius: 0
        border.color: Colors.outline
        border.width: 0

        RowLayout {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 4
            spacing: 4

            LauncherButton {
                id: launcherButton
            }

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

            Item {
                Layout.fillWidth: true
            }

            SysTray {
                bar: panel
            }

            Clock {
                id: clockComponent
            }
        }
    }
}
