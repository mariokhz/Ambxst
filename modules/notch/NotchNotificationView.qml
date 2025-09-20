import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.modules.theme
import qs.modules.services
import qs.modules.globals
import qs.modules.components
import qs.modules.notifications
import qs.config

Item {
    id: root

    implicitWidth: hovered ? 420 : 320
    implicitHeight: {
        let baseHeight = hovered ? contentItem.height + 12 : 40;  // Altura base para icono y textos
        let actionsHeight = 0;

        if (hovered && currentNotification && currentNotification.actions.length > 0) {
            actionsHeight = 40;  // Altura para botones de acción + márgenes
        }

        let controlsHeight = hovered ? dashboardAccessHeight : 0;

        return baseHeight + actionsHeight + controlsHeight;
    }

    property var currentNotification: Notifications.popupList.length > 0 ? Notifications.popupList[0] : null
    property bool notchHovered: false  // Propiedad para recibir hover del notch completo
    property bool hovered: notchHovered || mouseArea.containsMouse || anyButtonHovered
    property bool anyButtonHovered: false
    property int dashboardAccessHeight: 24

    // MouseArea para detectar hover en toda el área
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: -1  // Detrás de elementos interactivos
    }

    // Manejo del hover - pausa/reanuda timers de timeout de notificación
    onHoveredChanged: {
        if (hovered) {
            // Pausar timer de timeout de la notificación
            if (currentNotification) {
                Notifications.pauseGroupTimers(currentNotification.appName);
            }
        } else {
            // Reanudar timer de timeout de la notificación
            if (currentNotification) {
                Notifications.resumeGroupTimers(currentNotification.appName);
            }
        }
    }

    // Vista única de la notificación
    Column {
        anchors.fill: parent

        // Fila de control superior con revealer
        Item {
            width: parent.width
            height: hovered ? dashboardAccessHeight : 0
            clip: true

            Behavior on height {
                NumberAnimation {
                    duration: Config.animDuration / 2
                    easing.type: Easing.OutQuart
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.topMargin: 0
                spacing: 8

                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutQuart
                    }
                }

                // Botón de copiar (izquierda)
                Button {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 40
                    text: "📋"
                    hoverEnabled: true

                    onHoveredChanged: {
                        root.anyButtonHovered = hovered;
                    }

                    background: Rectangle {
                        color: parent.pressed ? Colors.adapter.primary : (parent.hovered ? Colors.surfaceBright : "transparent")
                        radius: 8

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        font.family: Config.theme.font
                        font.pixelSize: 10
                        color: parent.pressed ? Colors.adapter.overPrimary : (parent.hovered ? Colors.adapter.overBackground : Colors.adapter.outline)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                    }

                    onClicked: {
                        if (currentNotification) {
                            console.log("Copy:", currentNotification.body);
                            // TODO: Implementar copia al portapapeles
                        }
                    }
                }

                // Rectángulo de acceso al dashboard (centro)
                Rectangle {
                    id: dashboardAccess
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: dashboardAccessMouse.containsMouse ? Colors.adapter.primary : "transparent"
                    radius: 8

                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration / 2
                        }
                    }

                    MouseArea {
                        id: dashboardAccessMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        propagateComposedEvents: true

                        onHoveredChanged: {
                            root.anyButtonHovered = containsMouse;
                        }

                        onClicked: {
                            GlobalStates.dashboardCurrentTab = 0;
                            Visibilities.setActiveModule("dashboard");
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Icons.caretDown
                        font.family: Icons.font
                        font.pixelSize: 16
                        color: dashboardAccessMouse.containsMouse ? Colors.adapter.overPrimary : Colors.adapter.outline

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                    }
                }

                // Botón de descartar (derecha)
                Button {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 40
                    text: "✕"
                    hoverEnabled: true

                    onHoveredChanged: {
                        root.anyButtonHovered = hovered;
                    }

                    background: Rectangle {
                        color: parent.pressed ? Colors.adapter.error : (parent.hovered ? Colors.surfaceBright : "transparent")
                        radius: 8

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                    }

                    contentItem: Text {
                        text: parent.text
                        font.family: Config.theme.font
                        font.pixelSize: 10
                        color: parent.pressed ? Colors.adapter.overError : (parent.hovered ? Colors.adapter.overBackground : Colors.adapter.error)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                    }

                    onClicked: {
                        if (currentNotification) {
                            Notifications.discardNotification(currentNotification.id);
                        }
                    }
                }
            }
        }

        // Contenido principal de la notificación
        Item {
            id: contentItem
            width: parent.width
            height: parent.height

            Column {
                anchors.fill: parent
                anchors.margins: 0
                anchors.topMargin: hovered ? 8 : 0
                spacing: hovered ? 8 : 0

                Behavior on anchors.leftMargin {
                    NumberAnimation {
                        duration: Config.animDuration / 2
                    }
                }
                Behavior on anchors.rightMargin {
                    NumberAnimation {
                        duration: Config.animDuration / 2
                    }
                }
                Behavior on anchors.topMargin {
                    NumberAnimation {
                        duration: Config.animDuration / 2
                    }
                }
                Behavior on anchors.bottomMargin {
                    NumberAnimation {
                        duration: Config.animDuration / 2
                    }
                }
                Behavior on spacing {
                    NumberAnimation {
                        duration: Config.animDuration / 2
                    }
                }

                // Fila principal: icono + textos
                RowLayout {
                    width: parent.width
                    spacing: 8

                    Behavior on spacing {
                        NumberAnimation {
                            duration: Config.animDuration / 2
                        }
                    }

                    // App icon (izquierda)
                    NotificationAppIcon {
                        Layout.preferredWidth: hovered ? 48 : 36
                        Layout.preferredHeight: hovered ? 48 : 36
                        size: hovered ? 48 : 36
                        visible: currentNotification && (currentNotification.appIcon !== "" || currentNotification.image !== "")
                        appIcon: currentNotification ? currentNotification.appIcon : ""
                        image: currentNotification ? currentNotification.image : ""
                        summary: currentNotification ? currentNotification.summary : ""
                        urgency: currentNotification ? currentNotification.urgency : NotificationUrgency.Normal

                        Behavior on size {
                            NumberAnimation {
                                duration: Config.animDuration / 2
                            }
                        }
                    }

                    // Textos de la notificación
                    Column {
                        Layout.fillWidth: true
                        spacing: hovered ? 2 : 1

                        Behavior on spacing {
                            NumberAnimation {
                                duration: Config.animDuration / 2
                            }
                        }

                        Text {
                            width: parent.width
                            text: currentNotification ? currentNotification.summary : ""
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize
                            font.weight: Font.Bold
                            color: Colors.adapter.primary
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: currentNotification ? processNotificationBody(currentNotification.body, currentNotification.appName) : ""
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize - 1
                            color: Colors.adapter.overBackground
                            wrapMode: Text.Wrap
                            maximumLineCount: hovered ? 3 : 2
                            elide: Text.ElideRight
                        }
                    }
                }

                // Botones de acción con revealer (fila separada)
                Item {
                    width: parent.width
                    height: (hovered && currentNotification && currentNotification.actions.length > 0) ? 28 : 0
                    clip: true
                    visible: height > 0

                    Behavior on height {
                        NumberAnimation {
                            duration: Config.animDuration / 2
                            easing.type: Easing.OutQuart
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 6

                        Repeater {
                            model: currentNotification ? currentNotification.actions : []

                            Button {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28

                                text: modelData.text
                                font.family: Config.theme.font
                                font.pixelSize: Config.theme.fontSize - 2
                                hoverEnabled: true

                                onHoveredChanged: {
                                    root.anyButtonHovered = hovered;
                                }

                                background: Rectangle {
                                    color: parent.pressed ? Colors.adapter.primary : (parent.hovered ? Colors.surfaceBright : Colors.surfaceContainerHigh)
                                    radius: Config.roundness

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Config.animDuration / 2
                                        }
                                    }
                                }

                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: parent.pressed ? Colors.adapter.overPrimary : (parent.hovered ? Colors.adapter.overBackground : Colors.adapter.primary)
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Config.animDuration / 2
                                        }
                                    }
                                }

                                onClicked: {
                                    Notifications.attemptInvokeAction(currentNotification.id, modelData.identifier);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Función auxiliar para procesar el cuerpo de la notificación
    function processNotificationBody(body, appName) {
        if (!body)
            return "";

        let processedBody = body;

        // Limpiar notificaciones de navegadores basados en Chromium
        if (appName) {
            const lowerApp = appName.toLowerCase();
            const chromiumBrowsers = ["brave", "chrome", "chromium", "vivaldi", "opera", "microsoft edge"];

            if (chromiumBrowsers.some(name => lowerApp.includes(name))) {
                const lines = body.split('\n\n');

                if (lines.length > 1 && lines[0].startsWith('<a')) {
                    processedBody = lines.slice(1).join('\n\n');
                }
            }
        }

        return processedBody.replace(/\n/g, " ");
    }
}
