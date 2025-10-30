import QtQuick
import QtQuick.Layouts
import qs.modules.services
import qs.modules.components
import qs.modules.theme

Item {
    id: root

    required property var bar

    property bool vertical: bar.orientation === "vertical"
    property bool isHovered: false
    property bool mainHovered: false
    property bool iconHovered: false
    property bool externalBrightnessChange: false

    property real iconRotation: (brightnessSlider.value / 1.0) * 180
    property real iconScale: 0.8 + (brightnessSlider.value / 1.0) * 0.2

    property bool layerEnabled: true

    function updateSliderFromMonitor(forceAnimation: bool): void {
        if (!currentMonitor || !currentMonitor.ready || brightnessSlider.isDragging)
            return;
        brightnessSlider.value = currentMonitor.brightness;
        if (forceAnimation) {
            root.externalBrightnessChange = true;
            externalChangeTimer.restart();
        }
    }

    Behavior on iconRotation {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }
    Behavior on iconScale {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        onHoveredChanged: {
            root.mainHovered = hovered;
            root.isHovered = root.mainHovered || root.iconHovered;
        }
    }

    implicitWidth: root.vertical ? 4 : 80
    implicitHeight: root.vertical ? 80 : 4
    Layout.preferredWidth: root.vertical ? 4 : 80
    Layout.preferredHeight: root.vertical ? 80 : 4

    states: [
        State {
            name: "hovered"
            when: root.isHovered || brightnessSlider.isDragging || root.externalBrightnessChange
            PropertyChanges {
                target: root
                implicitWidth: root.vertical ? 4 : 128
                implicitHeight: root.vertical ? 128 : 4
                Layout.preferredWidth: root.vertical ? 4 : 128
                Layout.preferredHeight: root.vertical ? 128 : 4
            }
        }
    ]

    transitions: Transition {
        NumberAnimation {
            properties: "implicitWidth,implicitHeight,Layout.preferredWidth,Layout.preferredHeight"
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Layout.fillWidth: root.vertical
    Layout.fillHeight: !root.vertical

    property var currentMonitor: Brightness.getMonitorForScreen(bar.screen)

    Component.onCompleted: updateSliderFromMonitor(false)

    onCurrentMonitorChanged: updateSliderFromMonitor(false)

    BgRect {
        anchors.fill: parent
        layer.enabled: root.layerEnabled

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                root.mainHovered = true;
                root.isHovered = root.mainHovered || root.iconHovered;
            }
            onExited: {
                root.mainHovered = false;
                root.isHovered = root.mainHovered || root.iconHovered;
            }
            onWheel: wheel => {
                if (wheel.angleDelta.y > 0) {
                    brightnessSlider.value = Math.min(1, brightnessSlider.value + 0.1);
                } else {
                    brightnessSlider.value = Math.max(0, brightnessSlider.value - 0.1);
                }
            }
        }

        StyledSlider {
            id: brightnessSlider
            anchors.fill: parent
            anchors.margins: 8
            anchors.rightMargin: root.vertical ? 8 : 16
            anchors.topMargin: root.vertical ? 16 : 8
            vertical: root.vertical
            smoothDrag: true
            value: 0
            resizeParent: false
            wavy: true
            wavyAmplitude: (root.isHovered || isDragging || root.externalBrightnessChange) ? (1.5 * value) : 0
            wavyFrequency: (root.isHovered || isDragging || root.externalBrightnessChange) ? (8.0 * value) : 0
            iconPos: root.vertical ? "end" : "start"
            icon: Icons.sun
            iconRotation: root.iconRotation
            iconScale: root.iconScale
            progressColor: Colors.primary

            onValueChanged: {
                if (currentMonitor && currentMonitor.ready) {
                    currentMonitor.setBrightness(value);
                }
            }

            onIconClicked: {}

            Connections {
                target: currentMonitor
                ignoreUnknownSignals: true
                function onBrightnessChanged() {
                    root.updateSliderFromMonitor(true);
                }
                function onReadyChanged() {
                    root.updateSliderFromMonitor(false);
                }
            }

            Connections {
                target: brightnessSlider
                function onIconHovered(hovered) {
                    root.iconHovered = hovered;
                    root.isHovered = root.mainHovered || root.iconHovered;
                }
            }
        }

        Timer {
            id: externalChangeTimer
            interval: 1000
            onTriggered: root.externalBrightnessChange = false
        }
    }
}
