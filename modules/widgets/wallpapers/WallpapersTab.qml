import QtQuick
import QtQuick.Controls
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

Rectangle {
    color: Colors.background
    anchors.fill: parent
    anchors.margins: 4
    radius: Config.roundness > 0 ? Config.roundness : 0

    property string searchText: ""
    readonly property int gridRows: 3
    readonly property int gridColumns: 5

    function focusSearch() {
        wallpaperSearchInput.focusInput();
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            focusSearch();
        });
    }

    property var filteredWallpapers: {
        if (!GlobalStates.wallpaperManager)
            return [];
        if (searchText.length === 0)
            return GlobalStates.wallpaperManager.wallpaperPaths;

        return GlobalStates.wallpaperManager.wallpaperPaths.filter(function (path) {
            const fileName = path.split('/').pop().toLowerCase();
            return fileName.includes(searchText.toLowerCase());
        });
    }

    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Sidebar izquierdo con search y opciones
        Column {
            width: parent.width - wallpaperGridContainer.width - 8  // Expandir para llenar el espacio restante
            height: parent.height + 4
            spacing: 8

            // Barra de búsqueda
            SearchInput {
                id: wallpaperSearchInput
                width: parent.width
                text: searchText
                placeholderText: "Search wallpapers..."
                iconText: ""
                clearOnEscape: false
                radius: Config.roundness > 0 ? Config.roundness - 8 : 0

                onSearchTextChanged: text => {
                    searchText = text;
                }

                onEscapePressed: {
                    Visibilities.setActiveModule("");
                }
            }

            // Área placeholder para opciones futuras
            Rectangle {
                width: parent.width
                height: parent.height - 36 - 16
                color: Colors.surfaceContainer
                radius: Config.roundness > 0 ? Config.roundness : 0
                border.color: Colors.adapter.outline
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "Placeholder\nfor future\noptions"
                    color: Colors.adapter.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.2
                }
            }
        }

        // Grid de wallpapers a la derecha
        Rectangle {
            id: wallpaperGridContainer
            width: wallpaperWidth * gridColumns
            height: parent.height
            color: Colors.surfaceContainer
            radius: Config.roundness > 0 ? Config.roundness : 0
            border.color: Colors.adapter.outline
            border.width: 0
            clip: true

            readonly property int wallpaperHeight: height / gridRows
            readonly property int wallpaperWidth: wallpaperHeight  // Mantener cuadrados

            ScrollView {
                id: scrollView
                anchors.fill: parent

                GridView {
                    id: wallpaperGrid
                    width: parent.width
                    cellWidth: wallpaperGridContainer.wallpaperWidth
                    cellHeight: wallpaperGridContainer.wallpaperHeight
                    model: filteredWallpapers

                    delegate: Rectangle {
                        width: wallpaperGridContainer.wallpaperWidth
                        height: wallpaperGridContainer.wallpaperHeight
                        color: Colors.surface

                        property bool isCurrentWallpaper: {
                            if (!GlobalStates.wallpaperManager)
                                return false;
                            return GlobalStates.wallpaperManager.currentWallpaper === modelData;
                        }

                        property bool isHovered: false

                        Loader {
                            anchors.fill: parent
                            sourceComponent: {
                                if (!GlobalStates.wallpaperManager)
                                    return null;

                                var fileType = GlobalStates.wallpaperManager.getFileType(modelData);
                                if (fileType === 'image') {
                                    return staticImageComponent;
                                } else if (fileType === 'gif') {
                                    return animatedImageComponent;
                                }
                                return staticImageComponent; // fallback
                            }

                            property string sourceFile: modelData
                        }

                        // Etiqueta "CURRENT" para wallpaper actual
                        Rectangle {
                            visible: parent.isCurrentWallpaper
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 24
                            color: Colors.adapter.surfaceContainerLowest

                            Text {
                                anchors.centerIn: parent
                                text: "CURRENT"
                                color: Colors.adapter.primary
                                font.family: Config.theme.font
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                        }

                        Component {
                            id: staticImageComponent
                            Image {
                                source: parent.sourceFile ? "file://" + parent.sourceFile : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                            }
                        }

                        Component {
                            id: animatedImageComponent
                            AnimatedImage {
                                source: parent.sourceFile ? "file://" + parent.sourceFile : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                playing: false  // Solo se anima al hacer hover
                            }
                        }

                        // Etiqueta con nombre del archivo al hacer hover
                        Rectangle {
                            visible: parent.isHovered && !parent.isCurrentWallpaper
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 24
                            color: Colors.adapter.surfaceContainerLowest
                            z: 10
                            clip: true

                            Text {
                                id: hoverText
                                anchors.verticalCenter: parent.verticalCenter
                                x: 4
                                text: modelData ? modelData.split('/').pop() : ""
                                color: Colors.adapter.overBackground
                                font.family: Config.theme.font
                                font.pixelSize: 14

                                readonly property bool needsScroll: width > parent.width - 8

                                SequentialAnimation {
                                    id: scrollAnimation
                                    running: hoverText.needsScroll && parent.visible
                                    loops: Animation.Infinite

                                    PauseAnimation {
                                        duration: 1000
                                    }
                                    NumberAnimation {
                                        target: hoverText
                                        property: "x"
                                        to: hoverText.parent.width - hoverText.width - 4
                                        duration: 2000
                                        easing.type: Easing.InOutQuad
                                    }
                                    PauseAnimation {
                                        duration: 1000
                                    }
                                    NumberAnimation {
                                        target: hoverText
                                        property: "x"
                                        to: 4
                                        duration: 2000
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                            }

                            onVisibleChanged: {
                                if (visible) {
                                    hoverText.x = 4;
                                    if (hoverText.needsScroll) {
                                        scrollAnimation.restart();
                                    }
                                } else {
                                    scrollAnimation.stop();
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                parent.isHovered = true;
                                if (!parent.isCurrentWallpaper) {
                                    parent.color = Colors.surfaceContainerHigh;
                                }
                                // Activar animación de GIF al hacer hover
                                var loader = parent.children[0]; // El Loader
                                if (loader && loader.item && loader.item.hasOwnProperty('playing')) {
                                    loader.item.playing = true;
                                }
                            }
                            onExited: {
                                parent.isHovered = false;
                                if (!parent.isCurrentWallpaper) {
                                    parent.color = Colors.surface;
                                }
                                // Desactivar animación de GIF al salir del hover
                                var loader = parent.children[0]; // El Loader
                                if (loader && loader.item && loader.item.hasOwnProperty('playing')) {
                                    loader.item.playing = false;
                                }
                            }
                            onPressed: parent.scale = 0.95
                            onReleased: parent.scale = 1.0

                            onClicked: {
                                if (GlobalStates.wallpaperManager) {
                                    GlobalStates.wallpaperManager.setWallpaper(modelData);
                                }
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Config.animDuration / 3
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
