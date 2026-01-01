# Alchemy Recipe Overhaul Plan

## Context & Principles
- **Data-centric design**: Items, potions, and recipes live in `.tres` resources (ItemData, EquipmentData, PotionData, RecipeData). Systems load these at runtime via `ResourceManager`, so gameplay logic stays decoupled from content.
- **OOP & Single Responsibility**:
  - `InventorySystem` manages slot contents, delegates equipment to `EquipmentSystem`, gold to `CurrencySystem`.
  - `CraftingSystem` loads recipes and validates ingredients; UI (`crafting_ui.gd`) only displays data.
  - `ChestInventory` encapsulates chest slots without touching InventorySystem internals.
- Maintaining this separation is critical: logic changes belong in systems, content tweaks belong in resources/data files.

## Goals
1. Tie potion recipes directly to game mechanics (PlayerStats health/mana/stamina values, elemental systems, catalysts).
2. Ensure every potion’s base liquid, ingredients, and catalysts are consistent with its effect and tier.
3. Keep recipes data-driven so designers can add/edit `.tres` files without touching code.

## Base Liquids (Filled Elixir Vials)
*Implementation note: these exist as `ItemData` alchemy tools (`res://resources/items/*_filled_elixir_vial.tres`), so they are never drinkable consumables.*
| Base Liquid | Tier | Theme | Example Use |
| --- | --- | --- | --- |
| `water_filled_elixir_vial` | T1 | Neutral/restorative | Basic health/mana/stamina potions |
| `blood_filled_elixir_vial` | T2 | Vitality | Greater health, regen |
| `spectral_fluid_filled_elixir_vial` | T2 | Phasing/protection | Defense, warding |
| `psychotropic_filled_elixir_vial` | T2 | Mobility/reflex | Speed, agility |
| `ether_filled_elixir_vial` | T3 | Arcane/mana | INT boosts, high mana potions |
| `dark_matter_filled_elixir_vial` | T3 | Offensive | Strength/damage potions |

Each recipe must include exactly one base liquid; higher-tier potions require higher-tier bases.

## Ingredient Categories
- **Elemental herbs**: `air_herb`, `fire_herb`, `water_herb`, `stonebloom`, `storm_dust`.
- **Stat roots/materials**: `swiftroot`, `wisdom_bloom`, `healing_moss`, `stonebloom`, `orc_fang`.
- **Catalysts (rare items)**: `mana_crystal`, `phoenix_feather`, `storm_dust`, `arcane_dust`, `spider_silk`, `red_cap_mushroom`, `stonebloom` (tough stabilizer).

## Recipe Schema
Each RecipeData should include:
- `base_liquid`: filled elixir vial resource reference.
- `primary_ingredient`: herb/root that matches the potion’s theme (element/stat).
- `catalyst`: rare item that defines the potion’s unique effect.
- Optional `secondary` ingredient for hybrid potions (speed + defense, etc.).
- `result`, `result_count`, `ingredient_counts` to match actual potency/duration/XP values.

## Proposed Mapping Examples
| Potion | Base | Primary Ingredient | Catalyst | Notes |
| --- | --- | --- | --- | --- |
| Health Potion | Water | healing_moss ×2 | stonebloom | Restores 50 HP |
| Greater Health | Blood | healing_moss ×2 | phoenix_feather | Restores 100 HP |
| Mana Potion | Water | air_herb ×2 | mana_crystal | Restores 30 mana |
| Greater Mana | Ether | air_herb ×2 | mana_crystal + wisdom_bloom | Restores 75 mana |
| Stamina Potion | Water | swiftroot ×2 | spider_silk | Restores 50 stamina |
| Defense Potion | Spectral | stonebloom ×2 | storm_dust | +15% damage reduction |
| Speed Potion | Psychotropic | swiftroot ×2 | spider_silk + air_herb | +25% speed |
| Strength Potion | Dark Matter | orc_fang ×2 | phoenix_feather | +20 STR |
| Intelligence Boost | Ether | wisdom_bloom ×2 | mana_crystal | +5 INT |
| Gold Elixir | Ether | healing_moss + wisdom_bloom | mana_crystal + swiftroot | Restores all |

*Consumable artifacts such as Ashpulse Knot, Sigil of Still Air, Stormlink Sigil, Stoneward Seal, Sunflare Disk, Moonphase Token, Voidward Glyph, and Deepwater Script are loot-only items; do **not** create alchemy recipes for them.*

(Repeat for every potion resource in `resources/potions`.)

## Implementation Plan
1. **Create a recipe table** (JSON/CSV): each row `potion_id, base_liquid_id, ingredients[], ingredient_counts[], catalyst_id, tier, xp_reward, result_count`.
2. **Scripted regeneration**: build a small tool (Python/GDScript) to read the table and rewrite each `resources/recipes/*.tres` with the correct `ExtResource` references.
3. **Update potion descriptions** to describe actual potency/duration consistent with PlayerStats/Alchemy systems.
4. **UI enhancements** (optional): in the Recipes tab, display "Base: Spectral Essence (Phasing)" and tag ingredients by category (elemental/stat/catalyst). Allow filters by tier or effect.

## Why Data-Centric Matters Here
- Designers can tweak recipes by editing the table or `.tres` without risking logic regressions.
- Systems (Crafting, Inventory, UI) already expect Resource references; reusing this pipeline preserves SRP.
- Avoids hardcoded combinations in GDScript, keeping the architecture maintainable and ready for future expansions (new base liquids, catalysts, or potion tiers).

---
*Next step (when ready): populate the recipe table with final mappings and run the regeneration script to update all RecipeData resources.*
