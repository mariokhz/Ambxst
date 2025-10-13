pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.modules.theme
import qs.modules.components

ToolTip {
    id: root
    property string tooltipText: ""

    background: Rectangle {
        color: Colors.background
        border.width: 2
        border.color: Colors.surfaceBright
        radius: Math.max(0, Config.roundness - 8)
    }
    contentItem: Text {
        anchors.centerIn: parent
        text: root.tooltipText
        color: Colors.overBackground
        font.pixelSize: Config.theme.fontSize
        font.weight: Font.Bold
        font.family: Config.theme.font
    }
}
