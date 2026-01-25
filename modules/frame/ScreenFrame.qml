import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.modules.components
import qs.modules.corners
import qs.modules.services
import qs.config

Item {
    id: root

    required property ShellScreen targetScreen

    readonly property bool frameEnabled: Config.bar?.frameEnabled ?? false
    readonly property int thickness: {
        // Always return valid number for corners, even if frame is disabled
        const value = Config.bar?.frameThickness;
        if (typeof value !== "number")
            return 6;
        return Math.max(1, Math.min(Math.round(value), 40));
    }
    readonly property int actualFrameSize: frameEnabled ? thickness : 0
    readonly property int innerRadius: Math.max(Config.roundness + 4, thickness * 2)

    Item {
        id: noInputRegion
        width: 0
        height: 0
        visible: false
    }

    PanelWindow {
        id: topFrame
        screen: root.targetScreen
        visible: root.frameEnabled
        implicitHeight: root.actualFrameSize
        color: "transparent"
        anchors {
            left: true
            right: true
            top: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:top"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: root.actualFrameSize
        mask: Region { item: noInputRegion }
    }

    PanelWindow {
        id: bottomFrame
        screen: root.targetScreen
        visible: root.frameEnabled
        implicitHeight: root.actualFrameSize
        color: "transparent"
        anchors {
            left: true
            right: true
            bottom: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:bottom"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: root.actualFrameSize
        mask: Region { item: noInputRegion }
    }

    PanelWindow {
        id: leftFrame
        screen: root.targetScreen
        visible: root.frameEnabled
        implicitWidth: root.actualFrameSize
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:left"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: root.actualFrameSize
        mask: Region { item: noInputRegion }
    }

    PanelWindow {
        id: rightFrame
        screen: root.targetScreen
        visible: root.frameEnabled
        implicitWidth: root.actualFrameSize
        color: "transparent"
        anchors {
            top: true
            bottom: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:right"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: root.actualFrameSize
        mask: Region { item: noInputRegion }
    }

    PanelWindow {
        id: frameOverlay
        screen: root.targetScreen
        visible: root.frameEnabled
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:screenFrame:overlay"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        mask: Region { item: noInputRegion }

        // Frame Masking Logic - Restored to ensure hollow center
        StyledRect {
            id: frameFill
            anchors.fill: parent
            variant: "bg"
            radius: 0
            enableBorder: false
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: frameMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }

        Item {
            id: frameMask
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Canvas {
                id: frameCanvas
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    const ctx = getContext("2d");
                    const w = width;
                    const h = height;
                    const t = root.thickness;
                    // Use innerRadius for the cutout
                    const r = Math.min(root.innerRadius, Math.min(w, h) / 2);

                    ctx.clearRect(0, 0, w, h);
                    if (w <= 0 || h <= 0 || t <= 0)
                        return;

                    // Draw outer rectangle (opaque)
                    ctx.fillStyle = "white";
                    ctx.fillRect(0, 0, w, h);

                    // Cut out the inner rectangle
                    const innerX = t;
                    const innerY = t;
                    const innerW = w - t * 2;
                    const innerH = h - t * 2;
                    if (innerW <= 0 || innerH <= 0)
                        return;

                    ctx.globalCompositeOperation = "destination-out";
                    
                    // Draw rounded rect path for cutout
                    const rr = Math.min(r, innerW / 2, innerH / 2);
                    ctx.beginPath();
                    ctx.moveTo(innerX + rr, innerY);
                    ctx.arcTo(innerX + innerW, innerY, innerX + innerW, innerY + innerH, rr);
                    ctx.arcTo(innerX + innerW, innerY + innerH, innerX, innerY + innerH, rr);
                    ctx.arcTo(innerX, innerY + innerH, innerX, innerY, rr);
                    ctx.arcTo(innerX, innerY, innerX + innerW, innerY, rr);
                    ctx.closePath();
                    ctx.fill();

                    ctx.globalCompositeOperation = "source-over";
                }
            }
        }

        Connections {
            target: root
            function onThicknessChanged() { frameCanvas.requestPaint(); }
            function onInnerRadiusChanged() { frameCanvas.requestPaint(); }
        }

        onWidthChanged: frameCanvas.requestPaint()
        onHeightChanged: frameCanvas.requestPaint()
    }
}
