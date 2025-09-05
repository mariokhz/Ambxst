import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.modules.widgets.overview
import qs.modules.notch
import qs.modules.widgets.wallpapers
import qs.config

NotchAnimationBehavior {
    id: root

    property var state: QtObject {
        property int currentTab: 0
    }

    readonly property var tabModel: ["", "", "", "", ""]
    readonly property int tabCount: tabModel.length
    readonly property int tabSpacing: 8

    readonly property int tabWidth: 48
    readonly property real nonAnimWidth: 400 + tabWidth + 16 // contenido + pestañas + spacing

    implicitWidth: nonAnimWidth
    implicitHeight: 430 // Altura fija para el dashboard vertical

    // Usar el comportamiento estándar de animaciones del notch
    isVisible: GlobalStates.dashboardOpen

    Row {
        id: mainLayout
        anchors.fill: parent
        spacing: 8

        // Tab buttons
        Item {
            id: tabsContainer
            width: root.tabWidth
            height: parent.height

            // Background highlight que se desplaza verticalmente
            Rectangle {
                id: tabHighlight
                width: parent.width
                height: width
                // height: (parent.height - root.tabSpacing * (root.tabCount - 1)) / root.tabCount
                x: 0
                y: root.state.currentTab * (height + root.tabSpacing)
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, Config.opacity)
                radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                z: 0

                Behavior on y {
                    NumberAnimation {
                        duration: Config.animDuration
                        easing.type: Easing.OutQuart
                    }
                }
            }

            Column {
                id: tabs
                anchors.fill: parent
                spacing: root.tabSpacing

                Repeater {
                    model: root.tabModel

                    Button {
                        required property int index
                        required property string modelData

                        text: modelData
                        flat: true
                        width: tabsContainer.width
                        height: width
                        // implicitHeight: (tabsContainer.height - root.tabSpacing * (root.tabCount - 1)) / root.tabCount

                        background: Rectangle {
                            color: "transparent"
                            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                        }

                        contentItem: Text {
                            text: parent.text
                            color: root.state.currentTab === index ? Colors.adapter.primary : Colors.adapter.overBackground
                            // font.family: Config.theme.font
                            font.family: Icons.font
                            // font.pixelSize: Config.theme.fontSize
                            font.pixelSize: 20
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        onClicked: root.state.currentTab = index

                        Behavior on scale {
                            NumberAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutCubic
                            }
                        }

                        states: State {
                            name: "pressed"
                            when: parent.pressed
                            PropertyChanges {
                                target: parent
                                scale: 0.95
                            }
                        }
                    }
                }
            }
        }

        // Content area
        PaneRect {
            id: viewWrapper

            width: parent.width - root.tabWidth - 8 // Resto del ancho disponible
            height: parent.height

            radius: Config.roundness > 0 ? Config.roundness + 4 : 0
            clip: true

            SwipeView {
                id: view

                anchors.fill: parent
                orientation: Qt.Vertical

                currentIndex: root.state.currentTab

                onCurrentIndexChanged: {
                    root.state.currentTab = currentIndex;
                    // Auto-focus search input when switching to wallpapers tab
                    if (currentIndex === 3) {
                        Qt.callLater(() => {
                            if (wallpapersPane.item && wallpapersPane.item.focusSearch) {
                                wallpapersPane.item.focusSearch();
                            }
                        });
                    }
                }

                // Overview Tab
                DashboardPane {
                    sourceComponent: overviewComponent
                }

                // System Tab
                DashboardPane {
                    sourceComponent: systemComponent
                }

                // Quick Settings Tab
                DashboardPane {
                    sourceComponent: quickSettingsComponent
                }

                // Wallpapers Tab
                DashboardPane {
                    id: wallpapersPane
                    sourceComponent: wallpapersComponent
                }

                // Assistant Tab
                DashboardPane {
                    id: assistantPane
                    sourceComponent: assistantComponent
                }
            }
        }
    }

    // Animated size properties for smooth transitions
    property real animatedWidth: implicitWidth
    property real animatedHeight: implicitHeight

    width: animatedWidth
    height: animatedHeight

    // Update animated properties when implicit properties change
    onImplicitWidthChanged: animatedWidth = implicitWidth
    onImplicitHeightChanged: animatedHeight = implicitHeight

    Behavior on animatedWidth {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    Behavior on animatedHeight {
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutBack
            easing.overshoot: 1.1
        }
    }

    // Component definitions for better performance (defined once, reused)
    Component {
        id: overviewComponent
        OverviewTab {}
    }

    Component {
        id: systemComponent
        SystemTab {}
    }

    Component {
        id: quickSettingsComponent
        QuickSettingsTab {}
    }

    Component {
        id: wallpapersComponent
        WallpapersTab {}
    }

    Component {
        id: assistantComponent
        AssistantTab {}
    }
}
