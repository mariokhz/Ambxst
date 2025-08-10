import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.modules.globals

PanelWindow {
    id: wallpaper

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:wallpaper"
    exclusionMode: ExclusionMode.Ignore

    color: "transparent"

    property string wallpaperDir: wallpaperConfig.adapter.wallPath || Quickshell.env("HOME") + "/Wallpapers"
    property string fallbackDir: Quickshell.env("PWD") + "/assets/wallpapers_example"
    property string thumbnailDir: Quickshell.env("HOME") + "/.cache/ambyst/wallpaper-thumbnails"
    property list<string> wallpaperPaths: []
    property int currentIndex: 0
    property string currentWallpaper: wallpaperPaths.length > 0 ? wallpaperPaths[currentIndex] : ""
    property bool initialLoadCompleted: false
    property bool usingFallback: false

    // Funciones utilitarias para tipos de archivo
    function getFileType(path) {
        var extension = path.toLowerCase().split('.').pop();
        if (['jpg', 'jpeg', 'png', 'webp', 'tif', 'tiff', 'bmp'].includes(extension)) {
            return 'image';
        } else if (['gif'].includes(extension)) {
            return 'gif';
        }
        return 'unknown';
    }

    function generateThumbnailPath(sourcePath) {
        // Crear hash simple del path para nombre único
        var hash = 0;
        for (var i = 0; i < sourcePath.length; i++) {
            var charCode = sourcePath.charCodeAt(i);
            hash = ((hash << 5) - hash) + charCode;
            hash = hash & hash; // Convertir a 32bit integer
        }
        var fileName = sourcePath.split('/').pop().split('.')[0];
        return thumbnailDir + "/" + Math.abs(hash) + "_" + fileName + ".jpg";
    }

    function getThumbnailForWallpaper(wallpaperPath) {
        if (!wallpaperPath) return "";
        
        var fileType = getFileType(wallpaperPath);
        if (fileType === 'image') {
            return wallpaperPath; // Usar imagen original para imágenes estáticas
        } else {
            return generateThumbnailPath(wallpaperPath);
        }
    }

    // Update directory watcher when wallpaperDir changes
    onWallpaperDirChanged: {
        console.log("Wallpaper directory changed to:", wallpaperDir);
        usingFallback = false;
        directoryWatcher.path = wallpaperDir;
        scanWallpapers.running = true;
    }

    onCurrentWallpaperChanged: {
        if (currentWallpaper && initialLoadCompleted) {
            console.log("Wallpaper changed to:", currentWallpaper);
            
            // Generar miniatura si es necesario y usar para Matugen
            var thumbnailPath = getThumbnailForWallpaper(currentWallpaper);
            var fileType = getFileType(currentWallpaper);
            
            if (fileType === 'gif') {
                // Generar miniatura primero, luego ejecutar Matugen
                generateThumbnail(currentWallpaper, thumbnailPath, function() {
                    matugenProcess.command = ["matugen", "image", thumbnailPath, "-c", Qt.resolvedUrl("../../../assets/matugen/config.toml").toString().replace("file://", "")];
                    matugenProcess.running = true;
                });
            } else {
                // Usar imagen original para imágenes estáticas
                matugenProcess.command = ["matugen", "image", currentWallpaper, "-c", Qt.resolvedUrl("../../../assets/matugen/config.toml").toString().replace("file://", "")];
                matugenProcess.running = true;
            }
        }
    }

    function generateThumbnail(sourcePath, thumbnailPath, callback) {
        // Verificar si la miniatura ya existe
        checkThumbnailExists.sourcePath = sourcePath;
        checkThumbnailExists.thumbnailPath = thumbnailPath;
        checkThumbnailExists.callback = callback;
        checkThumbnailExists.command = ["test", "-f", thumbnailPath];
        checkThumbnailExists.running = true;
    }

    function setWallpaper(path) {
        console.log("setWallpaper called with:", path);
        initialLoadCompleted = true;
        var pathIndex = wallpaperPaths.indexOf(path);
        if (pathIndex !== -1) {
            currentIndex = pathIndex;
            wallpaperConfig.adapter.currentWall = path;
        } else {
            console.warn("Wallpaper path not found in current list:", path);
        }
    }

    function nextWallpaper() {
        if (wallpaperPaths.length === 0)
            return;
        initialLoadCompleted = true;
        currentIndex = (currentIndex + 1) % wallpaperPaths.length;
        currentWallpaper = wallpaperPaths[currentIndex];
        wallpaperConfig.adapter.currentWall = wallpaperPaths[currentIndex];
    }

    function previousWallpaper() {
        if (wallpaperPaths.length === 0)
            return;
        initialLoadCompleted = true;
        currentIndex = currentIndex === 0 ? wallpaperPaths.length - 1 : currentIndex - 1;
        currentWallpaper = wallpaperPaths[currentIndex];
        wallpaperConfig.adapter.currentWall = wallpaperPaths[currentIndex];
    }

    function setWallpaperByIndex(index) {
        if (index >= 0 && index < wallpaperPaths.length) {
            initialLoadCompleted = true;
            currentIndex = index;
            currentWallpaper = wallpaperPaths[currentIndex];
            wallpaperConfig.adapter.currentWall = wallpaperPaths[currentIndex];
        }
    }

    Component.onCompleted: {
        GlobalStates.wallpaperManager = wallpaper;
        // Crear directorio de miniaturas si no existe
        createThumbnailDir.running = true;
        // Initial scan
        scanWallpapers.running = true;
        // Start directory monitoring
        directoryWatcher.reload();
        forceActiveFocus();
    }

    FileView {
        id: wallpaperConfig
        path: Quickshell.env("PWD") + "/modules/widgets/wallpapers/wallpaper_config.json"
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            property string currentWall: ""
            property string wallPath: ""

            onCurrentWallChanged: {
                // Solo actualizar si el cambio viene del archivo JSON y es diferente al actual
                if (currentWall && currentWall !== wallpaper.currentWallpaper && wallpaper.initialLoadCompleted) {
                    console.log("Loading wallpaper from JSON:", currentWall);
                    var pathIndex = wallpaper.wallpaperPaths.indexOf(currentWall);
                    if (pathIndex !== -1) {
                        wallpaper.currentIndex = pathIndex;
                    } else {
                        console.warn("Saved wallpaper not found in current list:", currentWall);
                    }
                }
            }

            onWallPathChanged: {
                // Rescan wallpapers when wallPath changes
                if (wallPath) {
                    console.log("Wallpaper directory changed to:", wallPath);
                    scanWallpapers.running = true;
                }
            }
        }
    }

    Keys.onLeftPressed: {
        if (wallpaperPaths.length > 0) {
            previousWallpaper();
        }
    }

    Keys.onRightPressed: {
        if (wallpaperPaths.length > 0) {
            nextWallpaper();
        }
    }

    Process {
        id: matugenProcess
        running: false
        command: []

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.log("Matugen output:", text);
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Matugen error:", text);
                }
            }
        }
    }

    // Directory watcher using FileView to monitor the wallpaper directory
    FileView {
        id: directoryWatcher
        path: wallpaperDir
        watchChanges: true
        printErrors: false
        
        onFileChanged: {
            console.log("Wallpaper directory changed, rescanning...");
            scanWallpapers.running = true;
        }
        
        // Remove onLoadFailed to prevent premature fallback activation
    }

    // Proceso para crear directorio de miniaturas
    Process {
        id: createThumbnailDir
        running: false
        command: ["mkdir", "-p", thumbnailDir]
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Thumbnail directory ready:", thumbnailDir);
            }
        }
    }

    // Proceso para verificar si existe miniatura
    Process {
        id: checkThumbnailExists
        running: false
        command: []
        
        property string sourcePath: ""
        property string thumbnailPath: ""
        property var callback: null
        
        stdout: StdioCollector {
            onStreamFinished: {
                // Si test tiene éxito (código 0), la miniatura existe
                if (checkThumbnailExists.callback) checkThumbnailExists.callback();
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                // Si test falla, la miniatura no existe, generarla
                console.log("Generating thumbnail for:", checkThumbnailExists.sourcePath);
                var fileType = getFileType(checkThumbnailExists.sourcePath);
                
                if (fileType === 'gif') {
                    generateGifThumbnail.sourcePath = checkThumbnailExists.sourcePath;
                    generateGifThumbnail.thumbnailPath = checkThumbnailExists.thumbnailPath;
                    generateGifThumbnail.callback = checkThumbnailExists.callback;
                    generateGifThumbnail.running = true;
                }
            }
        }
    }

    // Proceso para generar miniatura de GIF
    Process {
        id: generateGifThumbnail
        running: false
        command: []
        
        property string sourcePath: ""
        property string thumbnailPath: ""
        property var callback: null
        
        onRunningChanged: {
            if (running && sourcePath && thumbnailPath) {
                command = ["ffmpeg", "-i", sourcePath, "-vf", "select=eq(n\\,0),scale=200:200:force_original_aspect_ratio=decrease,pad=200:200:(ow-iw)/2:(oh-ih)/2", "-vframes", "1", "-f", "image2", "-update", "1", "-y", thumbnailPath];
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("GIF thumbnail generated:", generateGifThumbnail.thumbnailPath);
                if (generateGifThumbnail.callback) generateGifThumbnail.callback();
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("FFmpeg GIF error:", text);
                }
            }
        }
    }

    Process {
        id: scanWallpapers
        running: false
        command: ["find", wallpaperDir, "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", "-o", "-name", "*.gif", ")"]

        stdout: StdioCollector {
            onStreamFinished: {
                var files = text.trim().split("\n").filter(function(f) { return f.length > 0; });
                if (files.length === 0) {
                    console.log("No wallpapers found in main directory, using fallback");
                    usingFallback = true;
                    scanFallback.running = true;
                } else {
                    usingFallback = false;
                    // Only update if the list has actually changed
                    var newFiles = files.sort();
                    if (JSON.stringify(newFiles) !== JSON.stringify(wallpaperPaths)) {
                        console.log("Wallpaper directory updated. Found", newFiles.length, "images");
                        wallpaperPaths = newFiles;
                        
                        // Initialize wallpaper selection
                        if (wallpaperPaths.length > 0 && !initialLoadCompleted) {
                            if (wallpaperConfig.adapter.currentWall) {
                                var savedIndex = wallpaperPaths.indexOf(wallpaperConfig.adapter.currentWall);
                                if (savedIndex !== -1) {
                                    currentIndex = savedIndex;
                                } else {
                                    currentIndex = 0;
                                    wallpaperConfig.adapter.currentWall = wallpaperPaths[0];
                                }
                            } else {
                                currentIndex = 0;
                                wallpaperConfig.adapter.currentWall = wallpaperPaths[0];
                            }
                            initialLoadCompleted = true;
                        }
                    }
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.warn("Error scanning wallpaper directory:", text);
                    // Only fallback if we don't already have wallpapers loaded
                    if (wallpaperPaths.length === 0) {
                        console.log("Directory scan failed, using fallback");
                        usingFallback = true;
                        scanFallback.running = true;
                    }
                }
            }
        }
    }

    Process {
        id: scanFallback
        running: false
        command: ["find", fallbackDir, "-type", "f", "(", "-name", "*.jpg", "-o", "-name", "*.jpeg", "-o", "-name", "*.png", "-o", "-name", "*.webp", "-o", "-name", "*.tif", "-o", "-name", "*.tiff", "-o", "-name", "*.gif", ")"]

        stdout: StdioCollector {
            onStreamFinished: {
                var files = text.trim().split("\n").filter(function(f) { return f.length > 0; });
                console.log("Using fallback wallpapers. Found", files.length, "images");
                
                // Only use fallback if we don't already have main wallpapers loaded
                if (usingFallback) {
                    wallpaperPaths = files.sort();
                    
                    // Initialize fallback wallpaper selection
                    if (wallpaperPaths.length > 0 && !initialLoadCompleted) {
                        currentIndex = 0;
                        wallpaperConfig.adapter.currentWall = wallpaperPaths[0];
                        initialLoadCompleted = true;
                    }
                }
            }
        }
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: "#000000"

        WallpaperImage {
            id: wallpaper1
            anchors.fill: parent
            source: wallpaper.currentWallpaper
            active: wallpaper.currentIndex % 2 === 0
        }

        WallpaperImage {
            id: wallpaper2
            anchors.fill: parent
            source: wallpaper.currentWallpaper
            active: wallpaper.currentIndex % 2 === 1
        }
    }

    component WallpaperImage: Item {
        property string source
        property bool active: false

        opacity: active ? 1.0 : 0.0
        scale: active ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        Loader {
            anchors.fill: parent
            sourceComponent: {
                if (!parent.source) return null;
                
                var fileType = getFileType(parent.source);
                if (fileType === 'image') {
                    return staticImageComponent;
                } else if (fileType === 'gif') {
                    return animatedImageComponent;
                }
                return staticImageComponent; // fallback
            }
            
            property string sourceFile: parent.source
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
                playing: parent.parent.active
            }
        }
    }
}