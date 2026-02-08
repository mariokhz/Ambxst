
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

StyledRect {
    id: root
    
    required property bool isOutput

    property var devices: isOutput ? Audio.outputDevices : Audio.inputDevices
    property var currentDevice: isOutput ? Audio.sink : Audio.source
    
    variant: mouseArea.containsMouse ? "focus" : "pane"
    radius: Styling.radius(4)
    implicitHeight: 50
    Layout.fillWidth: true

    Behavior on color {
        enabled: Config.animDuration > 0
        ColorAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Icon
        Text {
            text: root.isOutput ? Icons.speakerHigh : Icons.mic
            font.family: Icons.font
            font.pixelSize: 20
            color: Colors.primary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            // Label
            Text {
                text: root.isOutput ? "Output Device" : "Input Device"
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                font.weight: Font.Bold
                color: Colors.overSurfaceVariant
                opacity: 0.7
            }

            // Device Name
            Text {
                Layout.fillWidth: true
                text: Audio.friendlyDeviceName(root.currentDevice)
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(0)
                color: Colors.overBackground
                elide: Text.ElideRight
            }
        }

        // Cycle Icon
        Text {
            text: Icons.sync
            font.family: Icons.font
            font.pixelSize: 16
            color: Colors.overSurfaceVariant
            opacity: mouseArea.containsMouse ? 1 : 0.5
            
            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.devices.length <= 1) return;
            
            // Find current index
            let currentIndex = -1;
            for (let i = 0; i < root.devices.length; i++) {
                if (root.devices[i] === root.currentDevice) {
                    currentIndex = i;
                    break;
                }
            }
            
            // Calculate next index
            let nextIndex = (currentIndex + 1) % root.devices.length;
            let nextDevice = root.devices[nextIndex];
            
            // Set new device
            if (root.isOutput) {
                Audio.setDefaultSink(nextDevice);
            } else {
                Audio.setDefaultSource(nextDevice);
            }
        }
    }
}
