# Gold Icons Guide

**Purpose**: Document gold coin icons for HUD display

---

## Icon Location

**Path**: `res://resources/assets/gold_pieces/`

---

## Available Icons

| Icon File | Gold Amount Range | Use Case |
|-----------|-------------------|----------|
| `1_coin.png` | 1 gold | Single coin |
| `2_coins.png` | 2 gold | Two coins |
| `3_coins.png` | 3 gold | Three coins |
| `4_coins.png` | 4 gold | Four coins |
| `5_coins.png` | 5 gold | Five coins |
| `6_coins.png` | 6 gold | Six coins |
| `7-9_coins.png` | 7-9 gold | Small stack |
| `20-50_coins.png` | 20-50 gold | Medium stack |
| `50-99_coins.png` | 50-99 gold | Large stack |
| `100+_coins.png` | 100+ gold | Huge stack |

---

## Icon Selection Logic

When displaying gold in the HUD, select the appropriate icon based on the current gold amount:

```gdscript
func get_gold_icon_path(amount: int) -> String:
    if amount <= 1:
        return "res://resources/assets/gold_pieces/1_coin.png"
    elif amount == 2:
        return "res://resources/assets/gold_pieces/2_coins.png"
    elif amount == 3:
        return "res://resources/assets/gold_pieces/3_coins.png"
    elif amount == 4:
        return "res://resources/assets/gold_pieces/4_coins.png"
    elif amount == 5:
        return "res://resources/assets/gold_pieces/5_coins.png"
    elif amount == 6:
        return "res://resources/assets/gold_pieces/6_coins.png"
    elif amount >= 7 and amount <= 9:
        return "res://resources/assets/gold_pieces/7-9_coins.png"
    elif amount >= 20 and amount <= 49:
        return "res://resources/assets/gold_pieces/20-50_coins.png"
    elif amount >= 50 and amount <= 99:
        return "res://resources/assets/gold_pieces/50-99_coins.png"
    else:  # amount >= 100
        return "res://resources/assets/gold_pieces/100+_coins.png"
```

**Note**: There's a gap between 10-19 gold. For these amounts, use `7-9_coins.png` as a fallback, or add a new icon if needed.

---

## Implementation

### Gold Display UI Component

**Location**: `res://scenes/ui/gold_display.tscn` (to be created in Milestone 5)

**Structure**:
```
GoldDisplay (HBoxContainer)
├── TextureRect (gold icon)
└── Label (gold amount text)
```

**Script**: `res://scripts/ui/gold_display.gd` (to be created)

**Functionality**:
- Listens to `CurrencySystem.gold_changed` signal
- Updates icon based on gold amount (using logic above)
- Updates text label with current gold amount
- Positioned in HUD (top-left, below resource bars)

---

## Integration with CurrencySystem

The `CurrencySystem` autoload already emits `gold_changed(amount: int)` signal when gold changes.

**Connection**:
```gdscript
# In gold_display.gd _ready()
CurrencySystem.gold_changed.connect(_on_gold_changed)

func _on_gold_changed(amount: int) -> void:
    update_gold_display(amount)

func update_gold_display(amount: int) -> void:
    # Update icon
    var icon_path = get_gold_icon_path(amount)
    $TextureRect.texture = load(icon_path)
    
    # Update text
    $Label.text = str(amount)
```

---

## HUD Integration

**File**: `res://scenes/ui/hud.tscn`

Add gold display to HUD:
```
HUD (CanvasLayer)
├── HealthBar
├── ManaBar
├── StaminaBar
└── GoldDisplay (new)
```

---

## Notes

- **Icon Updates**: Icons change dynamically based on gold amount for visual feedback
- **Performance**: Icons are loaded on-demand when gold changes (not preloaded)
- **Future Enhancement**: Could add animation when gold amount changes
- **Gap Handling**: Amounts 10-19 currently use `7-9_coins.png` as fallback

---

**Status**: ✅ Icons provided and documented. Gold display UI component to be implemented in Milestone 5 (Commit 5A).

