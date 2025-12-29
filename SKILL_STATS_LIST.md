# Skill Stats Icons Needed

**Total: 8 Skill Stats**

---

## Base Stats (4) - From PlayerStats System

1. **Resilience** (formerly STR/Strength)
   - Full name: Resilience
   - Affects: Carry weight, defense, damage reduction
   - Location: `PlayerStats.base_resilience`, `PlayerStats.get_total_resilience()`
   - Formula: `max_carry_weight = 45.0 + (resilience * 2.0) kg`
   - Damage reduction: `damage_reduction = resilience * 0.15` (15% per point)

2. **Agility** (formerly DEX/Dexterity)
   - Full name: Agility
   - Affects: Max stamina (Agility × 10), stamina consumption multiplier, movement speed
   - Location: `PlayerStats.base_agility`, `PlayerStats.get_total_agility()`
   - Formula: `max_stamina = agility * 10`
   - Stamina consumption: `multiplier = 1.0 - (agility * 0.02)` (2% reduction per point)
   - Movement speed: `multiplier = 1.0 + (agility * 0.03)` (3% increase per point)

3. **INT (Intelligence)**
   - Full name: Intelligence
   - Affects: Mana max (INT × 15), spell damage (INT × 2)
   - Location: `PlayerStats.base_int`, `PlayerStats.get_total_int()`

4. **VIT (Vitality)**
   - Full name: Vitality
   - Affects: Health max (VIT × 20)
   - Location: `PlayerStats.base_vit`, `PlayerStats.get_total_vit()`

---

## Element Levels (4) - From SpellSystem

5. **Fire Element Level**
   - Full name: Fire Magic
   - Color: Red (#FF4444)
   - Location: `SpellSystem.get_level("fire")`, `SpellSystem.get_xp("fire")`

6. **Water Element Level**
   - Full name: Water Magic
   - Color: Cyan (#44AAFF)
   - Location: `SpellSystem.get_level("water")`, `SpellSystem.get_xp("water")`

7. **Earth Element Level**
   - Full name: Earth Magic
   - Color: Green (#44AA44)
   - Location: `SpellSystem.get_level("earth")`, `SpellSystem.get_xp("earth")`

8. **Air Element Level**
   - Full name: Air Magic
   - Color: Light Blue (#88CCFF)
   - Location: `SpellSystem.get_level("air")`, `SpellSystem.get_xp("air")`

---

## Icon Specifications

**Recommended Size**: 32x32px or 40x40px (to match item icons)

**File Naming Convention** (suggestion):
- `stat_resilience.png` / `stat_resilience.png` (formerly stat_str.png)
- `stat_agility.png` / `stat_agility.png` (formerly stat_dex.png)
- `stat_int.png` / `stat_intelligence.png`
- `stat_vit.png` / `stat_vitality.png`
- `stat_fire.png` / `element_fire.png`
- `stat_water.png` / `element_water.png`
- `stat_earth.png` / `element_earth.png`
- `stat_air.png` / `element_air.png`

**Location** (suggestion):
- `assets/ui/icons/stats/` (for base stats)
- `assets/ui/icons/elements/` (for element levels)
- OR all in: `assets/ui/icons/skills/`

---

## Tab Structure (Updated)

1. **Tab 1: Quick Belt** - 5 consumable item slots
2. **Tab 2: Stats** - Base stats (Resilience, Agility, INT, VIT) with values
3. **Tab 3: Spells** - Spell hotbar configuration
4. **Tab 4: Settings** - Game settings (placeholder)

*Note: Element levels and XP bars will be shown in Tab 2 (Stats) as they are skill-related.*

