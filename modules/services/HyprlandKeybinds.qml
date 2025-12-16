import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

QtObject {
    id: root

    property Process hyprctlProcess: Process {}

    property Timer applyTimer: Timer {
        interval: 100
        repeat: false
        onTriggered: applyKeybindsInternal()
    }

    function applyKeybinds() {
        applyTimer.restart();
    }

    // Helper function to check if an action is compatible with the current layout
    function isActionCompatibleWithLayout(action) {
        // If no compositor specified, action works everywhere
        if (!action.compositor) return true;
        
        // If compositor type is not hyprland, skip (future-proofing)
        if (action.compositor.type && action.compositor.type !== "hyprland") return false;
        
        // If no layouts specified or empty array, action works in all layouts
        if (!action.compositor.layouts || action.compositor.layouts.length === 0) return true;
        
        // Check if current layout is in the allowed list
        const currentLayout = Config.hyprland.layout;
        return action.compositor.layouts.indexOf(currentLayout) !== -1;
    }

    function applyKeybindsInternal() {
        // Verificar que el adapter esté cargado
        if (!Config.keybindsLoader.loaded) {
            console.log("HyprlandKeybinds: Esperando que se cargue el adapter...");
            return;
        }

        console.log("HyprlandKeybinds: Aplicando keybindings (layout: " + Config.hyprland.layout + ")...");

        // Construir lista de unbinds
        let unbindCommands = [];
        
        // Helper function para formatear modifiers
        function formatModifiers(modifiers) {
            if (!modifiers || modifiers.length === 0) return "";
            return modifiers.join(" ");
        }

        // Helper function para crear un bind command (old format for ambxst binds)
        function createBindCommand(keybind, flags) {
            const mods = formatModifiers(keybind.modifiers);
            const key = keybind.key;
            const dispatcher = keybind.dispatcher;
            const argument = keybind.argument || "";
            const bindKeyword = flags ? `bind${flags}` : "bind";
            // Para bindm no se incluye argumento si está vacío
            if (flags === "m" && !argument) {
                return `keyword ${bindKeyword} ${mods},${key},${dispatcher}`;
            }
            return `keyword ${bindKeyword} ${mods},${key},${dispatcher},${argument}`;
        }

        // Helper function para crear un unbind command (old format)
        function createUnbindCommand(keybind) {
            const mods = formatModifiers(keybind.modifiers);
            const key = keybind.key;
            return `keyword unbind ${mods},${key}`;
        }

        // Helper function para crear unbind command desde key object (new format)
        function createUnbindFromKey(keyObj) {
            const mods = formatModifiers(keyObj.modifiers);
            const key = keyObj.key;
            return `keyword unbind ${mods},${key}`;
        }

        // Helper function para crear bind command desde key + action (new format)
        function createBindFromKeyAction(keyObj, action) {
            const mods = formatModifiers(keyObj.modifiers);
            const key = keyObj.key;
            const dispatcher = action.dispatcher;
            const argument = action.argument || "";
            const flags = action.flags || "";
            const bindKeyword = flags ? `bind${flags}` : "bind";
            // Para bindm no se incluye argumento si está vacío
            if (flags === "m" && !argument) {
                return `keyword ${bindKeyword} ${mods},${key},${dispatcher}`;
            }
            return `keyword ${bindKeyword} ${mods},${key},${dispatcher},${argument}`;
        }

        // Construir batch command con todos los binds
        let batchCommands = [];

        // Procesar Ambxst keybinds (still use old format)
        const ambxst = Config.keybindsLoader.adapter.ambxst;
        
        // Dashboard keybinds
        const dashboard = ambxst.dashboard;
        unbindCommands.push(createUnbindCommand(dashboard.widgets));
        unbindCommands.push(createUnbindCommand(dashboard.clipboard));
        unbindCommands.push(createUnbindCommand(dashboard.emoji));
        unbindCommands.push(createUnbindCommand(dashboard.tmux));
        unbindCommands.push(createUnbindCommand(dashboard.wallpapers));
        unbindCommands.push(createUnbindCommand(dashboard.assistant));
        unbindCommands.push(createUnbindCommand(dashboard.notes));
        
        batchCommands.push(createBindCommand(dashboard.widgets));
        batchCommands.push(createBindCommand(dashboard.clipboard));
        batchCommands.push(createBindCommand(dashboard.emoji));
        batchCommands.push(createBindCommand(dashboard.tmux));
        batchCommands.push(createBindCommand(dashboard.wallpapers));
        batchCommands.push(createBindCommand(dashboard.assistant));
        batchCommands.push(createBindCommand(dashboard.notes));

        // System keybinds
        const system = ambxst.system;
        unbindCommands.push(createUnbindCommand(system.overview));
        unbindCommands.push(createUnbindCommand(system.powermenu));
        unbindCommands.push(createUnbindCommand(system.config));
        unbindCommands.push(createUnbindCommand(system.lockscreen));
        
        batchCommands.push(createBindCommand(system.overview));
        batchCommands.push(createBindCommand(system.powermenu));
        batchCommands.push(createBindCommand(system.config));
        batchCommands.push(createBindCommand(system.lockscreen));

        // Procesar custom keybinds (new format with keys[] and actions[])
        const customBinds = Config.keybindsLoader.adapter.custom;
        if (customBinds && customBinds.length > 0) {
            for (let i = 0; i < customBinds.length; i++) {
                const bind = customBinds[i];
                
                // Check if bind has the new format
                if (bind.keys && bind.actions) {
                    // Unbind all keys first (always unbind regardless of layout)
                    for (let k = 0; k < bind.keys.length; k++) {
                        unbindCommands.push(createUnbindFromKey(bind.keys[k]));
                    }
                    
                    // Only create binds if enabled
                    if (bind.enabled !== false) {
                        // For each key, bind only compatible actions
                        for (let k = 0; k < bind.keys.length; k++) {
                            for (let a = 0; a < bind.actions.length; a++) {
                                const action = bind.actions[a];
                                // Check if this action is compatible with the current layout
                                if (isActionCompatibleWithLayout(action)) {
                                    batchCommands.push(createBindFromKeyAction(bind.keys[k], action));
                                }
                            }
                        }
                    }
                } else {
                    // Fallback for old format (shouldn't happen after normalization)
                    unbindCommands.push(createUnbindCommand(bind));
                    if (bind.enabled !== false) {
                        const flags = bind.flags || "";
                        batchCommands.push(createBindCommand(bind, flags));
                    }
                }
            }
        }

        // Combinar unbind y bind en un solo batch
        const fullBatchCommand = unbindCommands.join("; ") + "; " + batchCommands.join("; ");

        console.log("HyprlandKeybinds: Ejecutando batch command");
        hyprctlProcess.command = ["sh", "-c", `hyprctl --batch "${fullBatchCommand}"`];
        hyprctlProcess.running = true;
    }

    property Connections configConnections: Connections {
        target: Config.keybindsLoader
        function onFileChanged() {
            applyKeybinds();
        }
        function onLoaded() {
            applyKeybinds();
        }
        function onAdapterUpdated() {
            applyKeybinds();
        }
    }

    // Re-apply keybinds when layout changes
    property Connections hyprlandConfigConnections: Connections {
        target: Config.hyprland
        function onLayoutChanged() {
            console.log("HyprlandKeybinds: Layout changed to " + Config.hyprland.layout + ", reapplying keybindings...");
            applyKeybinds();
        }
    }

    property Connections hyprlandConnections: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                console.log("HyprlandKeybinds: Detectado configreloaded, reaplicando keybindings...");
                applyKeybinds();
            }
        }
    }

    Component.onCompleted: {
        // Si el loader ya está cargado, aplicar inmediatamente
        if (Config.keybindsLoader.loaded) {
            applyKeybinds();
        }
    }
}
