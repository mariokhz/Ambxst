
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.config

ColumnLayout {
    id: root
    
    required property bool isOutput

    property var devices: isOutput ? Audio.outputDevices : Audio.inputDevices
    property var currentDevice: isOutput ? Audio.sink : Audio.source
    property bool expanded: false
    
    Layout.fillWidth: true
    spacing: 4

    // Main Button
    StyledRect {
        id: mainButton
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        
        variant: mouseArea.containsMouse ? "focus" : "pane"
        radius: Styling.radius(4)

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

            // Arrow Icon
            Text {
                text: root.expanded ? Icons.chevronUp : Icons.chevronDown
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
                if (root.devices.length > 1) {
                    root.expanded = !root.expanded;
                }
            }
        }
    }

    // Expandable List
    ClippingRectangle {
        id: listContainer
        Layout.fillWidth: true
        Layout.preferredHeight: root.expanded ? (Math.min(root.devices.length, 5) * 40) : 0
        color: Colors.background
        radius: Styling.radius(4)
        opacity: root.expanded ? 1 : 0
        visible: Layout.preferredHeight > 0

        Behavior on Layout.preferredHeight {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutQuart
            }
        }

        ListView {
            id: devicesListView
            anchors.fill: parent
            clip: true
            model: root.devices
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            
            delegate: Item {
                required property var modelData
                required property int index

                width: devicesListView.width
                height: 40

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    color: (root.currentDevice === modelData) ? Colors.primary : "transparent"
                    radius: Styling.radius(4)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12


                        Text {
                            text: root.isOutput ? Icons.speakerHigh : Icons.mic
                            font.family: Icons.font
                            font.pixelSize: 16
                            color: (root.currentDevice === modelData) ? Styling.srItem("primary") : Colors.overSurface
                        }

                        Text {
                            Layout.fillWidth: true
                            text: Audio.friendlyDeviceName(modelData)
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: (root.currentDevice === modelData) ? Font.Bold : Font.Normal
                            color: (root.currentDevice === modelData) ? Styling.srItem("primary") : Colors.overSurface
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: root.currentDevice === modelData
                            text: Icons.check
                            font.family: Icons.font
                            font.pixelSize: 16
                            color: Styling.srItem("primary")
                        }
                    }

                    HoverHandler {
                        id: itemHover
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        color: Colors.overSurface
                        opacity: itemHover.hovered ? 0.1 : 0
                        radius: Styling.radius(4)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isOutput) {
                                Audio.setDefaultSink(modelData);
                            } else {
                                Audio.setDefaultSource(modelData);
                            }
                            root.expanded = false;
                        }
                    }
                }
            }
        }
    }
}
