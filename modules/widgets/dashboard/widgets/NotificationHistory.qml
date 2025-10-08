import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.components
import qs.modules.services
import qs.modules.notifications
import qs.config

PaneRect {
    color: Colors.surface
    radius: Config.roundness > 0 ? Config.roundness + 4 : 0
    clip: true

    Flickable {
        anchors.fill: parent
        anchors.margins: 4
        contentWidth: width
        contentHeight: notificationList.contentHeight
        clip: true

        ListView {
            id: notificationList
            width: parent.width
            height: contentHeight
            spacing: 4
            model: Notifications.appNameList
            interactive: false
            cacheBuffer: 200
            reuseItems: true

            delegate: NotificationGroup {
                required property int index
                required property string modelData
                width: notificationList.width
                notificationGroup: Notifications.groupsByAppName[modelData]
                expanded: false
                popup: false
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 16
        visible: Notifications.appNameList.length === 0

        Text {
            text: Icons.bellZ
            textFormat: Text.RichText
            font.family: Icons.font
            font.pixelSize: 64
            color: Colors.surfaceBright
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
