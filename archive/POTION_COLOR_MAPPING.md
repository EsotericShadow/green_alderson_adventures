# Potion Color Mapping Guide

**Purpose**: Map potion animation colors to actual gameplay mechanics and stats

---

## Color-to-Effect Mapping

### ✅ Already Set (Obvious)

1. **Health Potion** (`restore_health`)
   - **Color**: `health_potion_red/` (RED)
   - **Effect**: Restores 50 HP instantly
   - **Reason**: Red = health/blood (universal convention)

2. **Mana Potion** (`restore_mana`)
   - **Color**: `mana_potion_blue/` (BLUE)
   - **Effect**: Restores 30 MP instantly
   - **Reason**: Blue = magic/mana (universal convention)

3. **Stamina Potion** (`restore_stamina`)
   - **Color**: `stamina_potion_green/` (GREEN)
   - **Effect**: Restores 50 stamina instantly
   - **Reason**: Green = energy/stamina (universal convention)

4. **Defense Potion** (`buff_defense`)
   - **Color**: `resilience_potion_black/` (BLACK)
   - **Effect**: +15% damage reduction for 60 seconds
   - **Reason**: Black = resilience/defense (armor/durability feel)
   - **Game Mechanic**: Buffs Resilience stat → damage reduction

---

### 🎯 Recommended Mappings

5. **Speed Potion** (`buff_speed`)
   - **Color**: `YELLOW/` (YELLOW)
   - **Effect**: +25% movement speed for 45 seconds
   - **Reason**: Yellow = agility/speed (light/fast feel)
   - **Game Mechanic**: Buffs Agility stat → movement speed + stamina efficiency

6. **Strength Potion** (`buff_strength`)
   - **Color**: `orange/` (ORANGE)
   - **Effect**: +20% damage for 60 seconds
   - **Reason**: Orange = combat/power (fire/combat feel)
   - **Game Mechanic**: Damage multiplier buff (not a stat buff, but combat-related)
   - **Note**: Despite the name "strength", this is a damage buff, not a Resilience buff

---

### 🔮 Available for Future Potions

7. **Intelligence Potion** (if you add `buff_intelligence` effect)
   - **Color**: `intelligence_potion_cyan/` (CYAN)
   - **Potential Effect**: +X% spell damage for Y seconds
   - **Reason**: Cyan = intelligence/magic (matches spell system's air element color)
   - **Game Mechanic**: Would buff Intelligence stat → spell damage

8. **Vitality Potion** (if you add `buff_vitality` effect)
   - **Color**: `PINK/` (PINK)
   - **Potential Effect**: +X max HP for Y seconds, or HP regen over time
   - **Reason**: Pink = vitality/life force (softer than red health)
   - **Game Mechanic**: Would buff Vitality stat → max HP

9. **Gold Potion** (`restore_all`)
   - **Color**: `GOLD/` (GOLD)
   - **Effect**: Restores health + mana + stamina simultaneously (all-in-one elixir)
   - **Reason**: Gold = premium/rare/superior (universal convention)
   - **Game Mechanic**: Premium potion that restores all three resources at once
   - **Implementation**: Requires adding `"restore_all"` to PotionData effect enum
   - **Suggested Values**: 
     - `potency`: `50` (restores 50 HP, 50 MP, 50 stamina)
     - `duration`: `0.0` (instant)

---

## Summary Table

| Potion Effect | Color Folder | Stat/Mechanic | Rationale |
|--------------|--------------|---------------|-----------|
| `restore_health` | `health_potion_red/` | Instant HP restore | Red = health/blood |
| `restore_mana` | `mana_potion_blue/` | Instant MP restore | Blue = magic/mana |
| `restore_stamina` | `stamina_potion_green/` | Instant stamina restore | Green = energy/stamina |
| `buff_defense` | `resilience_potion_black/` | Resilience → damage reduction | Black = armor/defense |
| `buff_speed` | `YELLOW/` | Agility → movement speed | Yellow = speed/agility |
| `buff_strength` | `orange/` | Damage multiplier | Orange = combat/power |
| `restore_all` | `GOLD/` | Restores HP + MP + Stamina | Gold = premium/all-in-one |
| *(future)* `buff_intelligence` | `intelligence_potion_cyan/` | Intelligence → spell damage | Cyan = magic/intelligence |
| *(future)* `buff_vitality` | `PINK/` | Vitality → max HP | Pink = vitality/life |

---

## Implementation Notes

1. **Strength Potion** (`buff_strength`): Despite the name, this is a **damage multiplier**, not a Resilience stat buff. Orange fits the combat/power theme.

2. **Speed Potion** (`buff_speed`): Yellow represents agility/speed, which aligns with the Agility stat that affects movement speed and stamina.

3. **Defense Potion** (`buff_defense`): Black represents resilience/armor, which matches the Resilience stat that provides damage reduction.

4. **Future Potions**: If you add Intelligence or Vitality buff potions later, you already have the colors ready (CYAN and PINK).

5. **Gold Potion** (`restore_all`): Premium all-in-one elixir that restores health, mana, and stamina simultaneously. Requires adding `"restore_all"` to the PotionData effect enum and implementing the logic to restore all three resources.

6. **Gold Currency Icons**: Still needed separately for the HUD gold display (not a potion).

---

## File Paths for Resources

When creating PotionData resources, use these animation paths:

- Health Potion: `res://resources/assets/animations/potions/health_potion_red/`
- Mana Potion: `res://resources/assets/animations/potions/mana_potion_blue/`
- Stamina Potion: `res://resources/assets/animations/potions/stamina_potion_green/`
- Defense Potion: `res://resources/assets/animations/potions/resilience_potion_black/`
- Speed Potion: `res://resources/assets/animations/potions/YELLOW/`
- Strength Potion: `res://resources/assets/animations/potions/orange/`
- Gold Potion (All-in-One Elixir): `res://resources/assets/animations/potions/GOLD/`

---

**All potion colors mapped to gameplay mechanics!** ✅

**Implementation Note**: The Gold Potion requires adding `"restore_all"` to the PotionData effect enum and implementing logic to restore health, mana, and stamina simultaneously.

**Gold Currency Icons**: ✅ Provided in `res://resources/assets/gold_pieces/` - See `GOLD_ICONS_GUIDE.md` for details.

