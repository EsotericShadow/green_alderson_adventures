# Alchemy Tools and Consumables Integration Plan

**Purpose**: Plan for integrating alchemy tools (mortar & pestle, elixir vials) and special consumables (sigils, glyphs, tokens) into the game systems.

**Architecture Compliance**: This plan strictly follows our established architecture:
- ✅ **Coordinator/Worker Pattern**: Coordinators make decisions, workers execute tasks
- ✅ **Single Responsibility**: Each system/class has ONE clear purpose
- ✅ **No God Objects**: Systems are focused and delegate to workers
- ✅ **EventBus Communication**: Decoupled communication via signals
- ✅ **Existing Systems**: Extends existing systems (`SpellSystem`, `PlayerStats`, `BaseEnemy`) rather than creating new singletons

---

## Overview

### Asset Categories

1. **Alchemy Tools** (`res://resources/assets/alchemy_tools/`)
   - **Mortar and Pestle**: Crafting tool (not consumable)
   - **Empty Elixir Vial**: Base container for potion crafting
   - **8 Filled Elixir Vials**: Dual-purpose items (consumables with effects + ingredients for advanced potions)

2. **Special Consumables** (`res://resources/assets/consumables/`)
   - **8 Unique Consumables**: Sigils, glyphs, tokens, disks with special combat/utility effects

---

## Part 1: Alchemy Tools

### 1.1 Mortar and Pestle (`mortar_and_pestle.jpg`)

**Type**: Crafting Tool (not a consumable item)

**Purpose**: 
- Required equipment for grinding ingredients
- May be needed as a crafting requirement for certain recipes
- Could unlock advanced recipes when in inventory

**Implementation**:
- **ItemData** resource with `item_type = "material"` (or potentially a new `"tool"` type)
- **Properties**:
  - `id`: `"mortar_and_pestle"`
  - `display_name`: `"Mortar and Pestle"`
  - `description`: `"A heavy stone mortar and pestle used for grinding herbs and crystals into fine powders. Essential for advanced alchemy."`
  - `stackable`: `false` (unique tool)
  - `max_stack`: `1`
  - `item_type`: `"material"` (or extend enum to include `"tool"`)
  - `weight`: `2.0` (heavy tool)

**Crafting Integration**:
- Some recipes may require Mortar and Pestle in inventory (not consumed)
- Advanced recipes unlock when player has Mortar and Pestle
- Could add a `required_tools: Array[ItemData]` to `RecipeData` (future enhancement)

---

### 1.2 Empty Elixir Vial (`empty_elixir_vial.jpg`)

**Type**: Crafting Material

**Purpose**: 
- Base container required for crafting potions
- Consumed during potion creation
- Acts as a "bottle" ingredient

**Implementation**:
- **ItemData** resource
- **Properties**:
  - `id`: `"empty_elixir_vial"`
  - `display_name`: `"Empty Elixir Vial"`
  - `description`: `"A clean, empty glass vial ready to be filled with alchemical concoctions."`
  - `stackable`: `true`
  - `max_stack`: `99`
  - `item_type`: `"material"`
  - `weight`: `0.1`

**Recipe Integration**:
- All potion recipes should require 1 Empty Elixir Vial
- Update existing recipes to include this ingredient
- Example: Health Potion = 1 Empty Vial + 2 Stonebloom + 1 Red Cap Mushroom

---

### 1.3 Filled Elixir Vials (8 types)

**Type**: Dual-Purpose (Consumable + Ingredient)

**Concept**: These vials contain magical substances that:
1. **Can be consumed directly** for immediate effects (like potions)
2. **Can be used as ingredients** in advanced potion recipes (like ingredients)

**Implementation Strategy**:
- Create **PotionData** resources (for consumption)
- Also create **ItemData** resources (for use as ingredients)
- OR: Extend `PotionData` to support being used as recipe ingredients
- **Recommendation**: Create both `PotionData` (consumable) AND `ItemData` (ingredient) versions, or extend `RecipeData` to accept `PotionData` as ingredients

---

#### 1.3.1 Blood Filled Elixir Vial (`blood_filled_elixir_vial.jpg`)

**Consumable Effect**:
- **Effect**: `restore_health` (instant)
- **Potency**: `75` HP
- **Duration**: `0.0` (instant)
- **Description**: `"A vial filled with crimson blood essence. Restores health when consumed."`

**As Ingredient**:
- Used in advanced health potions
- Used in strength/combat potions (blood = vitality/strength)
- **Suggested Recipe**: Greater Health Potion = 1 Blood Vial + 2 Red Cap Mushroom + 1 Healing Moss

---

#### 1.3.2 Water Filled Elixir Vial (`water_filled_elixir_vial.jpg`)

**Consumable Effect**:
- **Effect**: `restore_mana` (instant)
- **Potency**: `50` MP
- **Duration**: `0.0` (instant)
- **Description**: `"Pure magical water collected from a sacred spring. Restores mana when consumed."`

**As Ingredient**:
- Used in mana potions
- Used in water-element potions
- **Suggested Recipe**: Greater Mana Potion = 1 Water Vial + 2 Mana Crystal + 1 Azure Kelp

---

#### 1.3.3 Wisdom Filled Elixir Vial (`wisdom_filled_elixir_vial.jpg`)

**Consumable Effect**:
- **Effect**: `buff_intelligence` (NEW - needs to be added to PotionData enum)
- **Potency**: `+5` INT (temporary)
- **Duration**: `300.0` seconds (5 minutes)
- **Description**: `"An elixir infused with ancient wisdom. Temporarily boosts intelligence and spell power."`

**As Ingredient**:
- Used in intelligence potions
- Used in spell-enhancement potions
- **Suggested Recipe**: Intelligence Boost Potion = 1 Wisdom Vial + 2 Wise Shade + 1 Arcane Powder

**Note**: Requires adding `"buff_intelligence"` to `PotionData.effect` enum

---

#### 1.3.4 Ether Filled Elixir Vial (`ether_filled_elixir_vial.jpg`)

**Consumable Effect**:
- **Effect**: `restore_all` (instant)
- **Potency**: `40` (restores 40 HP, 40 MP, 40 stamina)
- **Duration**: `0.0` (instant)
- **Description**: `"Ethereal essence that restores all resources. A rare and valuable elixir."`

**As Ingredient**:
- Used in premium potions
- Used in "restore all" potions
- **Suggested Recipe**: Gold Potion = 1 Ether Vial + 1 Phoenix Feather + 1 Mana Crystal

---

#### 1.3.5 Psychotropic Filled Elixir Vial (`psychotropic_filled_elixir_vial.jpg`)

**Consumable Effect**:
- **Effect**: `buff_speed` (temporary)
- **Potency**: `+30%` movement speed
- **Duration**: `180.0` seconds (3 minutes)
- **Description**: `"A mind-altering elixir that heightens perception and reaction time. Increases movement speed."`

**As Ingredient**:
- Used in speed potions
- Used in agility potions
- **Suggested Recipe**: Speed Potion = 1 Psychotropic Vial + 2 Swiftroot + 1 Spider Silk

---

#### 1.3.6 Spectral Fluid Filled Elixir Vial (`spectral_fluid_filled_elixir_vial.jpg`)

**Consumable Effect**:
- **Effect**: `buff_defense` (temporary)
- **Potency**: `+20%` damage reduction
- **Duration**: `240.0` seconds (4 minutes)
- **Description**: `"Ghostly fluid that phases through matter. Provides temporary damage reduction."`

**As Ingredient**:
- Used in defense potions
- Used in resistance potions
- **Suggested Recipe**: Defense Potion = 1 Spectral Fluid Vial + 2 Stonebloom + 1 Healing Moss

---

#### 1.3.7 Dark Matter Filled Elixir Vial (`dark_matter_filled_elixir_vial.jpg`)

**Consumable Effect**:
- **Effect**: `buff_strength` (temporary)
- **Potency**: `+25%` damage
- **Duration**: `180.0` seconds (3 minutes)
- **Description**: `"Condensed dark matter that enhances physical power. Temporarily increases damage dealt."`

**As Ingredient**:
- Used in strength potions
- Used in combat potions
- **Suggested Recipe**: Strength Potion = 1 Dark Matter Vial + 2 Orc Fang + 1 Phoenix Feather

---

#### 1.3.8 Water Filled Elixir Vial (Duplicate Name Issue)

**Note**: There are TWO files with similar names:
- `water_filled_elixir_vial.jpg` (already mapped above)
- Possibly a duplicate or different variant?

**Action**: Verify if this is a duplicate or if one should be renamed (e.g., `pure_water_vial.jpg`)

---

## Part 2: Special Consumables

**Type**: Unique Consumables with Special Effects

**Implementation Strategy**:
- These don't fit the standard `PotionData` system (they have unique, non-standard effects)
- **Option 1**: Extend `PotionData` with new effect types
- **Option 2**: Create a new `ConsumableData` resource class that extends `ItemData`
- **Option 3**: Use `PotionData` with custom effect handlers

**Recommendation**: Extend `PotionData.effect` enum with new effect types, OR create a `SpecialConsumableData` class that extends `PotionData` with additional properties.

---

### 2.1 Deepwater Script (`Deepwater_Script.jpg`)

**Effect**: Boosts water spells
**Description**: `"An ancient script written in flowing ink that ripples like water. Enhances water spell damage and effectiveness."`

**Implementation**:
- **Effect Type**: `"buff_water_spells"` (NEW)
- **Potency**: `+30%` water spell damage
- **Duration**: `300.0` seconds (5 minutes)
- **Mechanic**: 
  - When consumed, applies a temporary buff to `SpellSystem`
  - Water spells deal increased damage while buff is active
  - Requires tracking buffs in `SpellSystem` or `PlayerStats`

**System Changes Needed**:
- **In `SpellSystem`**: Add `element_damage_multipliers` Dictionary and buff tracking
- **In `PotionData`**: Add `buff_water_spells` to effect enum
- **In `PotionConsumptionHandler`**: Add handler that calls `SpellSystem.apply_element_buff()`
- **Architecture**: Buff state lives in `SpellSystem` (not a separate BuffSystem)

---

### 2.2 Voidward Glyph (`Voidward_Glyph.jpg`)

**Effect**: Reduces curse effects
**Description**: `"A forbidden glyph that wards against dark magic. Reduces damage from curse-type effects. Illegal in some regions."`

**Implementation**:
- **Effect Type**: `"buff_curse_resistance"` (NEW)
- **Potency**: `+50%` curse resistance
- **Duration**: `600.0` seconds (10 minutes)
- **Mechanic**:
  - Reduces damage from "curse" type attacks
  - Requires curse damage type system (may not exist yet)
  - **Alternative**: If curse system doesn't exist, treat as `buff_defense` with longer duration

**System Changes Needed**:
- Add curse damage type to combat system (future)
- OR: Use as enhanced `buff_defense` for now

---

### 2.3 Ashpulse Knot (`Ashpulse_Knot.jpg`)

**Effect**: Area fire pulse
**Description**: `"A smoldering knot that releases a burst of fire in all directions when activated. Turns to soot after use."`

**Implementation**:
- **Effect Type**: `"area_fire_damage"` (NEW - instant combat effect)
- **Potency**: `50` fire damage in radius
- **Duration**: `0.0` (instant)
- **Mechanic**:
  - When consumed, deals fire damage to all enemies in radius around player
  - Requires area damage system
  - **Alternative**: Could be a spell-like effect that spawns a fire explosion

**System Changes Needed**:
- **Create Worker**: `AreaDamageWorker` (extends `RefCounted`)
- **In `PotionData`**: Add `area_fire_damage` to effect enum
- **In `PotionConsumptionHandler`**: Instantiate worker and call `deal_area_damage()`
- **Architecture**: Worker handles area damage (not added to `CombatSystem`)

---

### 2.4 Moonphase Token (`Moonphase_Token.jpg`)

**Effect**: Random elemental buff (phase dependent)
**Description**: `"A token that shifts with the moon's phases. Grants a random elemental buff that changes based on the current phase."`

**Implementation**:
- **Effect Type**: `"buff_random_element"` (NEW)
- **Potency**: `+25%` damage for random element
- **Duration**: `240.0` seconds (4 minutes)
- **Mechanic**:
  - Randomly selects fire/water/earth/air on consumption
  - Applies spell damage buff for that element
  - Could use game time or random seed for "phase"

**System Changes Needed**:
- Add random element selection logic
- Apply buff to selected element in `SpellSystem`

---

### 2.5 Stormlink Sigil (`Stormlink_Sigil.jpg`)

**Effect**: Chains lightning spells
**Description**: `"A sigil crackling with lightning. Causes lightning spells to chain between enemies. Cracks after use."`

**Implementation**:
- **Effect Type**: `"buff_lightning_chaining"` (NEW)
- **Potency**: `3` chain targets (lightning jumps to 3 nearby enemies)
- **Duration**: `180.0` seconds (3 minutes)
- **Mechanic**:
  - Air spells (or future lightning spells) chain to nearby enemies
  - Requires chaining system in spell projectiles
  - **Alternative**: If lightning spells don't exist, apply to air spells

**System Changes Needed**:
- Add chaining logic to spell projectiles
- Track buff in `SpellSystem`
- Add `buff_lightning_chaining` to `PotionData.effect` enum

---

### 2.6 Stoneward Seal (`Stoneward_Seal.jpg`)

**Effect**: Temporary armor buff
**Description**: `"A stone seal used by ritual guards. Provides a powerful temporary armor buff."`

**Implementation**:
- **Effect Type**: `"buff_defense"` (existing)
- **Potency**: `+40%` damage reduction (higher than normal defense potion)
- **Duration**: `300.0` seconds (5 minutes)
- **Mechanic**: Standard defense buff, but stronger

**System Changes Needed**: None (uses existing `buff_defense`)

---

### 2.7 Sunflare Disk (`Sunflare_Disk.jpg`)

**Effect**: Emits radiant burst
**Description**: `"A blinding disk of pure light. Emits a radiant burst that damages and blinds enemies. Too bright to stare at."`

**Implementation**:
- **Effect Type**: `"area_radiant_damage"` (NEW)
- **Potency**: `60` radiant damage + blind effect
- **Duration**: `0.0` (instant)
- **Mechanic**:
  - Instant area damage (like Ashpulse Knot)
  - Could add "blind" debuff to enemies (slows movement/attack speed)
  - **Alternative**: Just area damage if blind system doesn't exist

**System Changes Needed**:
- Add area damage handler
- Add blind debuff system (future) OR just use damage

---

### 2.8 Sigil of Still Air (`Sigil_of_Still_Air.jpg`)

**Effect**: Halts enemy movement briefly
**Description**: `"A sigil used by sky monks. Creates a zone of still air that freezes enemies in place."`

**Implementation**:
- **Effect Type**: `"area_enemy_slow"` (NEW)
- **Potency**: `100%` movement reduction (complete stop)
- **Duration**: `5.0` seconds (enemies frozen for 5 seconds)
- **Mechanic**:
  - Applies slow/freeze debuff to all enemies in radius
  - Requires enemy debuff system
  - **Alternative**: If debuff system doesn't exist, could be area damage instead

**System Changes Needed**:
- **In `BaseEnemy`**: Add debuff tracking and `movement_speed_multiplier`
- **In `PotionData`**: Add `area_enemy_slow` to effect enum
- **In `PotionConsumptionHandler`**: Emit EventBus signal or call enemy debuff method
- **Architecture**: Debuffs are enemy state, managed by `BaseEnemy` coordinator

---

## Part 3: Implementation Plan

### Phase 1: Extend PotionData System

**Tasks**:
1. Add new effect types to `PotionData.effect` enum:
   - `"buff_intelligence"`
   - `"buff_water_spells"`
   - `"buff_curse_resistance"`
   - `"area_fire_damage"`
   - `"buff_random_element"`
   - `"buff_lightning_chaining"`
   - `"area_radiant_damage"`
   - `"area_enemy_slow"`

2. Update `PotionConsumptionHandler` to handle new effects:
   - Add handlers for each new effect type
   - Integrate with `SpellSystem` for spell buffs
   - Integrate with `CombatSystem` for area damage
   - Integrate with enemy system for debuffs

---

### Phase 2: Create Alchemy Tool Resources

**Tasks**:
1. Create `mortar_and_pestle.tres` (ItemData)
2. Create `empty_elixir_vial.tres` (ItemData)
3. Create 8 filled vial resources:
   - `blood_filled_elixir_vial.tres` (PotionData)
   - `water_filled_elixir_vial.tres` (PotionData)
   - `wisdom_filled_elixir_vial.tres` (PotionData)
   - `ether_filled_elixir_vial.tres` (PotionData)
   - `psychotropic_filled_elixir_vial.tres` (PotionData)
   - `spectral_fluid_filled_elixir_vial.tres` (PotionData)
   - `dark_matter_filled_elixir_vial.tres` (PotionData)
   - Verify duplicate `water_filled_elixir_vial.jpg` issue

**Note**: For dual-purpose vials (consumable + ingredient), we need to decide:
- **Option A**: Create both `PotionData` (consumable) and `ItemData` (ingredient) versions
- **Option B**: Extend `RecipeData` to accept `PotionData` as ingredients
- **Option C**: Create a base `ItemData` and extend it for both purposes

**Recommendation**: Option B - Extend `RecipeData` to accept `PotionData` as ingredients (cleaner, single source of truth)

---

### Phase 3: Create Special Consumable Resources

**Tasks**:
1. Create 8 special consumable resources (all `PotionData`):
   - `deepwater_script.tres`
   - `voidward_glyph.tres`
   - `ashpulse_knot.tres`
   - `moonphase_token.tres`
   - `stormlink_sigil.tres`
   - `stoneward_seal.tres`
   - `sunflare_disk.tres`
   - `sigil_of_still_air.tres`

2. Configure each with appropriate effect, potency, and duration

---

### Phase 4: Update Recipe System

**Tasks**:
1. Update `RecipeData` to accept `PotionData` as ingredients (if Option B chosen)
2. Update existing recipes to include `empty_elixir_vial` requirement
3. Create new advanced recipes using filled vials:
   - Greater Health Potion (Blood Vial + ingredients)
   - Greater Mana Potion (Water Vial + ingredients)
   - Intelligence Boost Potion (Wisdom Vial + ingredients)
   - Speed Potion (Psychotropic Vial + ingredients)
   - Defense Potion (Spectral Fluid Vial + ingredients)
   - Strength Potion (Dark Matter Vial + ingredients)

---

### Phase 5: Implement New Effect Handlers (Following Architecture)

**Tasks**:

1. **Spell Buffs** (`buff_water_spells`, `buff_lightning_chaining`, `buff_random_element`):
   - **In `SpellSystem`**: Add `element_damage_multipliers` Dictionary
   - **In `SpellSystem`**: Add `buff_timers` Dictionary for duration tracking
   - **In `SpellSystem`**: Add `apply_element_buff()` method
   - **In `SpellSystem`**: Modify `get_spell_damage()` to apply multipliers
   - **In `SpellSystem`**: Add `_process()` to expire buff timers
   - **Single Responsibility**: `SpellSystem` manages spell-related buffs

2. **Area Damage** (`area_fire_damage`, `area_radiant_damage`):
   - **Create Worker**: `scripts/workers/effects/area_damage_worker.gd`
   - **Worker Responsibility**: Detect enemies in radius, apply damage
   - **In `PotionConsumptionHandler`**: Instantiate worker and call `deal_area_damage()`
   - **Worker Pattern**: Single-use worker, destroyed after use
   - **Single Responsibility**: Worker handles area damage detection/application

3. **Enemy Debuffs** (`area_enemy_slow`):
   - **In `BaseEnemy`**: Add `active_debuffs` Dictionary
   - **In `BaseEnemy`**: Add `movement_speed_multiplier` variable
   - **In `BaseEnemy`**: Add `apply_debuff()` method
   - **In `BaseEnemy`**: Modify movement logic to apply multiplier
   - **In `BaseEnemy`**: Add `_process_debuffs()` to track duration
   - **Single Responsibility**: `BaseEnemy` manages enemy state (including debuffs)

4. **Stat Buffs** (`buff_intelligence`, `buff_defense`, `buff_strength`):
   - **In `PlayerStats`**: Add `temporary_stat_modifiers` Dictionary
   - **In `PlayerStats`**: Add `buff_timers` Dictionary
   - **In `PlayerStats`**: Add `apply_stat_buff()` method
   - **In `PlayerStats`**: Modify stat getters (e.g., `get_total_int()`) to apply modifiers
   - **In `PlayerStats`**: Add `_process()` to expire buff timers
   - **Single Responsibility**: `PlayerStats` manages player stat state

5. **Speed Buffs** (`buff_speed`):
   - **In `PlayerStats`**: Add `movement_speed_multiplier` variable
   - **In `PlayerStats`**: Add `apply_speed_buff()` method
   - **In `player.gd`**: Modify movement speed calculation to apply multiplier
   - **Single Responsibility**: `PlayerStats` manages movement-related stats

---

### Phase 6: Image Processing

**Tasks**:
1. Convert all JPG files to PNG with transparent backgrounds:
   - Alchemy tools (9 files)
   - Consumables (8 files)
2. Use `rembg` (Python) to remove backgrounds
3. Save as PNG files in respective directories

---

## Part 4: System Architecture Considerations

**CRITICAL**: This plan must follow our established architecture:
- **Coordinator/Worker Pattern**: Coordinators make decisions, workers execute tasks
- **Single Responsibility**: Each system/class has ONE clear purpose
- **No God Objects**: Systems are focused and delegate to workers
- **EventBus Communication**: Decoupled communication via signals

---

### 4.1 Buff Tracking (NOT a BuffSystem Singleton)

**Architecture Principle**: Buffs should be tracked in the systems they affect, NOT in a centralized "BuffSystem" (which would be a God Object).

**Current Codebase Analysis**:
- `SpellSystem.get_spell_damage()` uses `DamageCalculator.calculate_spell_damage()` which takes `base_damage`, `level`, `flat_bonus`, `percentage_bonus`
- `PlayerStats.get_total_*()` methods already add equipment bonuses from `InventorySystem`
- `PlayerStats.get_movement_speed_multiplier()` uses `StatFormulas.calculate_movement_speed_multiplier()` (agility-based)
- `PlayerStats` has `_process()` for regeneration (can add buff timer processing)
- `SpellSystem` does NOT have `_process()` - will need to add it for buff timers

**Implementation**:

**Spell Buffs** (water spells, lightning chaining, random element):
- **Location**: `scripts/systems/spells/spell_system.gd`
- **Add**: `element_damage_multipliers: Dictionary = {"fire": 1.0, "water": 1.0, "earth": 1.0, "air": 1.0}`
- **Add**: `buff_timers: Dictionary = {}` (stores `{buff_id: {"timer": float, "multiplier": float, "element": String}}`)
- **Add**: `_process(delta: float)` to decrement buff timers
- **Modify**: `get_spell_damage()` to apply element multiplier AFTER `DamageCalculator` calculation
- **Add**: `apply_element_buff(element: String, multiplier: float, duration: float) -> void`
- **Pattern**: Use simple float timers (like `BaseEnemy` uses `attack_cooldown_timer`)

**Stat Buffs** (intelligence, defense, strength):
- **Location**: `scripts/systems/player/player_stats.gd`
- **Add**: `temporary_stat_modifiers: Dictionary = {}` (stores `{stat_name: modifier_value}`)
- **Add**: `buff_timers: Dictionary = {}` (stores `{buff_id: {"timer": float, "stat": String, "modifier": int}}`)
- **Modify**: `get_total_int()`, `get_total_resilience()`, `get_total_agility()`, `get_total_vit()` to add temporary modifiers
- **Add**: `apply_stat_buff(stat_name: String, modifier: int, duration: float) -> void`
- **Modify**: `_process()` to decrement buff timers (already exists for regeneration)

**Speed Buffs**:
- **Location**: `scripts/systems/player/player_stats.gd`
- **Add**: `movement_speed_buff_multiplier: float = 1.0` (applied on top of agility multiplier)
- **Add**: `speed_buff_timer: float = 0.0`
- **Add**: `apply_speed_buff(multiplier: float, duration: float) -> void`
- **Modify**: `get_movement_speed_multiplier()` to multiply by `movement_speed_buff_multiplier`
- **Modify**: `_process()` to decrement `speed_buff_timer`

**Code Structure**:
```gdscript
# In SpellSystem.gd (add to existing)
var element_damage_multipliers: Dictionary = {
    "fire": 1.0,
    "water": 1.0,
    "earth": 1.0,
    "air": 1.0
}
var buff_timers: Dictionary = {}  # {buff_id: {"timer": float, "multiplier": float, "element": String}}

func _process(delta: float) -> void:
    # Process buff timers
    for buff_id in buff_timers.keys():
        buff_timers[buff_id]["timer"] -= delta
        if buff_timers[buff_id]["timer"] <= 0.0:
            var element = buff_timers[buff_id]["element"]
            element_damage_multipliers[element] = 1.0
            buff_timers.erase(buff_id)
            _logger.log("Buff expired: " + buff_id)

func apply_element_buff(element: String, multiplier: float, duration: float) -> void:
    var buff_id = "element_buff_" + element + "_" + str(Time.get_ticks_msec())
    element_damage_multipliers[element] = multiplier
    buff_timers[buff_id] = {"timer": duration, "multiplier": multiplier, "element": element}
    _logger.log("Applied " + element + " spell buff: " + str(multiplier) + "x for " + str(duration) + "s")

func get_spell_damage(spell: SpellData) -> int:
    # ... existing calculation ...
    var total_damage: int = DamageCalculator.calculate_spell_damage(...)
    # Apply element multiplier
    var element_multiplier: float = element_damage_multipliers.get(spell.element, 1.0)
    return int(total_damage * element_multiplier)

# In PlayerStats.gd (add to existing)
var temporary_stat_modifiers: Dictionary = {}  # {stat_name: int}
var buff_timers: Dictionary = {}  # {buff_id: {"timer": float, "stat": String, "modifier": int}}
var movement_speed_buff_multiplier: float = 1.0
var speed_buff_timer: float = 0.0

func _process(delta: float) -> void:
    # ... existing regeneration code ...
    
    # Process stat buff timers
    for buff_id in buff_timers.keys():
        buff_timers[buff_id]["timer"] -= delta
        if buff_timers[buff_id]["timer"] <= 0.0:
            var stat = buff_timers[buff_id]["stat"]
            temporary_stat_modifiers.erase(stat)
            buff_timers.erase(buff_id)
            _logger.log("Stat buff expired: " + stat)
    
    # Process speed buff timer
    if speed_buff_timer > 0.0:
        speed_buff_timer -= delta
        if speed_buff_timer <= 0.0:
            movement_speed_buff_multiplier = 1.0
            _logger.log("Speed buff expired")

func apply_stat_buff(stat_name: String, modifier: int, duration: float) -> void:
    var buff_id = "stat_buff_" + stat_name + "_" + str(Time.get_ticks_msec())
    temporary_stat_modifiers[stat_name] = modifier
    buff_timers[buff_id] = {"timer": duration, "stat": stat_name, "modifier": modifier}
    _logger.log("Applied " + stat_name + " buff: +" + str(modifier) + " for " + str(duration) + "s")

func get_total_int() -> int:
    var bonus: int = 0
    if InventorySystem != null:
        bonus = InventorySystem.get_total_stat_bonus(StatConstants.STAT_INT)
    var temp_modifier: int = temporary_stat_modifiers.get(StatConstants.STAT_INT, 0)
    return base_int + bonus + temp_modifier

func get_movement_speed_multiplier() -> float:
    var agility: int = get_total_agility()
    var base_multiplier: float = StatFormulas.calculate_movement_speed_multiplier(agility)
    return base_multiplier * movement_speed_buff_multiplier

func apply_speed_buff(multiplier: float, duration: float) -> void:
    movement_speed_buff_multiplier = multiplier
    speed_buff_timer = duration
    _logger.log("Applied speed buff: " + str(multiplier) + "x for " + str(duration) + "s")
```

---

### 4.2 Area Damage (Worker Pattern)

**Architecture Principle**: Area damage detection and application should be handled by a **Worker**, not added to `CombatSystem` (which only does damage reduction calculations).

**Current Codebase Analysis**:
- `CombatSystem` only has `calculate_damage_reduction()` - single responsibility
- Enemies use `Area2D` with `get_overlapping_bodies()` for detection (see `BaseEnemy._process_idle()`)
- Enemies are in `GROUP_ENEMY` group (see `GameConstants.GROUP_ENEMY`)
- Enemies have `take_damage(amount: int, source: Node)` method
- Player position available via `get_tree().get_first_node_in_group("player")` or direct reference

**Implementation**:
- **Create**: `scripts/workers/effects/area_damage_worker.gd` (extends `RefCounted` like `PotionConsumptionHandler`)
- Worker is instantiated by `PotionConsumptionHandler` when area damage effect is triggered
- Worker uses `Area2D` pattern to detect enemies in radius
- Worker applies damage directly to enemies via `take_damage()`
- Worker is destroyed after use (single-use worker)
- **Single Responsibility**: Worker handles area damage detection and application

**Structure**:
```gdscript
# scripts/workers/effects/area_damage_worker.gd
class_name AreaDamageWorker
extends RefCounted

var _logger = GameLogger.create("[AreaDamageWorker] ")

## Deals area damage to all enemies in radius around center point.
## 
## Args:
##   center: Center point of area damage (player position)
##   radius: Radius of area damage in pixels
##   damage: Damage amount to deal
##   damage_type: Type of damage (for logging/future resistance system)
func deal_area_damage(center: Vector2, radius: float, damage: int, damage_type: String = "magic") -> void:
    _logger.log("Dealing area damage: " + str(damage) + " " + damage_type + " damage at " + str(center) + " (radius: " + str(radius) + ")")
    
    # Get all enemies in scene
    var enemies = get_tree().get_nodes_in_group(GameConstants.GROUP_ENEMY)
    var hit_count: int = 0
    
    for enemy in enemies:
        if not enemy is BaseEnemy:
            continue
        
        var enemy_pos: Vector2 = enemy.global_position
        var distance: float = center.distance_to(enemy_pos)
        
        if distance <= radius:
            enemy.take_damage(damage, null)  # Source is null (potion effect)
            hit_count += 1
            _logger.log("  Hit enemy: " + enemy.name + " at distance " + str(int(distance)))
    
    _logger.log("Area damage complete: hit " + str(hit_count) + " enemies")
```

**Note**: Worker needs access to scene tree. Since it's instantiated by `PotionConsumptionHandler` (which is called from `InventorySystem`), we can pass scene tree reference or use `get_tree()` from a node reference.

**Alternative**: Create temporary `Area2D` node in scene, detect enemies, then remove node. But simpler approach: iterate through enemy group and check distance.

**Usage in PotionConsumptionHandler**:
```gdscript
# In PotionConsumptionHandler._handle_area_damage()
# Need to get player position - could pass via parameter or get from scene tree
var player = get_tree().get_first_node_in_group(GameConstants.GROUP_PLAYER)
if player != null:
    var worker = AreaDamageWorker.new()
    worker.deal_area_damage(player.global_position, radius, damage, "fire")
```

**Why NOT in CombatSystem**: `CombatSystem` only does `calculate_damage_reduction()`. Adding area damage detection would violate single responsibility.

---

### 4.3 Enemy Debuff System (In BaseEnemy)

**Architecture Principle**: Debuffs are enemy state, so they belong in `BaseEnemy` (the enemy coordinator).

**Current Codebase Analysis**:
- `BaseEnemy` has `move_speed: float` variable (exported)
- Movement is applied in `_process_chase()` via `mover.move(dir, move_speed)`
- `BaseEnemy` has `_physics_process()` with timer decrements (`attack_cooldown_timer`, `hurt_timer`, `post_attack_backoff_timer`)
- Pattern: Simple float timers decremented in `_physics_process()`
- **CRITICAL**: `BaseEnemy` has LOCKED combat logic - debuffs should NOT modify attack logic, only movement

**Implementation**:
- **Location**: `scripts/enemies/base_enemy.gd`
- **Add**: `movement_speed_multiplier: float = 1.0` (applied to `move_speed` in movement calculations)
- **Add**: `debuff_timer: float = 0.0` (for slow/freeze debuffs)
- **Add**: `apply_debuff(effect: String, potency: float, duration: float) -> void`
- **Modify**: `_physics_process()` to decrement `debuff_timer` and reset multiplier when expired
- **Modify**: `_process_chase()` to apply `movement_speed_multiplier` to `move_speed`
- **Single Responsibility**: `BaseEnemy` manages enemy state (including debuffs)

**Structure**:
```gdscript
# In BaseEnemy.gd (add to existing coordinator)
var movement_speed_multiplier: float = 1.0  # Applied in movement calculations
var debuff_timer: float = 0.0

func _physics_process(delta: float) -> void:
    # ... existing timer decrements ...
    
    # Process debuff timer
    if debuff_timer > 0.0:
        debuff_timer -= delta
        if debuff_timer <= 0.0:
            movement_speed_multiplier = 1.0
            _logger.log("Debuff expired: movement speed restored")
    
    # ... rest of existing code ...

func apply_debuff(effect: String, potency: float, duration: float) -> void:
    match effect:
        "slow", "freeze":
            movement_speed_multiplier = 1.0 - potency  # potency is percentage (0.0 to 1.0)
            debuff_timer = duration
            _logger.log("Debuff applied: " + effect + " (" + str(int(potency * 100)) + "%) for " + str(duration) + "s")
        _:
            _logger.log_error("Unknown debuff effect: " + effect)

func _process_chase() -> void:
    # ... existing code ...
    if mover != null:
        var effective_speed: float = move_speed * movement_speed_multiplier
        if dist < separation_distance:
            dir = -dir
            mover.move(dir, effective_speed * 0.8)  # Apply multiplier
        else:
            mover.move(dir, effective_speed)  # Apply multiplier
```

**Why in BaseEnemy**: Debuffs are enemy state, so the enemy coordinator manages them (following coordinator pattern). Movement speed multiplier is applied in movement logic, not in a separate system.

---

### 4.4 PotionConsumptionHandler (Worker Extension)

**Architecture Principle**: `PotionConsumptionHandler` is already a worker (extends `RefCounted`). We extend it with new effect handlers, maintaining single responsibility.

**Current Codebase Analysis**:
- `PotionConsumptionHandler` is instantiated in `InventorySystem._ready()` as `_potion_handler`
- Handler is called from `InventorySystem.use_item()` when potion is consumed
- Handler already has `_apply_effect()` with match statement routing
- Handler has access to `PlayerStats` (checked in `consume_potion()`)
- Handler needs access to scene tree for area damage (can get from `get_tree()` if we store reference, or pass via parameter)

**Implementation**:
- **Location**: `scripts/systems/inventory/potion_consumption_handler.gd`
- **Add**: New effect handlers to `_apply_effect()` match statement
- **Add**: Helper methods for each new effect type
- Each handler delegates to appropriate systems/workers:
  - Spell buffs → `SpellSystem.apply_element_buff()`
  - Stat buffs → `PlayerStats.apply_stat_buff()` or `apply_speed_buff()`
  - Area damage → `AreaDamageWorker.deal_area_damage()` (new worker)
  - Enemy debuffs → Apply to all enemies in radius (iterate through group)
- **Single Responsibility**: Handler routes effects to appropriate systems

**Structure**:
```gdscript
# In PotionConsumptionHandler.gd (extend existing worker)
var _scene_tree: SceneTree = null  # Set when handler is created

func _apply_effect(potion: PotionData) -> void:
    match potion.effect:
        # ... existing effects ...
        "buff_water_spells":
            if SpellSystem != null:
                SpellSystem.apply_element_buff("water", 1.0 + (potion.potency / 100.0), potion.duration)
        "buff_intelligence":
            if PlayerStats != null:
                PlayerStats.apply_stat_buff(StatConstants.STAT_INT, potion.potency, potion.duration)
        "buff_defense":
            if PlayerStats != null:
                # Defense buff = resilience modifier
                PlayerStats.apply_stat_buff(StatConstants.STAT_RESILIENCE, potion.potency, potion.duration)
        "buff_strength":
            # Strength buff = damage percentage bonus (handled differently - see notes)
            _handle_strength_buff(potion)
        "buff_speed":
            if PlayerStats != null:
                PlayerStats.apply_speed_buff(1.0 + (potion.potency / 100.0), potion.duration)
        "area_fire_damage", "area_radiant_damage":
            _handle_area_damage(potion)
        "area_enemy_slow":
            _handle_enemy_slow(potion)
        "buff_random_element":
            _handle_random_element_buff(potion)
        "buff_lightning_chaining":
            if SpellSystem != null:
                SpellSystem.apply_element_buff("air", 1.0 + (potion.potency / 100.0), potion.duration)
        _:
            _logger.log_error("Unknown potion effect: " + potion.effect)

func _handle_area_damage(potion: PotionData) -> void:
    if _scene_tree == null:
        _logger.log_error("Scene tree not available for area damage")
        return
    
    var player = _scene_tree.get_first_node_in_group(GameConstants.GROUP_PLAYER)
    if player == null:
        _logger.log_error("Player not found for area damage")
        return
    
    var worker = AreaDamageWorker.new()
    var damage_type = "fire" if potion.effect == "area_fire_damage" else "radiant"
    worker.deal_area_damage(player.global_position, 100.0, potion.potency, damage_type)

func _handle_enemy_slow(potion: PotionData) -> void:
    if _scene_tree == null:
        _logger.log_error("Scene tree not available for enemy slow")
        return
    
    var player = _scene_tree.get_first_node_in_group(GameConstants.GROUP_PLAYER)
    if player == null:
        _logger.log_error("Player not found for enemy slow")
        return
    
    var enemies = _scene_tree.get_nodes_in_group(GameConstants.GROUP_ENEMY)
    var radius: float = 150.0  # Slow radius
    var hit_count: int = 0
    
    for enemy in enemies:
        if not enemy is BaseEnemy:
            continue
        
        var distance: float = player.global_position.distance_to(enemy.global_position)
        if distance <= radius:
            # potency is percentage (0.0 to 1.0) - 1.0 = 100% slow (freeze)
            enemy.apply_debuff("slow", potion.potency / 100.0, potion.duration)
            hit_count += 1
    
    _logger.log("Applied slow debuff to " + str(hit_count) + " enemies")
```

**Note**: `_scene_tree` needs to be set when handler is created. Options:
1. Pass `get_tree()` from `InventorySystem._ready()` when creating handler
2. Store reference to a Node (like `InventorySystem`) and call `get_tree()` when needed
3. Use `get_tree()` directly if we make handler a Node instead of RefCounted (not recommended - breaks pattern)

**Recommended**: Option 1 - Pass scene tree when creating handler in `InventorySystem._ready()`:
```gdscript
# In InventorySystem._ready()
_potion_handler = PotionConsumptionHandler.new()
_potion_handler.set_scene_tree(get_tree())
```

Add method to `PotionConsumptionHandler`:
```gdscript
func set_scene_tree(tree: SceneTree) -> void:
    _scene_tree = tree
```

---

### 4.5 RecipeData Extension (Data Structure)

**Architecture Principle**: Extending `RecipeData` to accept `PotionData` as ingredients is a data structure change, not a system change. This is acceptable.

**Current Codebase Analysis**:
- `RecipeData.ingredients: Array[ItemData]` already exists
- `PotionData` extends `ItemData` (see `scripts/data/potion_data.gd`)
- `CraftingSystem.can_craft()` uses `InventorySystem.has_item(ingredient, required_count)`
- `InventorySystem.has_item()` checks `ItemData` type
- **Conclusion**: Since `PotionData` extends `ItemData`, recipes can already accept potions as ingredients! No code changes needed.

**Implementation**:
- **No code changes required** - `PotionData` extends `ItemData`, so it's already compatible
- **Resource Creation**: Create `PotionData` resources for filled vials
- **Recipe Creation**: Reference `PotionData` resources in `RecipeData.ingredients` array
- **Crafting**: `CraftingSystem` will work automatically since it uses `has_item()` which accepts any `ItemData`

**Verification**:
- Test that `InventorySystem.has_item()` works with `PotionData` resources
- Test that `CraftingSystem.can_craft()` correctly checks for potion ingredients
- Test that `CraftingSystem.craft()` correctly consumes potion ingredients

**Note**: Since `PotionData` extends `ItemData`, we can keep the type as `Array[ItemData]` and it will accept both regular items and potions.

---

## Part 5: Recipe Examples

### Basic Potion Recipes (Updated with Empty Vial)

1. **Health Potion**
   - 1 Empty Elixir Vial
   - 2 Stonebloom
   - 1 Red Cap Mushroom
   - Result: Health Potion (50 HP)

2. **Mana Potion**
   - 1 Empty Elixir Vial
   - 2 Zephyr's Sage
   - 1 Mana Crystal
   - Result: Mana Potion (30 MP)

---

### Advanced Potion Recipes (Using Filled Vials)

3. **Greater Health Potion**
   - 1 Blood Filled Elixir Vial
   - 2 Red Cap Mushroom
   - 1 Healing Moss
   - Result: Greater Health Potion (100 HP)

4. **Greater Mana Potion**
   - 1 Water Filled Elixir Vial
   - 2 Mana Crystal
   - 1 Azure Kelp
   - Result: Greater Mana Potion (75 MP)

5. **Intelligence Boost Potion**
   - 1 Wisdom Filled Elixir Vial
   - 2 Wise Shade
   - 1 Arcane Powder
   - Result: Intelligence Boost Potion (+5 INT for 5 min)

6. **Speed Potion**
   - 1 Psychotropic Filled Elixir Vial
   - 2 Swiftroot
   - 1 Spider Silk
   - Result: Speed Potion (+30% speed for 3 min)

7. **Defense Potion**
   - 1 Spectral Fluid Filled Elixir Vial
   - 2 Stonebloom
   - 1 Healing Moss
   - Result: Defense Potion (+20% defense for 4 min)

8. **Strength Potion**
   - 1 Dark Matter Filled Elixir Vial
   - 2 Orc Fang
   - 1 Phoenix Feather
   - Result: Strength Potion (+25% damage for 3 min)

---

## Part 6: Implementation Priority

### High Priority (Core Functionality)
1. ✅ Image processing (convert JPG to PNG)
2. ✅ Create alchemy tool resources (Mortar & Pestle, Empty Vial)
3. ✅ Create filled vial resources (8 PotionData resources)
4. ✅ Create special consumable resources (8 PotionData resources)
5. ✅ Extend `PotionData.effect` enum with new effects
6. ✅ Update `PotionConsumptionHandler` for new effects (basic handlers)

### Medium Priority (System Integration)
7. ⏳ Update recipes to require Empty Vial
8. ⏳ Create advanced recipes using filled vials
9. ⏳ Implement spell buff system (for water spells, lightning chaining, etc.)
10. ⏳ Implement area damage system (for fire pulse, radiant burst)
11. ⏳ Implement intelligence buff (temporary INT modifier)

### Low Priority (Advanced Features)
12. ⏳ Implement enemy debuff system (for slow/freeze)
13. ⏳ Implement curse resistance system
14. ⏳ Implement random element buff logic
15. ⏳ Add Mortar & Pestle as recipe requirement (if desired)

---

## Part 7: Architecture Decisions Made

1. **Dual-Purpose Vials**: How to handle vials as both consumables and ingredients?
   - **Decision**: Extend `RecipeData` to accept `PotionData` as ingredients (since `PotionData` extends `ItemData`)

2. **Mortar & Pestle**: Should it be required for recipes?
   - **Decision**: Not required initially, but can be added later as recipe requirement

3. **Buff System**: Should we create a dedicated `BuffSystem`?
   - **Decision**: ❌ NO - Buffs tracked in systems they affect (`SpellSystem` for spell buffs, `PlayerStats` for stat buffs)
   - **Reason**: Avoids God Object, maintains single responsibility

4. **Area Damage**: Where should area damage logic live?
   - **Decision**: Create `AreaDamageWorker` (worker pattern)
   - **Reason**: `CombatSystem` only does damage reduction calculations (single responsibility)

5. **Enemy Debuffs**: Where should debuff logic live?
   - **Decision**: In `BaseEnemy` (enemy coordinator)
   - **Reason**: Debuffs are enemy state, managed by enemy coordinator

6. **Duplicate Water Vial**: Is `water_filled_elixir_vial.jpg` a duplicate?
   - **Action**: Verify with user or rename one variant

---

## Summary

This plan outlines:
- ✅ **9 Alchemy Tools**: Mortar & Pestle, Empty Vial, 7 Filled Vials (8 total vials)
- ✅ **8 Special Consumables**: Sigils, glyphs, tokens with unique effects
- ✅ **System Extensions**: New effect types, buff system, area damage, debuffs
- ✅ **Recipe Updates**: Include Empty Vial requirement, create advanced recipes
- ✅ **Implementation Phases**: Prioritized tasks from high to low priority

**Next Steps**: Review this plan, then proceed with implementation starting with Phase 1 (extend PotionData system) and Phase 6 (image processing).

