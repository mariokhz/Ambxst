import QtQuick
import QtQuick.Effects
import qs.modules.theme
import qs.modules.corners
import qs.modules.components
import qs.config

Item {
    id: root
    required property string position

    visible: Config.bar.showBackground

    readonly property int cornerSize: Config.theme.enableCorners && Config.roundness > 0 ? Styling.radius(4) : 0

    // Calcular offsets para expandir el area y cubrir las corners
    readonly property int leftOffset: (position === "left") ? cornerSize : ((position === "right") ? cornerSize : 0)
    readonly property int rightOffset: (position === "left") ? cornerSize : ((position === "right") ? cornerSize : 0)
    readonly property int topOffset: (position === "top") ? cornerSize : ((position === "bottom") ? cornerSize : 0)
    readonly property int bottomOffset: (position === "top") ? cornerSize : ((position === "bottom") ? cornerSize : 0)

    // StyledRect expandido que cubre bar + corners
    StyledRect {
        id: barBackground
        variant: "barbg"
        radius: 0
        enableBorder: false

        // Expandir para cubrir las corners
        x: position === "right" ? -cornerSize : 0
        y: position === "bottom" ? -cornerSize : 0
        width: root.width + (position === "left" || position === "right" ? cornerSize : 0)
        height: root.height + (position === "top" || position === "bottom" ? cornerSize : 0)

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: barMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }

    // Mascara combinada para la bar + corners
    Item {
        id: barMask
        visible: false
        x: barBackground.x
        y: barBackground.y
        width: barBackground.width
        height: barBackground.height
        layer.enabled: true
        layer.smooth: true

        // Rectangulo central (la bar misma)
        Rectangle {
            id: centerMask
            color: "white"
            x: root.position === "right" ? cornerSize : 0
            y: root.position === "bottom" ? cornerSize : 0
            width: root.width
            height: root.height
        }

        // Corner izquierdo/superior
        Item {
            id: cornerLeftMask
            visible: Config.theme.enableCorners && cornerSize > 0
            width: cornerSize
            height: cornerSize
            x: {
                if (root.position === "left") return root.width + cornerSize;
                if (root.position === "right") return 0;
                return 0;
            }
            y: {
                if (root.position === "top") return root.height;
                if (root.position === "bottom") return 0;
                return 0;
            }

            RoundCorner {
                anchors.fill: parent
                corner: {
                    if (root.position === "top") return RoundCorner.CornerEnum.TopLeft
                    if (root.position === "bottom") return RoundCorner.CornerEnum.BottomLeft
                    if (root.position === "left") return RoundCorner.CornerEnum.TopLeft
                    if (root.position === "right") return RoundCorner.CornerEnum.TopRight
                }
                size: Math.max(cornerSize, 1)
                color: "white"
            }
        }

        // Corner derecho/inferior
        Item {
            id: cornerRightMask
            visible: Config.theme.enableCorners && cornerSize > 0
            width: cornerSize
            height: cornerSize
            x: {
                if (root.position === "left") return root.width + cornerSize;
                if (root.position === "right") return 0;
                return root.width - cornerSize;
            }
            y: {
                if (root.position === "top") return root.height;
                if (root.position === "bottom") return 0;
                return root.height + cornerSize - cornerSize;
            }

            RoundCorner {
                anchors.fill: parent
                corner: {
                    if (root.position === "top") return RoundCorner.CornerEnum.TopRight
                    if (root.position === "bottom") return RoundCorner.CornerEnum.BottomRight
                    if (root.position === "left") return RoundCorner.CornerEnum.BottomLeft
                    if (root.position === "right") return RoundCorner.CornerEnum.BottomRight
                }
                size: Math.max(cornerSize, 1)
                color: "white"
            }
        }
    }
}
