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
                console.log("DEBUG: currentWall changed to:", currentWall);
                console.log("DEBUG: current wallpaper is:", wallpaper.currentWallpaper);
                console.log("DEBUG: initialLoadCompleted:", wallpaper.initialLoadCompleted);
                // Solo actualizar si el cambio viene del archivo JSON y es diferente al actual
                if (currentWall && currentWall !== wallpaper.currentWallpaper && wallpaper.initialLoadCompleted) {
                    console.log("Loading wallpaper from JSON:", currentWall);
                    var pathIndex = wallpaper.wallpaperPaths.indexOf(currentWall);
                    if (pathIndex !== -1) {
                        wallpaper.currentIndex = pathIndex;
                    } else {
                        console.warn("Saved wallpaper not found in current list:", currentWall);
                    }
                } else if (currentWall && !wallpaper.initialLoadCompleted) {
                    console.log("DEBUG: Deferring wallpaper load until scan completes");
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
                    generateGifThumbnail.generateThumbnail(checkThumbnailExists.sourcePath, checkThumbnailExists.thumbnailPath, checkThumbnailExists.callback);
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
        
        function generateThumbnail(source, thumbnail, completionCallback) {
            sourcePath = source;
            thumbnailPath = thumbnail;
            callback = completionCallback;
            
            console.log("DEBUG: Starting FFmpeg thumbnail generation");
            console.log("DEBUG: Source:", sourcePath);
            console.log("DEBUG: Thumbnail:", thumbnailPath);
            
            // Set command before running
            command = ["ffmpeg", "-i", sourcePath, "-vf", "select=eq(n\\,0),scale=200:200:force_original_aspect_ratio=decrease,pad=200:200", "-vframes", "1", "-f", "image2", "-update", "1", "-y", thumbnailPath];
            running = true;
        }
        
        onRunningChanged: {
            if (!running) {
                console.log("DEBUG: FFmpeg process finished");
                // Use a delay to allow file system to sync, then check if file exists
                Qt.callLater(function() {
                    if (thumbnailPath) {
                        checkFinalThumbnail.sourcePath = sourcePath;
                        checkFinalThumbnail.thumbnailPath = thumbnailPath;
                        checkFinalThumbnail.callback = callback;
                        checkFinalThumbnail.running = true;
                    }
                });
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.log("DEBUG: FFmpeg stdout:", text);
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    console.log("DEBUG: FFmpeg stderr:", text);
                }
            }
        }
    }
    
    // Proceso separado para verificar que la miniatura se generó correctamente
    Process {
        id: checkFinalThumbnail
        running: false
        command: []
        
        property string sourcePath: ""
        property string thumbnailPath: ""
        property var callback: null
        
        onRunningChanged: {
            if (running && thumbnailPath) {
                command = ["test", "-f", thumbnailPath];
            } else if (!running) {
                // Process finished - check exit status via a simple ls command
                // If test succeeded, the file exists, so we can call the callback
                verifyThumbnailExists.sourcePath = sourcePath;
                verifyThumbnailExists.thumbnailPath = thumbnailPath;
                verifyThumbnailExists.callback = callback;
                verifyThumbnailExists.running = true;
            }
        }
    }
    
    // Alternative verification using ls command to get clear output
    Process {
        id: verifyThumbnailExists
        running: false
        command: []
        
        property string sourcePath: ""
        property string thumbnailPath: ""
        property var callback: null
        
        onRunningChanged: {
            if (running && thumbnailPath) {
                command = ["ls", "-la", thumbnailPath];
            }
        }
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0 && text.indexOf("No such file") === -1) {
                    // File exists and ls succeeded
                    console.log("DEBUG: Thumbnail verified successfully:", verifyThumbnailExists.thumbnailPath);
                    if (verifyThumbnailExists.callback) verifyThumbnailExists.callback();
                } else {
                    // File doesn't exist, use fallback
                    console.warn("DEBUG: Thumbnail verification failed, using original file for Matugen");
                    if (verifyThumbnailExists.sourcePath) {
                        matugenProcess.command = ["matugen", "image", verifyThumbnailExists.sourcePath, "-c", Qt.resolvedUrl("../../../assets/matugen/config.toml").toString().replace("file://", "")];
                        matugenProcess.running = true;
                    }
                }
            }
        }
        
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) {
                    // ls failed - file doesn't exist, use fallback
                    console.warn("DEBUG: Thumbnail verification failed (stderr), using original file for Matugen");
                    if (verifyThumbnailExists.sourcePath) {
                        matugenProcess.command = ["matugen", "image", verifyThumbnailExists.sourcePath, "-c", Qt.resolvedUrl("../../../assets/matugen/config.toml").toString().replace("file://", "")];
                        matugenProcess.running = true;
                    }
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
                            console.log("DEBUG: Initializing wallpaper selection");
                            if (wallpaperConfig.adapter.currentWall) {
                                console.log("DEBUG: Found saved wallpaper:", wallpaperConfig.adapter.currentWall);
                                var savedIndex = wallpaperPaths.indexOf(wallpaperConfig.adapter.currentWall);
                                if (savedIndex !== -1) {
                                    console.log("DEBUG: Loading saved wallpaper at index:", savedIndex);
                                    currentIndex = savedIndex;
                                } else {
                                    console.log("DEBUG: Saved wallpaper not found, using first wallpaper");
                                    currentIndex = 0;
                                    wallpaperConfig.adapter.currentWall = wallpaperPaths[0];
                                }
                            } else {
                                console.log("DEBUG: No saved wallpaper, using first one");
                                currentIndex = 0;
                                wallpaperConfig.adapter.currentWall = wallpaperPaths[0];
                            }
                            console.log("DEBUG: Setting initialLoadCompleted to true");
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