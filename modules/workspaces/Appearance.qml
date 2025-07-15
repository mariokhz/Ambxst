pragma Singleton
import QtQuick
import "../theme/"

QtObject {
    readonly property QtObject rounding: QtObject {
        readonly property real global: 16
        readonly property real full: 12
        readonly property real medium: 8
        readonly property real small: 4
    }

    readonly property QtObject font: QtObject {
        readonly property QtObject pixelSize: QtObject {
            readonly property real small: 10
            readonly property real medium: 12
            readonly property real large: 14
        }
    }

    readonly property QtObject colors: QtObject {
        readonly property color colPrimary: Colors.primary
        readonly property color colOnLayer1Inactive: Colors.surfaceBright
    }

    readonly property QtObject m3colors: QtObject {
        readonly property color m3secondaryContainer: Colors.outline
        readonly property color m3onPrimary: Colors.background
        readonly property color m3onSecondaryContainer: Colors.foreground
    }

    readonly property QtObject animation: QtObject {
        readonly property QtObject elementMove: QtObject {
            readonly property Component numberAnimation: Component {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }
        }
        readonly property QtObject elementMoveFast: QtObject {
            readonly property Component numberAnimation: Component {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }
        }
    }
}
