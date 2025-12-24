# Combat Animation Assets - Main Character

## Directory: `assets/characters/main_character/animations/combat/`

### Light Attack
**Path**: `light-attack/`
**Directions**: 8 (N, S, E, W, NE, NW, SE, SW)
**Frames per direction**: 6
**Total frames**: 48

**Frame breakdown**:
- Frame 0-1: Windup (pull back)
- Frame 2-3: Swing (active hit)
- Frame 4-5: Recovery (return to idle)

**Files needed**:
```
light-attack/
├── north/
│   ├── frame_000.png
│   ├── frame_001.png
│   ├── frame_002.png
│   ├── frame_003.png
│   ├── frame_004.png
│   └── frame_005.png
├── south/
│   ├── frame_000.png
│   ├── frame_001.png
│   ├── frame_002.png
│   ├── frame_003.png
│   ├── frame_004.png
│   └── frame_005.png
├── east/
│   ├── frame_000.png
│   ├── frame_001.png
│   ├── frame_002.png
│   ├── frame_003.png
│   ├── frame_004.png
│   └── frame_005.png
├── west/
│   ├── frame_000.png
│   ├── frame_001.png
│   ├── frame_002.png
│   ├── frame_003.png
│   ├── frame_004.png
│   └── frame_005.png
├── north-east/
│   ├── frame_000.png
│   ├── frame_001.png
│   ├── frame_002.png
│   ├── frame_003.png
│   ├── frame_004.png
│   └── frame_005.png
├── north-west/
│   ├── frame_000.png
│   ├── frame_001.png
│   ├── frame_002.png
│   ├── frame_003.png
│   ├── frame_004.png
│   └── frame_005.png
├── south-east/
│   ├── frame_000.png
│   ├── frame_001.png
│   ├── frame_002.png
│   ├── frame_003.png
│   ├── frame_004.png
│   └── frame_005.png
└── south-west/
    ├── frame_000.png
    ├── frame_001.png
    ├── frame_002.png
    ├── frame_003.png
    ├── frame_004.png
    └── frame_005.png
```

**Specifications**:
- Size: 32x32 pixels
- Format: PNG with transparency
- Style: Matches existing walk/run animations
- Sword must be visible throughout animation

---

### Heavy Attack
**Path**: `heavy-attack/`
**Directions**: 8
**Frames per direction**: 8
**Total frames**: 64

**Frame breakdown**:
- Frame 0-2: Windup (longer pull back)
- Frame 3-5: Swing (powerful strike)
- Frame 6-7: Recovery (slower return)

**Files needed**: Same structure as light-attack, but 8 frames per direction

---

### Block Stance
**Path**: `block-stance/`
**Directions**: 8
**Frames per direction**: 3
**Total frames**: 24

**Frame breakdown**:
- Frame 0: Enter block
- Frame 1: Hold block
- Frame 2: Exit block

**Files needed**: Same structure as light-attack, but 3 frames per direction

---

### Parry Stance
**Path**: `parry-stance/`
**Directions**: 8
**Frames per direction**: 4
**Total frames**: 32

**Files needed**: Same structure as light-attack, but 4 frames per direction

---

### Block Impact Reaction
**Path**: `block-impact/`
**Directions**: 8
**Frames per direction**: 4
**Total frames**: 32

**Frame breakdown**:
- Frame 0-1: Impact
- Frame 2-3: Recoil recovery

**Files needed**: Same structure as light-attack, but 4 frames per direction

---

### Parry Success
**Path**: `parry-success/`
**Directions**: 8
**Frames per direction**: 5
**Total frames**: 40

**Frame breakdown**:
- Frame 0-1: Parry contact
- Frame 2: Spark/flash
- Frame 3-4: Counter-ready pose

**Files needed**: Same structure as light-attack, but 5 frames per direction

---

### Hit Reaction
**Path**: `hit-reaction/`
**Directions**: 8
**Frames per direction**: 4
**Total frames**: 32

**Frame breakdown**:
- Frame 0: Hit impact
- Frame 1: Flinch
- Frame 2: Red flash
- Frame 3: Recoil

**Files needed**: Same structure as light-attack, but 4 frames per direction

---

### Death Animation
**Path**: `death/`
**Directions**: 1 (south-facing, can rotate)
**Frames**: 8
**Total frames**: 8

**Frame breakdown**:
- Frame 0-2: Stagger
- Frame 3-5: Fall
- Frame 6-7: Fade out

**Files needed**:
```
death/
└── south/
    ├── frame_000.png
    ├── frame_001.png
    ├── frame_002.png
    ├── frame_003.png
    ├── frame_004.png
    ├── frame_005.png
    ├── frame_006.png
    └── frame_007.png
```

---

## Total Combat Animation Files Needed

**Total**: 280 individual PNG files

**Cost Estimate**: $200-400 (all combat animations)

**Priority**: 🔴 ESSENTIAL

**Style Reference**: Use existing `walk/south/` and `breathing-idle/south/` animations

