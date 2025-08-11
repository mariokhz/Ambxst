import QtQuick
import QtQuick.Controls
import qs.modules.theme
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.config

// Componente principal para el selector de fondos de pantalla.
Rectangle {
    // Configuración de estilo y layout del componente.
    color: Colors.background
    anchors.fill: parent
    anchors.margins: 4
    radius: Config.roundness > 0 ? Config.roundness : 0

    // Propiedades personalizadas para la funcionalidad del componente.
    property string searchText: ""
    readonly property int gridRows: 3
    readonly property int gridColumns: 5
    property int selectedIndex: GlobalStates.wallpaperSelectedIndex
    property bool navigationInProgress: false

    // Timer para limitar la velocidad de navegación con las teclas.
    Timer {
        id: navigationTimer
        interval: Config.animDuration / 2
        onTriggered: navigationInProgress = false
    }

    // Función para enfocar el campo de búsqueda.
    function focusSearch() {
        wallpaperSearchInput.focusInput();
    }

    // Llama a focusSearch una vez que el componente se ha completado.
    Component.onCompleted: {
        Qt.callLater(() => {
            focusSearch();
        });
    }

    // Propiedad calculada que filtra los fondos de pantalla según el texto de búsqueda.
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

    // Layout principal con una fila para la barra lateral y la cuadrícula.
    Row {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Columna para el buscador y las opciones.
        Column {
            // El ancho se calcula dinámicamente para llenar el espacio.
            width: parent.width - wallpaperGridContainer.width - 8
            height: parent.height + 4
            spacing: 8

            // Barra de búsqueda.
            SearchInput {
                id: wallpaperSearchInput
                width: parent.width
                text: searchText
                placeholderText: "Search wallpapers..."
                iconText: ""
                clearOnEscape: false
                radius: Config.roundness > 0 ? Config.roundness - 8 : 0

                // Manejo de eventos de búsqueda y teclado.
                onSearchTextChanged: text => {
                    searchText = text;
                    if (text.length > 0 && filteredWallpapers.length > 0) {
                        GlobalStates.wallpaperSelectedIndex = 0;
                        selectedIndex = 0;
                        wallpaperGrid.currentIndex = 0;
                    } else {
                        GlobalStates.wallpaperSelectedIndex = -1;
                        selectedIndex = -1;
                        wallpaperGrid.currentIndex = -1;
                    }
                }

                onEscapePressed: {
                    Visibilities.setActiveModule("");
                }

                onDownPressed: {
                    if (filteredWallpapers.length > 0 && !navigationInProgress) {
                        navigationInProgress = true;
                        navigationTimer.restart();

                        if (selectedIndex < filteredWallpapers.length - 1) {
                            let newIndex = selectedIndex + gridColumns;
                            if (newIndex >= filteredWallpapers.length) {
                                newIndex = filteredWallpapers.length - 1;
                            }
                            GlobalStates.wallpaperSelectedIndex = newIndex;
                            selectedIndex = newIndex;
                            wallpaperGrid.currentIndex = newIndex;
                        } else if (selectedIndex === -1) {
                            GlobalStates.wallpaperSelectedIndex = 0;
                            selectedIndex = 0;
                            wallpaperGrid.currentIndex = 0;
                        }
                    }
                }

                onUpPressed: {
                    if (filteredWallpapers.length > 0 && selectedIndex > 0 && !navigationInProgress) {
                        navigationInProgress = true;
                        navigationTimer.restart();

                        let newIndex = selectedIndex - gridColumns;
                        if (newIndex < 0) {
                            newIndex = 0;
                        }
                        GlobalStates.wallpaperSelectedIndex = newIndex;
                        selectedIndex = newIndex;
                        wallpaperGrid.currentIndex = newIndex;
                    } else if (selectedIndex === 0 && searchText.length === 0 && !navigationInProgress) {
                        navigationInProgress = true;
                        navigationTimer.restart();

                        GlobalStates.wallpaperSelectedIndex = -1;
                        selectedIndex = -1;
                        wallpaperGrid.currentIndex = -1;
                    }
                }

                onAccepted: {
                    if (selectedIndex >= 0 && selectedIndex < filteredWallpapers.length) {
                        let selectedWallpaper = filteredWallpapers[selectedIndex];
                        if (selectedWallpaper && GlobalStates.wallpaperManager) {
                            GlobalStates.wallpaperManager.setWallpaper(selectedWallpaper);
                        }
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Left && filteredWallpapers.length > 0 && !navigationInProgress) {
                        navigationInProgress = true;
                        navigationTimer.restart();

                        if (selectedIndex > 0) {
                            GlobalStates.wallpaperSelectedIndex = selectedIndex - 1;
                            selectedIndex = selectedIndex - 1;
                            wallpaperGrid.currentIndex = selectedIndex;
                        } else if (selectedIndex === -1) {
                            GlobalStates.wallpaperSelectedIndex = 0;
                            selectedIndex = 0;
                            wallpaperGrid.currentIndex = 0;
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right && filteredWallpapers.length > 0 && !navigationInProgress) {
                        navigationInProgress = true;
                        navigationTimer.restart();

                        if (selectedIndex < filteredWallpapers.length - 1) {
                            GlobalStates.wallpaperSelectedIndex = selectedIndex + 1;
                            selectedIndex = selectedIndex + 1;
                            wallpaperGrid.currentIndex = selectedIndex;
                        } else if (selectedIndex === -1) {
                            GlobalStates.wallpaperSelectedIndex = 0;
                            selectedIndex = 0;
                            wallpaperGrid.currentIndex = 0;
                        }
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Home && filteredWallpapers.length > 0 && !navigationInProgress) {
                        navigationInProgress = true;
                        navigationTimer.restart();

                        GlobalStates.wallpaperSelectedIndex = 0;
                        selectedIndex = 0;
                        wallpaperGrid.currentIndex = 0;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_End && filteredWallpapers.length > 0 && !navigationInProgress) {
                        navigationInProgress = true;
                        navigationTimer.restart();

                        GlobalStates.wallpaperSelectedIndex = filteredWallpapers.length - 1;
                        selectedIndex = filteredWallpapers.length - 1;
                        wallpaperGrid.currentIndex = selectedIndex;
                        event.accepted = true;
                    }
                }
            }

            // Área placeholder para opciones futuras.
            Rectangle {
                width: parent.width
                height: parent.height - wallpaperSearchInput.height - 8
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

        // Contenedor para la cuadrícula de fondos de pantalla.
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
            readonly property int wallpaperWidth: wallpaperHeight

            ScrollView {
                id: scrollView
                anchors.fill: parent

                GridView {
                    id: wallpaperGrid
                    width: parent.width
                    cellWidth: wallpaperGridContainer.wallpaperWidth
                    cellHeight: wallpaperGridContainer.wallpaperHeight
                    model: filteredWallpapers
                    currentIndex: selectedIndex

                    // Sincronizar currentIndex con selectedIndex y centrar la vista.
                    onCurrentIndexChanged: {
                        if (currentIndex !== selectedIndex) {
                            GlobalStates.wallpaperSelectedIndex = currentIndex;
                            selectedIndex = currentIndex;
                        }
                        if (currentIndex >= 0) {
                            positionViewAtIndex(currentIndex, GridView.Center);
                        }
                    }

                    // Elemento de realce para el wallpaper seleccionado.
                    highlight: Rectangle {
                        color: Colors.adapter.primary
                        opacity: 0.2
                        radius: Config.roundness > 0 ? Config.roundness + 4 : 0
                        visible: selectedIndex >= 0
                        z: 5

                        Behavior on x {
                            NumberAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }

                        Behavior on y {
                            NumberAnimation {
                                duration: Config.animDuration / 2
                                easing.type: Easing.OutQuart
                            }
                        }
                    }

                    // Delegado para cada elemento de la cuadrícula.
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
                        property bool isSelected: selectedIndex === index

                        // Carga la imagen o el GIF según el tipo de archivo.
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
                                return staticImageComponent; // Fallback
                            }

                            property string sourceFile: modelData
                        }

                        // Borde de resaltado para navegación por teclado.
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: Colors.adapter.primary
                            border.width: parent.isSelected ? 2 : 0
                            radius: 4
                            z: 15

                            Behavior on border.width {
                                NumberAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutQuart
                                }
                            }
                        }

                        // Etiqueta "CURRENT" para el fondo de pantalla activo.
                        Rectangle {
                            visible: parent.isCurrentWallpaper
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 24
                            color: Colors.adapter.surfaceContainerLowest
                            z: 10
                            clip: true

                            Text {
                                anchors.centerIn: parent
                                text: "CURRENT"
                                color: Colors.adapter.primary
                                font.family: Config.theme.font
                                font.pixelSize: 14
                                font.weight: Font.Bold
                            }
                        }

                        // Componente para imágenes estáticas.
                        Component {
                            id: staticImageComponent
                            Image {
                                source: parent.sourceFile ? "file://" + parent.sourceFile : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                            }
                        }

                        // Componente para imágenes animadas (GIFs).
                        Component {
                            id: animatedImageComponent
                            AnimatedImage {
                                source: parent.sourceFile ? "file://" + parent.sourceFile : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                playing: parent.isHovered // Solo se anima al hacer hover
                            }
                        }

                        // Etiqueta con el nombre del archivo al hacer hover o seleccionar.
                        Rectangle {
                            visible: parent.isHovered || parent.isSelected
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

                                readonly property bool needsScroll: paintedWidth > parent.width - 8

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
                                        to: parent.width - paintedWidth - 4
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
                        }

                        // Manejo de eventos de ratón.
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                parent.isHovered = true;
                                GlobalStates.wallpaperSelectedIndex = index;
                                selectedIndex = index;
                                wallpaperGrid.currentIndex = index;
                            }
                            onExited: {
                                parent.isHovered = false;
                                if (!parent.isCurrentWallpaper) {
                                    parent.color = Colors.surface;
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

                        // Animaciones de color y escala.
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
