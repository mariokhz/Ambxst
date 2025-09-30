import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects
import qs.modules.theme
import qs.modules.components
import qs.config

MouseArea {
    id: root

    required property var bar
    required property SystemTrayItem item
    property bool targetMenuOpen: false
    property int trayItemSize: 20

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    Layout.fillHeight: true
    implicitWidth: trayItemSize
    implicitHeight: trayItemSize
    onClicked: event => {
        switch (event.button) {
        case Qt.LeftButton:
            item.activate();
            break;
        case Qt.RightButton:
            if (item.hasMenu) {
                // Posicionar el menú basado en la posición del mouse
                let globalPos = mapToGlobal(event.x, event.y);
                contextMenu.x = globalPos.x;
                contextMenu.y = globalPos.y;
                contextMenu.open();
            }
            break;
        }
        event.accepted = true;
    }

    ContextMenu {
        id: contextMenu
        menuHandle: root.item.menu
    }

    IconImage {
        id: trayIcon
        source: root.item.icon
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        smooth: true
        visible: !Config.tintIcons
    }

    Loader {
        active: Config.tintIcons
        anchors.fill: trayIcon
        sourceComponent: Item {
            Desaturate {
                id: desaturate
                visible: false
                anchors.fill: parent
                source: trayIcon
                desaturation: 0.3
            }
            ColorOverlay {
                anchors.fill: parent
                source: desaturate
                color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2)
            }
        }
    }
}
