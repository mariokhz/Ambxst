pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.modules.components
import qs.modules.theme
import qs.modules.services
import qs.modules.globals
import qs.config

PanelWindow {
    id: root

    property ShellScreen targetScreen
    screen: targetScreen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ambxst:osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    WlrLayershell.margins.bottom: 100

    color: "transparent"

    visible: GlobalStates.osdVisible

    // Internal state for responsiveness
    property real osdValue: 0
    property bool osdMuted: false
    
    readonly property int criticalLevel: 10

    // Centering wrapper
    Item {
        anchors.fill: parent

        StyledRect {
            id: osdRect
            variant: (GlobalStates.osdIndicator === "battery" && Battery.percentage < root.criticalLevel && !Battery.isPluggedIn) ? "error" : "popup"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            implicitWidth: 220
            implicitHeight: 52
            radius: Styling.radius(16)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 24
                anchors.topMargin: 8
                anchors.bottomMargin: 8
                spacing: 10

                Text {
                    id: iconText
                    text: {
                        if (GlobalStates.osdIndicator === "volume") {
                            return Audio.volumeIcon(root.osdValue, root.osdMuted);
                        } else if (GlobalStates.osdIndicator === "mic") {
                            return root.osdMuted ? Icons.micSlash : Icons.mic;
                        } else if (GlobalStates.osdIndicator === "battery") {
                            if (Battery.isPluggedIn) return Icons.plug;
                            if (Battery.percentage < 10) return Icons.batteryEmpty;
                            if (Battery.percentage < 30) return Icons.batteryLow;
                            if (Battery.percentage < 70) return Icons.batteryMedium;
                            if (Battery.percentage < 90) return Icons.batteryHigh;
                            return Icons.batteryFull;
                        } else {
                            return Icons.sun;
                        }
                    }
                    font.family: Icons.font
                    font.pixelSize: 22
                    color: osdRect.item
                    Layout.alignment: Qt.AlignVCenter

                    rotation: GlobalStates.osdIndicator === "brightness" ? (root.osdValue * 180) : 0
                    scale: GlobalStates.osdIndicator === "brightness" ? (0.8 + (root.osdValue * 0.2)) : 1

                    Behavior on rotation {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }

                    Behavior on scale {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutQuart
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: {
                                if (GlobalStates.osdIndicator === "volume")
                                    return "Volume";
                                if (GlobalStates.osdIndicator === "mic")
                                    return "Microphone";
                                if (GlobalStates.osdIndicator === "brightness")
                                    return "Brightness";
                                if (GlobalStates.osdIndicator === "battery")
                                    return "Battery";
                                return "";
                            }
                            font.family: Config.theme.font
                            font.pixelSize: 15
                            font.bold: false
                            color: osdRect.item
                            Layout.alignment: Qt.AlignBottom
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: Math.round(root.osdValue * 100)
                            font.family: Config.theme.font
                            font.pixelSize: 15
                            font.bold: false
                            color: osdRect.item
                            Layout.alignment: Qt.AlignBottom
                        }
                    }

                    StyledSlider {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 12
                        value: root.osdValue
                        wavy: false
                        enabled: false
                        thickness: 3
                        handleSpacing: 0
                        progressColor: (GlobalStates.osdIndicator === "battery" && Battery.percentage < root.criticalLevel && !Battery.isPluggedIn) ? osdRect.item : Styling.srItem("overprimary")
                        backgroundColor: (GlobalStates.osdIndicator === "battery" && Battery.percentage < root.criticalLevel && !Battery.isPluggedIn) ? Qt.rgba(osdRect.item.r, osdRect.item.g, osdRect.item.b, 0.2) : Qt.rgba(Colors.overBackground.r, Colors.overBackground.g, Colors.overBackground.b, 0.2)
                        showHandle: GlobalStates.osdIndicator !== "battery"
                    }
                }
            }
        }
    }

    // Close on click or hover
    MouseArea {
        anchors.fill: parent
        onEntered: {
            hideTimer.stop();
            hideTimer.triggered();
        }
        hoverEnabled: true
    }

    Timer {
        id: hideTimer
        interval: 2500
        onTriggered: GlobalStates.osdVisible = false
    }

    Connections {
        target: GlobalStates
        function onOsdVisibleChanged() {
            if (GlobalStates.osdVisible) {
                hideTimer.restart();
            }
        }
    }

    // Services connections - Direct and responsive
    Connections {
        target: Audio
        function onVolumeChanged(volume, muted, node) {
            root.osdValue = volume;
            root.osdMuted = muted;
            GlobalStates.osdIndicator = "volume";
            GlobalStates.osdVisible = true;
            hideTimer.restart();
        }
        function onMicVolumeChanged(volume, muted, node) {
            root.osdValue = volume;
            root.osdMuted = muted;
            GlobalStates.osdIndicator = "mic";
            GlobalStates.osdVisible = true;
            hideTimer.restart();
        }
    }

    Connections {
        target: Brightness
        function onBrightnessChanged(value, screen) {
            // Check if the change happened on THIS screen or if it's a sync change
            if (!screen || !root.targetScreen || screen.name === root.targetScreen.name || Brightness.syncBrightness) {
                root.osdValue = value;
                root.osdMuted = false;
                GlobalStates.osdIndicator = "brightness";
                GlobalStates.osdVisible = true;
                hideTimer.restart();
            }
        }
    }

    Connections {
        target: Battery
        function onIsPluggedInChanged() {
            root.osdValue = Battery.percentage / 100;
            root.osdMuted = false;
            GlobalStates.osdIndicator = "battery";
            GlobalStates.osdVisible = true;
            hideTimer.restart();
        }
        function onPercentageChanged() {
            // Optional: Trigger OSD on low battery?
             if (Battery.percentage < root.criticalLevel && !Battery.isPluggedIn) {
                root.osdValue = Battery.percentage / 100;
                root.osdMuted = false;
                GlobalStates.osdIndicator = "battery";
                GlobalStates.osdVisible = true;
                hideTimer.restart();
             }
        }
    }
}
