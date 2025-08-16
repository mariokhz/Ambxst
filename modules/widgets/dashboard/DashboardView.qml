import QtQuick
import qs.modules.widgets.dashboard
import qs.modules.services

Item {
    implicitWidth: 1000
    implicitHeight: 430

    Dashboard {
        id: dashboardItem
        anchors.fill: parent

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                Visibilities.setActiveModule("");
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            Qt.callLater(() => {
                forceActiveFocus();
            });
        }
    }
}
