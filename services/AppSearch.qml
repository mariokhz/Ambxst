pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    
    property real scoreThreshold: 0.2
    property var substitutions: ({
        "code-url-handler": "visual-studio-code",
        "Code": "visual-studio-code",
        "gnome-tweaks": "org.gnome.tweaks",
        "pavucontrol-qt": "pavucontrol",
        "footclient": "foot",
        "brave-browser": "brave-desktop"
    })
    
    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .sort((a, b) => a.name.localeCompare(b.name))
    
    function fuzzyQuery(search) {
        if (!search || search.length === 0) return [];
        
        const searchLower = search.toLowerCase();
        const results = [];
        
        for (let i = 0; i < list.length; i++) {
            const app = list[i];
            const nameLower = app.name.toLowerCase();
            
            // Simple fuzzy matching
            if (nameLower.includes(searchLower)) {
                results.push({
                    name: app.name,
                    icon: app.icon || "application-x-executable",
                    execute: () => {
                        app.execute();
                    }
                });
            }
        }
        
        // Sort by relevance (exact matches first, then partial matches)
        results.sort((a, b) => {
            const aExact = a.name.toLowerCase() === searchLower;
            const bExact = b.name.toLowerCase() === searchLower;
            if (aExact && !bExact) return -1;
            if (!aExact && bExact) return 1;
            
            const aStarts = a.name.toLowerCase().startsWith(searchLower);
            const bStarts = b.name.toLowerCase().startsWith(searchLower);
            if (aStarts && !bStarts) return -1;
            if (!aStarts && bStarts) return 1;
            
            return a.name.localeCompare(b.name);
        });
        
        return results.slice(0, 10); // Limit results
    }
    
    function iconExists(iconName) {
        if (!iconName || iconName.length == 0) return false;
        return (Quickshell.iconPath(iconName, true).length > 0) 
            && !iconName.includes("image-missing");
    }
    
    function guessIcon(str) {
        if (!str || str.length == 0) return "application-x-executable";
        
        if (substitutions[str])
            return substitutions[str];
        
        if (iconExists(str)) return str;
        
        let guessStr = str.split('.').slice(-1)[0].toLowerCase();
        if (iconExists(guessStr)) return guessStr;
        
        guessStr = str.toLowerCase().replace(/\s+/g, "-");
        if (iconExists(guessStr)) return guessStr;
        
        return "application-x-executable";
    }
}