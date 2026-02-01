pragma Singleton
pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config

Singleton {
    id: root
    property var trackedPlayer: null
    property var filteredPlayers: {
        const filtered = Mpris.players.values.filter(player => {
            const dbusName = (player.dbusName || "").toLowerCase();
            if (!Config.bar.enableFirefoxPlayer && dbusName.includes("firefox")) {
                return false;
            }
            return true;
        });
        return filtered;
    }
    property var activePlayer: trackedPlayer ?? filteredPlayers[0] ?? null

    property string cacheFilePath: Quickshell.dataPath("lastPlayer.json")
    property bool isInitializing: true
    property string cachedDbusName: ""
    property bool cacheFileReady: false

    Process {
        id: ensureCacheFile
        running: true
        command: ["bash", "-c", "mkdir -p \"$(dirname '" + root.cacheFilePath + "')\" && if [ ! -f '" + root.cacheFilePath + "' ]; then echo '{}' > '" + root.cacheFilePath + "'; fi"]
        onExited: {
            root.cacheFileReady = true
            cacheFile.reload()
        }
    }

    FileView {
        id: cacheFile
        path: root.cacheFileReady ? root.cacheFilePath : ""
        onLoaded: root.loadLastPlayer()
    }

    onFilteredPlayersChanged: {
        if (root.isInitializing && root.cachedDbusName && root.filteredPlayers.length > 0) {
            for (const player of root.filteredPlayers) {
                if (player.dbusName === root.cachedDbusName) {
                    root.trackedPlayer = player;
                    root.isInitializing = false;
                    return;
                }
            }
        }
    }

    Component.onCompleted: {
        cacheFile.reload();
    }

    function loadLastPlayer() {
        try {
            const data = cacheFile.text();
            if (!data) {
                root.isInitializing = false;
                return;
            }

            const obj = JSON.parse(data);
            if (obj && obj.dbusName) {
                root.cachedDbusName = obj.dbusName;
                for (const player of root.filteredPlayers) {
                    if (player.dbusName === obj.dbusName) {
                        root.trackedPlayer = player;
                        root.isInitializing = false;
                        return;
                    }
                }
            }
        } catch (e) {
            console.warn("Error loading last player:", e);
            root.isInitializing = false;
        }
    }

    function saveLastPlayer() {
        if (!root.trackedPlayer || root.isInitializing)
            return;

        const data = JSON.stringify({
            dbusName: root.trackedPlayer.dbusName
        });

        cacheFile.setText(data);
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property var modelData
            target: modelData

            Component.onCompleted: {
                const dbusName = (modelData.dbusName || "").toLowerCase();
                const shouldIgnore = !Config.bar.enableFirefoxPlayer && dbusName.includes("firefox");

                if (!shouldIgnore && (root.trackedPlayer == null || modelData.isPlaying)) {
                    root.trackedPlayer = modelData;
                }
            }

            Component.onDestruction: {
                if (root.trackedPlayer === modelData) {
                    for (const player of root.filteredPlayers) {
                        if (player.playbackState.isPlaying) {
                            root.trackedPlayer = player;
                            break;
                        }
                    }

                    if (root.trackedPlayer === modelData) {
                        root.trackedPlayer = root.filteredPlayers.length > 0 ? root.filteredPlayers[0] : null;
                    }
                }
            }

            function onPlaybackStateChanged() {
            // Comentado para evitar cambio automático de player
            // if (root.trackedPlayer !== modelData) root.trackedPlayer = modelData
            }
        }
    }

    property bool isPlaying: root.activePlayer && root.activePlayer.isPlaying
    property bool canTogglePlaying: root.activePlayer?.canTogglePlaying ?? false
    function togglePlaying() {
        if (root.canTogglePlaying)
            root.activePlayer.togglePlaying();
    }

    property bool canGoPrevious: root.activePlayer?.canGoPrevious ?? false
    function previous() {
        if (root.canGoPrevious) {
            root.activePlayer.previous();
        }
    }

    property bool canGoNext: root.activePlayer?.canGoNext ?? false
    function next() {
        if (root.canGoNext) {
            root.activePlayer.next();
        }
    }

    property bool canChangeVolume: root.activePlayer && root.activePlayer.volumeSupported && root.activePlayer.canControl

    property bool loopSupported: root.activePlayer && root.activePlayer.loopSupported && root.activePlayer.canControl
    property var loopState: root.activePlayer?.loopState ?? MprisLoopState.None
    function setLoopState(loopState) {
        if (root.loopSupported) {
            root.activePlayer.loopState = loopState;
        }
    }

    property bool shuffleSupported: root.activePlayer && root.activePlayer.shuffleSupported && root.activePlayer.canControl
    property bool hasShuffle: root.activePlayer?.shuffle ?? false
    function setShuffle(shuffle) {
        if (root.shuffleSupported) {
            root.activePlayer.shuffle = shuffle;
        }
    }

    function setActivePlayer(player) {
        const targetPlayer = player ?? root.filteredPlayers[0] ?? null;

        root.trackedPlayer = targetPlayer;
        root.saveLastPlayer();
    }

    function cyclePlayer(direction) {
        const players = root.filteredPlayers;
        if (players.length === 0)
            return;

        const currentIndex = players.indexOf(root.activePlayer);
        let newIndex;

        if (direction > 0) {
            newIndex = (currentIndex + 1) % players.length;
        } else {
            newIndex = (currentIndex - 1 + players.length) % players.length;
        }

        root.trackedPlayer = players[newIndex];
        root.saveLastPlayer();
    }
}
