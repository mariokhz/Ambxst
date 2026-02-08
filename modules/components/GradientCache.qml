pragma Singleton

import QtQuick
import Quickshell
import qs.config
import qs.modules.theme

/**
 * GradientCache - Singleton that caches resolved gradient data for StyledRect.
 *
 * Since Canvas and ShaderEffectSource must be in the same window, we can't share
 * the actual Canvas objects. Instead, we cache the resolved color data so each
 * StyledRect doesn't need to resolve colors on every repaint.
 *
 * Usage: GradientCache.getResolvedStops(gradientStops) returns resolved color array
 */
Singleton {
    id: root

    // Internal cache storage - maps hash keys to resolved gradient data
    property var _cache: ({})

    // Version counter - incremented when colors change to invalidate caches
    property int version: 0

    /**
     * Generate a stable hash key from gradient stops array (unresolved).
     */
    function _hashGradient(stops) {
        if (!stops || stops.length === 0)
            return "";

        const parts = [];
        for (let i = 0; i < stops.length; i++) {
            const s = stops[i];
            parts.push(s[0] + "@" + s[1]);
        }
        return parts.join(",");
    }

    /**
     * Get resolved gradient stops (with colors converted to actual color values).
     * Returns array of [resolvedColor, position] pairs.
     */
    function getResolvedStops(gradientStops) {
        if (!gradientStops || gradientStops.length === 0)
            return null;

        const key = _hashGradient(gradientStops);
        const cacheKey = key + "_v" + root.version;

        // Return cached resolved stops if exists
        if (root._cache[cacheKey]) {
            return root._cache[cacheKey];
        }

        // Resolve colors
        const resolved = [];
        for (let i = 0; i < gradientStops.length; i++) {
            const s = gradientStops[i];
            resolved.push([Config.resolveColor(s[0]), s[1]]);
        }

        root._cache[cacheKey] = resolved;
        return resolved;
    }

    /**
     * Invalidate cache when theme colors change.
     */
    function invalidateAll() {
        root.version++;
        // Clear old cache entries to free memory
        root._cache = {};
    }

    // Listen for color theme changes
    Connections {
        target: Colors
        function onLoaded() {
            root.invalidateAll();
        }
    }
}
