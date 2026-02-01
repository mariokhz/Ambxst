# Media Player Component Hierarchy & Data Flow

## Component Tree

```
MprisController (Service Singleton)
├── activePlayer: MprisPlayer | null
├── filteredPlayers: MprisPlayer[]
├── Properties:
│   ├── isPlaying
│   ├── canTogglePlaying
│   ├── canGoNext
│   ├── canGoPrevious
│   ├── hasShuffle
│   ├── loopState
│   └── (all with ?. fallbacks)
│
└── Connected Components:
    │
    ├── FullPlayer (Dashboard)
    │   ├── CircularSeekBar (value, isDragging)
    │   ├── syncSeekBarPosition() method
    │   ├── Timer (updates each second)
    │   ├── Connections:
    │   │   ├── onActivePlayerChanged()
    │   │   ├── onPositionChanged()
    │   │   └── onDashboardOpenChanged()
    │   └── UI States:
    │       ├── hasActivePlayer = true → Shows all controls
    │       └── hasActivePlayer = false → Shows "Nothing Playing"
    │
    ├── CompactPlayer (Notch)
    │   ├── PositionSlider (slider.value)
    │   ├── Timer (updates each second)
    │   ├── Connections:
    │   │   └── onPositionChanged()
    │   └── UI States:
    │       ├── player !== null → Shows controls
    │       └── player === null → Shows WavyLine placeholder
    │
    └── LockPlayer (Lockscreen)
        ├── PositionSlider (positionSlider.value)
        ├── Timer (updates each second)
        ├── Connections:
        │   └── onPositionChanged()
        └── UI States:
            ├── activePlayer !== null → Shows player controls
            └── activePlayer === null → Shows WavyLine placeholder
```

---

## Data Flow: Playback Position Update

### Normal Playback Flow
```
MprisController.activePlayer (D-Bus Mpris Service)
         ↓
    position change
         ↓
   onPositionChanged() signal
         ↓
  ┌─────────────────────────────────────┐
  │ Component Connections (Async)       │
  ├─────────────────────────────────────┤
  │ 1. FullPlayer.syncSeekBarPosition() │
  │    → seekBar.value = pos/length      │
  │                                     │
  │ 2. CompactPlayer.onPositionChanged()│
  │    → slider.value = pos/length      │
  │                                     │
  │ 3. LockPlayer.onPositionChanged()   │
  │    → positionSlider.value = pos/len │
  └─────────────────────────────────────┘
         ↓
  StyledSlider/CircularSeekBar
         ↓
  Canvas draws progress ring/bar
```

### Player Null State Flow
```
All Players Disconnect
         ↓
MprisController.activePlayer = null
         ↓
activePlayerChanged() signal
         ↓
  ┌──────────────────────────────────────┐
  │ Component Reactions                  │
  ├──────────────────────────────────────┤
  │ 1. FullPlayer:                       │
  │    • Timer.running = false (isPlaying=false)
  │    • syncSeekBarPosition() checks    │
  │      hasActivePlayer (guards access) │
  │    • UI shows "Nothing Playing"      │
  │    ⚠️  seekBar.value NOT reset       │
  │                                      │
  │ 2. CompactPlayer:                    │
  │    • Timer.running = false           │
  │    • Shows WavyLine placeholder      │
  │    • slider.value defaults to 0      │
  │                                      │
  │ 3. LockPlayer:                       │
  │    • Timer.running = false           │
  │    • Shows WavyLine placeholder      │
  │    • positionSlider.value = 0        │
  │                                      │
  │ 4. MprisController:                  │
  │    • activePlayer → null             │
  │    • canTogglePlaying → false        │
  │    • Controls disabled by UI         │
  └──────────────────────────────────────┘
         ↓
  User Sees:
  • Disabled controls
  • Placeholder visuals
  • No playback animation
```

---

## Null-Safety Mechanism Diagram

```
User Interacts with Player UI
         ↓
onClicked: {
    │
    ├─ Check 1: isDragging guard
    │  if (isDragging && ...) 
    │      ✓ Continue
    │
    ├─ Check 2: Optional chaining
    │  if (root.player && root.player.canSeek)
    │      └─ Access only if exists
    │
    └─ Check 3: Property access
       root.player.position = value * root.length
       ✓ Safe because player checked above
}

If any check fails:
    → No-op (silent failure)
    → No crash, no error message
    → UI remains responsive
```

---

## Property Fallback Chain

```
Position Property Chain:
┌─────────────────────────────────────────────┐
│ property real position: player?.position ?? 0.0
│                         ↑                    ↑
│                    Optional            Default
│                    chaining            if null
└─────────────────────────────────────────────┘
    │                                          │
    ├─ If player exists                       │
    │  └─ Use player.position                 │
    │                                          │
    └─ If player is null                      │
       └─ Use 0.0 (safe default)

Length Property Chain:
┌─────────────────────────────────────────────┐
│ property real length: player?.length ?? 1.0 │
│                       ↑                  ↑   │
│                  Optional             Safe   │
│                  chaining          divisor   │
└─────────────────────────────────────────────┘
    │                                          │
    ├─ If player exists                       │
    │  └─ Use player.length                   │
    │                                          │
    └─ If player is null                      │
       └─ Use 1.0 (prevents divide-by-zero)

Value Calculation:
┌──────────────────────────────────────────────┐
│ value: root.length > 0                       │
│        ? Math.min(1.0, position / length)   │
│        : 0                                   │
│        ↑                                      │
│   Extra safety check                         │
└──────────────────────────────────────────────┘
    │                                           │
    ├─ If length > 0                           │
    │  └─ Calculate ratio (capped at 1.0)      │
    │                                           │
    └─ If length <= 0                          │
       └─ Use 0 (fail-safe default)
```

---

## State Machine: Active Player Lifecycle

```
┌─────────────────────────────────────────┐
│        No Players Available             │
│   (activePlayer === null)               │
├─────────────────────────────────────────┤
│ • Timer stops                           │
│ • Controls disabled                     │
│ • Placeholder shown                     │
│ • Value defaults to 0                   │
└──────────────┬──────────────────────────┘
               │
               │ Player connects
               ↓
┌─────────────────────────────────────────┐
│     Player Active & Stopped             │
│ (activePlayer !== null, !isPlaying)     │
├─────────────────────────────────────────┤
│ • Timer stops                           │
│ • Controls enabled but paused           │
│ • Progress shows: position/length       │
│ • Can click play to resume              │
└──────────────┬──────────────────────────┘
               │
               │ Play button clicked
               ↓
┌─────────────────────────────────────────┐
│         Player Playing                  │
│   (isPlaying === true)                  │
├─────────────────────────────────────────┤
│ • Timer starts (1s updates)             │
│ • Controls enabled                      │
│ • Position advances visually            │
│ • Wave animation runs on slider         │
│ • User can seek (updates position)      │
└──────────────┬──────────────────────────┘
               │
               │ Pause/Stop || Player closes
               ↓
        Back to above states
```

---

## Seek Operation Flow

```
User Drags Slider Handle
         ↓
MouseArea.onPressed:
    ├─ isDragging = true
    ├─ dragPosition = mouse position
    └─ if (!updateOnRelease):
           value = dragPosition  (optimistic update)
         ↓
MouseArea.onPositionChanged:
    ├─ if (isDragging):
    │   └─ dragPosition = mouse position (continuous update)
    │       └─ if (!updateOnRelease):
    │               value = dragPosition
         ↓
MouseArea.onReleased:
    ├─ isDragging = false
    ├─ finalValue = dragPosition
    ├─ if (snapMode === "release"):
    │   └─ finalValue = applyStep(finalValue)
    ├─ value = finalValue
    └─ dragPosition = finalValue (commit)
         ↓
Slider.onValueChanged:
    ├─ if (isDragging && player && player.canSeek):
    │   └─ player.position = value * length (D-Bus call)
    │       └─ D-Bus updates player
    │           └─ onPositionChanged() fires
    │               └─ Components update (see above)
         ↓
User Sees Progress Ring/Bar Move
```

---

## Timer-Based Position Update

```
┌─────────────────────────────────────────────┐
│ Timer.running = isPlaying                   │
│  (only runs when player exists AND playing) │
└──────────────┬──────────────────────────────┘
               │
               ├─ Each 1000ms:
               ├─────────────────────────────┐
               │ onTriggered():              │
               ├─────────────────────────────┤
               │ 1. Check if dragging        │
               │    if (isDragging) return   │ Skip if user manipulating
               │                             │
               │ 2. Calculate new value      │
               │    value = length > 0       │
               │           ? Math.min(       │
               │             1.0,            │
               │             position/length │
               │           ) : 0             │
               │                             │
               │ 3. Emit signal              │
               │    player.positionChanged() │
               └──────────────┬──────────────┘
                              │
                              ↓
                     Canvas repaints
                   (Smoothly advances
                    progress ring/bar)

Loop continues while isPlaying === true
    ↓
When player stops or becomes null:
    Timer automatically stops
```

---

## Component Dependency Graph

```
┌──────────────────────────┐
│   MprisController        │
│   (Service Singleton)    │
└────────┬─────────────────┘
         │
         │ Provides activePlayer
         │
    ┌────┴────┬────────┬────────┐
    │         │        │        │
    ↓         ↓        ↓        ↓
FullPlayer  Compact  Lock    Other
            Player   Player  Users


FullPlayer Dependencies:
├─ MprisController.activePlayer
│  ├─ position
│  ├─ length
│  ├─ playbackState
│  └─ trackArtUrl
│
├─ CircularSeekBar (UI component)
│  └─ value, isDragging, enabled
│
└─ GlobalStates.dashboardOpen (for re-sync)


CompactPlayer Dependencies:
├─ player (prop from parent)
│  ├─ position
│  ├─ length
│  ├─ playbackState
│  ├─ trackArtUrl
│  └─ canPause, canGoPrevious, canGoNext
│
└─ PositionSlider (child component)
   └─ player (passed down)


PositionSlider Dependencies:
├─ player (required prop)
│  ├─ position
│  ├─ length
│  └─ canSeek
│
└─ StyledSlider (child component)
   └─ value (calculated from position/length)
```

---

## Issue: CircularSeekBar Not Reset

```
Timeline: Player Lifecycle

┌────────────────────────────────┐
│ Song Playing                   │
│ Player = Spotify               │
│ Position = 1.5min / 3.0min     │
│ seekBar.value = 0.5 (50%)      │
│ 🎵 Circle shows at 50%         │
└────────────────────────────────┘
         │
         ↓ User stops player
         
┌────────────────────────────────┐
│ Player Stopped                 │
│ Player = Spotify               │
│ Position = 0.0                 │
│ seekBar.value = 0 (updated)    │
│ ✓ Circle resets to 0%          │
└────────────────────────────────┘
         │
         ↓ All players close (or new player)
         
┌────────────────────────────────┐
│ No Players / Player Changed    │
│ activePlayer = null            │
│ Position = undefined           │
│ seekBar.value = ??? STALE       │
│ ⚠️  Circle STILL at 50%         │
│    (No reset triggered)        │
└────────────────────────────────┘
         │
         ↓ User thinks music is still playing!
         
        🎵 Confusing UX
        
FIX: Add listener for activePlayer === null
    function onActivePlayerChanged() {
        if (!MprisController.activePlayer) {
            seekBar.value = 0;
        }
    }
```

---

## Safe Access Pattern Comparison

### ❌ UNSAFE (Can crash)
```qml
// Direct access without null check
text: activePlayer.trackTitle  // ← Crash if null!

// Division without zero check  
value: position / length        // ← NaN if length === 0

// Access in loop without guards
for (let i = 0; i < players.length; i++) {
    players[i].position = 0     // ← Crashes if player disappears mid-loop
}
```

### ✅ SAFE (Current pattern)
```qml
// Optional chaining + fallback
text: activePlayer?.trackTitle ?? "Nothing Playing"

// Division with guard
value: length > 0 ? position / length : 0

// Guard before connection
Connections {
    target: activePlayer
    function onPositionChanged() {
        if (activePlayer) { /* access */ }  // Double-check
    }
}
```

---

**End of Diagrams**
