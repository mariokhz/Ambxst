# Media Player Components - Code Reference & Fixes

## Quick Reference

### Files Analyzed
| File | Type | Purpose | Progress Component |
|------|------|---------|-------------------|
| `PositionSlider.qml` | Reusable | Horizontal slider for position | StyledSlider |
| `CircularSeekBar.qml` | Reusable | Circular progress ring | Canvas |
| `StyledSlider.qml` | Reusable | Generic horizontal slider | Canvas |
| `CompactPlayer.qml` | Widget | Notch media player | PositionSlider |
| `FullPlayer.qml` | Widget | Dashboard media player | CircularSeekBar |
| `LockPlayer.qml` | Widget | Lockscreen media player | PositionSlider |
| `MprisController.qml` | Service | Media service singleton | N/A (backend) |

---

## Code Snippets: Safe Progress Handling

### 1. PositionSlider - The Gold Standard

```qml
// ✅ SAFE: Complete null-safety pattern
property real position: player?.position ?? 0.0
property real length: player?.length ?? 1.0

property alias value: slider.value
property alias isDragging: slider.isDragging

StyledSlider {
    id: slider
    anchors.fill: parent
    
    // Safe value calculation (3 levels of defense)
    value: root.length > 0 
        ? Math.min(1.0, root.position / root.length) 
        : 0
    
    // Only seek when player exists
    onValueChanged: {
        if (isDragging && root.player && root.player.canSeek) {
            root.player.position = value * root.length;
        }
    }
}
```

**Why This Works:**
1. **Optional chaining**: `player?.position` returns undefined if null
2. **Fallback value**: `?? 0.0` provides safe default
3. **Guard check**: `root.length > 0` prevents NaN
4. **Capped value**: `Math.min(1.0, ...)` prevents overflow
5. **Double guard**: `if (root.player && ...)` before D-Bus call

---

### 2. FullPlayer - Complex Sync Pattern

```qml
// ✅ SAFE: Multi-point synchronization
property bool hasActivePlayer: MprisController.activePlayer !== null

// Function with triple guard
function syncSeekBarPosition() {
    if (!seekBar.isDragging && !player.isSeeking && player.hasActivePlayer) {
        seekBar.value = player.length > 0 
            ? player.position / player.length 
            : 0;
    }
}

// Sync trigger 1: Position changes
Connections {
    target: MprisController.activePlayer
    function onPositionChanged() {
        syncSeekBarPosition();
    }
}

// Sync trigger 2: Player changes
Connections {
    target: MprisController
    function onActivePlayerChanged() {
        Qt.callLater(syncSeekBarPosition);  // Deferred to avoid race
    }
}

// Sync trigger 3: Dashboard visibility
Connections {
    target: GlobalStates
    function onDashboardOpenChanged() {
        if (GlobalStates.dashboardOpen) {
            Qt.callLater(syncSeekBarPosition);
        }
    }
}
```

**Pattern Explanation:**
- **Guard 1** (`!isDragging`): Don't interrupt user drag
- **Guard 2** (`!isSeeking`): Don't interrupt D-Bus position updates  
- **Guard 3** (`hasActivePlayer`): Only sync if player exists
- **Deferred updates**: Use `Qt.callLater()` to avoid race conditions

---

### 3. Timer-Based Updates

```qml
// ✅ SAFE: Timer-based position refresh
Timer {
    running: compactPlayer.isPlaying  // Only runs when: player exists AND playing
    interval: 1000
    repeat: true
    onTriggered: {
        // Skip if user is dragging
        if (!positionSlider.isDragging) {
            // Safe calculation (guarded division)
            positionSlider.value = compactPlayer.length > 0 
                ? Math.min(1.0, compactPlayer.position / compactPlayer.length) 
                : 0;
        }
        // Emit signal to trigger listeners
        compactPlayer.player?.positionChanged();
    }
}
```

**Why Timer is Safe:**
- Only runs if `isPlaying === true`
- When player is null, `isPlaying` is false (from optional chaining)
- Timer automatically stops when player becomes null

---

### 4. MprisController - Service Pattern

```qml
pragma Singleton
import Quickshell.Services.Mpris

Singleton {
    id: root
    
    // ✅ SAFE: Three-level player selection
    property var filteredPlayers: {
        const filtered = Mpris.players.values.filter(player => {
            const dbusName = (player.dbusName || "").toLowerCase();
            // Filter out unwanted players
            if (!Config.bar.enableFirefoxPlayer && dbusName.includes("firefox")) {
                return false;
            }
            return true;
        });
        return filtered;
    }
    
    // Fallback chain:
    // 1. Try tracked (user preference)
    // 2. Try first filtered player
    // 3. Return null if no players
    property var activePlayer: trackedPlayer ?? filteredPlayers[0] ?? null
    
    // ✅ SAFE: Control methods with null-safety
    property bool canTogglePlaying: root.activePlayer?.canTogglePlaying ?? false
    function togglePlaying() {
        if (root.canTogglePlaying) {
            root.activePlayer.togglePlaying();
        }
    }
    
    // ✅ SAFE: Handle player destruction
    Component.onDestruction: {
        if (root.trackedPlayer == null || !root.trackedPlayer.isPlaying) {
            // Find another playing player
            for (const player of root.filteredPlayers) {
                if (player.playbackState === MprisPlaybackState.Playing) {
                    root.trackedPlayer = player;
                    return;
                }
            }
        }
        // Fall back to first available if no one playing
        if (root.trackedPlayer == null && root.filteredPlayers.length != 0) {
            root.trackedPlayer = root.filteredPlayers[0];
        }
    }
}
```

---

## Issues & Fixes

### Issue 1: CircularSeekBar Not Reset on Player Null ⚠️

**Location:** `FullPlayer.qml` (around line 236)

**Problem:**
```qml
CircularSeekBar {
    id: seekBar
    value: 0  // Never updated when activePlayer becomes null
    // When player closes, value stays at last position
    // User sees progress ring at 50% even though nothing is playing
}
```

**Current Behavior:**
- When player changes: `value` might not update if `syncSeekBarPosition()` isn't called
- When player becomes null: `value` definitely doesn't reset (no code triggers it)
- **Visual Result:** Stale progress ring suggests music still playing

**Fix (Recommended):**

```qml
// In FullPlayer.qml, add to Connections for activePlayer change
Connections {
    target: MprisController
    function onActivePlayerChanged() {
        if (!MprisController.activePlayer) {
            // Reset seek bar when no player active
            seekBar.value = 0;
        } else {
            // Sync when new player becomes active
            Qt.callLater(syncSeekBarPosition);
        }
    }
}
```

**Severity:** Low (cosmetic only - no crash risk)  
**User Impact:** Confusing UI temporarily shows old progress position

---

### Issue 2: PositionSlider Length Fallback ⚠️

**Location:** `PositionSlider.qml` (line 17)

**Current Code:**
```qml
property real length: player?.length ?? 1.0
```

**Potential Confusion:**
- When player is null: `length = 1.0` (not 0!)
- If someone uses `length` directly elsewhere, might expect 0
- In practice: **Not an issue** because `position` is also 0, so `0/1 = 0` (correct)

**Why It's OK:**
```qml
// The value calculation compensates:
value: root.length > 0 
    ? Math.min(1.0, root.position / root.length)  // 0 / 1.0 = 0 ✓
    : 0                                            // fallback not used
```

**Recommendation:** Add clarifying comment

```qml
// Use 1.0 as fallback to prevent division by zero
// Safe because position is also 0.0 when player is null
property real length: player?.length ?? 1.0
```

---

### Issue 3: Hardcoded Defaults

**Current Pattern:**
```qml
property real position: player?.position ?? 0.0
property real length: player?.length ?? 1.0
```

**Recommendation:** Define constants for clarity

```qml
readonly property real defaultPosition: 0.0
readonly property real defaultLength: 1.0

property real position: player?.position ?? defaultPosition
property real length: player?.length ?? defaultLength
```

---

## Best Practices Summary

### ✅ Do Use

1. **Optional Chaining with Fallback**
   ```qml
   text: activePlayer?.trackTitle ?? "Nothing Playing"
   ```

2. **Conditional Guards**
   ```qml
   if (isDragging && player && player.canSeek) { /* ... */ }
   ```

3. **Safe Division**
   ```qml
   value: length > 0 ? position / length : 0
   ```

4. **Timer Conditions**
   ```qml
   Timer {
       running: isPlaying  // Stops automatically when false
   }
   ```

5. **Deferred Updates**
   ```qml
   Qt.callLater(syncPosition);  // Avoid race conditions
   ```

6. **Null Checks in Connections**
   ```qml
   Connections {
       target: activePlayer  // Safe if null
       function onSignal() {
           if (activePlayer) { /* access properties */ }
       }
   }
   ```

---

### ❌ Don't Use

1. **Direct Null Access**
   ```qml
   text: activePlayer.trackTitle  // ← Crash!
   ```

2. **Unsafe Division**
   ```qml
   value: position / length  // ← NaN if length = 0
   ```

3. **Unconditional Timers**
   ```qml
   Timer {
       running: true  // Always runs, wastes CPU
   }
   ```

4. **Stale Signal Connections**
   ```qml
   // Bad: Connection stays active even if target becomes null
   Connections {
       target: player
       // No null check in handler
   }
   ```

5. **No-op Seeks**
   ```qml
   // Bad: No feedback if seek fails
   player.position = newValue
   ```

---

## Testing Checklist

### Unit Tests

- [ ] `PositionSlider` with null player
  ```qml
  player = null
  // Expected: value = 0, no crashes
  ```

- [ ] `CircularSeekBar` manual drag to value
  ```qml
  isDragging = true
  dragValue = 0.5
  // Expected: canvas updates, handle moves
  ```

- [ ] `CompactPlayer` timer stops on null
  ```qml
  player = null
  // Expected: timer.running = false
  ```

### Integration Tests

- [ ] Full player lifecycle
  1. No player → "Nothing Playing"
  2. Player starts → Progress shows
  3. Player stops → Progress frozen
  4. Player closes → Back to "Nothing Playing"

- [ ] Rapid player changes
  - Switch between multiple players quickly
  - Expected: No race conditions, accurate progress

- [ ] Seek during player change
  - Start seeking, player changes mid-drag
  - Expected: Seek either completes or cancels gracefully

- [ ] Dashboard visibility
  - Open/close dashboard while playing
  - Expected: Progress syncs accurately on reopen

---

## Refactoring Ideas

### 1. Extract Safe Position Calculation

Create a shared utility:

```qml
// Suggested: modules/utils/PlayerUtils.qml
pragma Singleton

import QtQml

QtObject {
    id: root
    
    function calculateProgress(position, length) {
        if (!position || !length) return 0;
        if (length <= 0) return 0;
        return Math.min(1.0, position / length);
    }
    
    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "--:--";
        const totalSeconds = Math.floor(seconds);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const secs = totalSeconds % 60;
        
        if (hours > 0) {
            return `${hours}:${minutes < 10 ? '0' : ''}${minutes}:${secs < 10 ? '0' : ''}${secs}`;
        }
        return `${minutes}:${secs < 10 ? '0' : ''}${secs}`;
    }
    
    function canControlPlayer(player) {
        return player !== null && player.canControl;
    }
}
```

**Usage:**
```qml
import qs.modules.utils

value: PlayerUtils.calculateProgress(position, length)
```

---

### 2. Create PlayerState Enum

```qml
// Suggested: modules/utils/PlayerStates.qml

pragma Singleton
import QtQml

QtObject {
    readonly property int NONE = 0           // No player
    readonly property int STOPPED = 1        // Player exists, not playing
    readonly property int PLAYING = 2        // Player exists, playing
    readonly property int PAUSED = 3         // Player exists, paused
    readonly property int SEEKING = 4        // User adjusting position
    
    function getState(player, isDragging, isSeeking) {
        if (!player) return NONE;
        if (isDragging || isSeeking) return SEEKING;
        if (player.playbackState === MprisPlaybackState.Playing) return PLAYING;
        if (player.playbackState === MprisPlaybackState.Paused) return PAUSED;
        return STOPPED;
    }
}
```

---

### 3. Unified Player Sync Service

Create a singleton to handle all syncing:

```qml
// Suggested: modules/services/PlayerSyncService.qml

pragma Singleton

QtObject {
    id: root
    
    property var playerSliders: []
    property var playerRings: []
    
    function registerSlider(slider, playerRef) {
        playerSliders.push({
            slider: slider,
            playerRef: playerRef
        });
    }
    
    function registerRing(ring, playerRef) {
        playerRings.push({
            ring: ring,
            playerRef: playerRef
        });
    }
    
    function syncAll() {
        playerSliders.forEach(entry => {
            if (entry.playerRef) {
                entry.slider.value = calculateProgress(
                    entry.playerRef.position,
                    entry.playerRef.length
                );
            }
        });
        playerRings.forEach(entry => {
            if (entry.playerRef) {
                entry.ring.value = calculateProgress(
                    entry.playerRef.position,
                    entry.playerRef.length
                );
            } else {
                entry.ring.value = 0;  // Reset ring when player is null
            }
        });
    }
    
    function calculateProgress(position, length) {
        if (!position || !length) return 0;
        if (length <= 0) return 0;
        return Math.min(1.0, position / length);
    }
}
```

---

## Performance Notes

### Timer Efficiency
```qml
// ✅ EFFICIENT: Timer only runs when needed
Timer {
    running: isPlaying  // Stops automatically when false
    interval: 1000
    repeat: true
}
```

**Performance Impact:** Negligible (one 1Hz timer per active player)

### Canvas Drawing
```qml
// ✅ EFFICIENT: Repaints only when needed
Connections {
    target: progressCanvas
    function onProgressChanged() {
        canvas.requestPaint();  // Throttled by Qt
    }
}
```

**Performance Impact:** ~60 FPS canvas redraws (GPU-accelerated on most systems)

### Signal Connections
```qml
// ⚠️ WARNING: Each connection creates overhead
Connections {
    target: activePlayer  // Safe if null (Qt handles it)
    function onPositionChanged() { /* ... */ }
}
```

**Performance Impact:** Each component has ~3-4 connections (acceptable for <5 player widgets)

---

## Debugging Tips

### Enable Null Player Logging

```qml
// Temporary debugging helper
property bool debugMode: true

onActivePlayerChanged: {
    if (debugMode) {
        if (!activePlayer) {
            console.warn("Active player became null");
        } else {
            console.log("Active player changed to:", activePlayer.identity);
        }
    }
}
```

### Trace Value Updates

```qml
property real position: MprisController.activePlayer?.position ?? 0.0
onPositionChanged: {
    if (debugMode) {
        console.log("Position:", position, "Length:", length, "Value:", value);
    }
}
```

### Check Timer State

```qml
Timer {
    running: isPlaying
    onRunningChanged: {
        if (debugMode) {
            console.log("Timer running:", running, "isPlaying:", isPlaying);
        }
    }
}
```

---

## Migration Guide (If Refactoring)

### Step 1: Audit Current Usage
```bash
grep -r "activePlayer\." modules/widgets/ --include="*.qml" | \
  grep -v "activePlayer\?\."
```

### Step 2: Create Fallback Utilities
- Add `PlayerUtils.qml` with safe calculations
- Test thoroughly with null players

### Step 3: Update Components Incrementally
1. Start with lowest-level components (`StyledSlider`, `CircularSeekBar`)
2. Move to mid-level (`PositionSlider`)
3. Finally update high-level widgets (`CompactPlayer`, `FullPlayer`, `LockPlayer`)

### Step 4: Regression Testing
- Test each modification thoroughly
- Monitor for performance changes
- Verify no new issues with null players

---

**End of Code Reference**
