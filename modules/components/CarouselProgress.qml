import QtQuick
import qs.config
import qs.modules.theme

Item {
    id: root
    
    property color color: Styling.srItem("overprimary")
    property real dotSize: 4
    property real spacing: 6
    property real speed: 10 // Pixels per second
    property bool running: true
    
    // Default spacing is now handled by targetSpacing
    property bool active: true
    property real targetSpacing: 6
    
    // Base dash length (active state)
    readonly property real baseDashLength: dotSize * 2.5
    
    // Dynamic dash length property
    property real dashLength: active ? baseDashLength : (baseDashLength + targetSpacing + dotSize)
    
    Behavior on dashLength {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.InOutQuad
        }
    }
    
    // Compatibility properties
    property real lineWidth: dotSize
    property real frequency: 0
    property real amplitudeMultiplier: 0
    property real fullLength: 0
    property bool animationsEnabled: true
    
    onLineWidthChanged: dotSize = lineWidth

    clip: true

    Row {
        id: dotRow
        // When inactive, use negative spacing to ensure overlap.
        // The total width (dashLength + spacing) MUST remain constant to avoid visual jumps.
        // Active: base + target
        // Inactive: (base + target + dotSize) + (-dotSize) = base + target
        spacing: root.active ? root.targetSpacing : -root.dotSize
        Behavior on spacing {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.InOutQuad
            }
        }
        
        anchors.verticalCenter: parent.verticalCenter
        
        // Use fixed cycle width for calculations to prevent Repeater changes during animation
        readonly property real stableCycleWidth: root.baseDashLength + root.targetSpacing
        
        // Ensure enough dots to cover width + 1 cycle, plus extra buffer
        readonly property int dotCount: root.width > 0 && stableCycleWidth > 0 ? Math.ceil(root.width / stableCycleWidth) + 4 : 0
        
        Repeater {
            model: dotRow.dotCount
            Rectangle {
                width: root.dashLength
                height: root.dotSize
                radius: height / 2
                color: root.color
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        NumberAnimation on x {
            from: -dotRow.stableCycleWidth
            to: 0
            duration: dotRow.stableCycleWidth > 0 ? (dotRow.stableCycleWidth / root.speed) * 1000 : 1000
            loops: Animation.Infinite
            running: root.running && root.visible && root.animationsEnabled
        }
    }
}
