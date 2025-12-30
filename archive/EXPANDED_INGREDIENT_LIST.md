# Expanded Ingredient List - Game Mechanics Focused

**Purpose**: Additional ingredient ideas that serve specific game mechanics beyond basic potions

---

## Current Ingredients (6)
1. Emberleaf (Fire herb)
2. Azure Kelp (Water herb)
3. Stonebloom (Earth herb)
4. Zephyr Petal (Air herb)
5. Red Cap Mushroom (Amanita Muscaria)
6. Mana Crystal

---

## Additional Ingredient Ideas by Game Mechanic

### Combat & Damage Ingredients

7. **Orc Tooth** (`orc_tooth.tres`)
   - **display_name**: `"Orc Fang"`
   - **description**: `"A sharp fang from a defeated orc. Still warm to the touch and pulsing with residual aggression."`
   - **item_type**: `"material"`
   - **weight**: `0.2`
   - **Use**: Craft damage-boosting potions, strength potions
   - **Source**: Enemy drops (orcs)

8. **Iron Ore** (`iron_ore.tres`)
   - **display_name**: `"Raw Iron"`
   - **description**: `"A chunk of unrefined iron ore. Heavy and metallic, it resonates with earth magic."`
   - **item_type**: `"material"`
   - **weight**: `1.5`
   - **Use**: Craft defense potions, resilience-boosting items, equipment crafting
   - **Source**: Mining nodes, earth element areas

9. **Phoenix Feather** (`phoenix_feather.tres`)
   - **display_name**: `"Phoenix Down"`
   - **description**: `"A brilliant red feather that glows with inner fire. Extremely rare and powerful."`
   - **item_type**: `"material"`
   - **weight**: `0.05`
   - **Use**: Craft fire element potions, resurrection items, high-tier fire spells
   - **Source**: Rare enemy drops, fire element areas

### Speed & Agility Ingredients

10. **Spider Silk** (`spider_silk.tres`)
    - **display_name**: `"Gossamer Thread"`
    - **description**: `"Silky thread spun by giant forest spiders. Light as air and incredibly strong."`
    - **item_type**: `"material"`
    - **weight**: `0.1`
    - **Use**: Craft speed potions, agility-boosting items, light armor
    - **Source**: Spider enemy drops, forest areas

11. **Swiftroot** (`swiftroot.tres`)
    - **display_name**: `"Windroot"`
    - **description**: `"A gnarled root that seems to move on its own. Eating it makes you feel lighter."`
    - **item_type**: `"material"`
    - **weight**: `0.2`
    - **Use**: Craft stamina potions, movement speed buffs
    - **Source**: Air element areas, rare plant nodes

### Magic & Intelligence Ingredients

12. **Arcane Dust** (`arcane_dust.tres`)
    - **display_name**: `"Mana Dust"`
    - **description**: `"Sparkling dust that glimmers with magical energy. Essential for mana restoration."`
    - **item_type**: `"material"`
    - **weight**: `0.05`
    - **Use**: Craft mana potions, intelligence-boosting items, spell enhancement
    - **Source**: Magic nodes, spell casting areas

13. **Wisdom Bloom** (`wisdom_bloom.tres`)
    - **display_name**: `"Scholar's Bloom"`
    - **description**: `"A rare flower that blooms only in places of learning. Its petals shimmer with knowledge."`
    - **item_type**: `"material"`
    - **weight**: `0.1`
    - **Use**: Craft intelligence potions, spell power boosts, XP gain items
    - **Source**: Rare plant nodes, library/study areas

### Health & Vitality Ingredients

14. **Healing Moss** (`healing_moss.tres`)
    - **display_name**: `"Life Moss"`
    - **description**: `"A vibrant green moss that glows softly. Known for its restorative properties."`
    - **item_type**: `"material"`
    - **weight**: `0.1`
    - **Use**: Craft health potions, vitality-boosting items, regeneration potions
    - **Source**: Forest areas, water element areas

15. **Vital Essence** (`vital_essence.tres`)
    - **display_name**: `"Life Essence"`
    - **description**: `"A glowing orb of pure life energy. Warm to the touch and pulsing with vitality."`
    - **item_type**: `"material"`
    - **weight**: `0.3`
    - **Use**: Craft high-tier health potions, max HP increases, resurrection items
    - **Source**: Rare drops, boss enemies, life magic areas

### Elemental Enhancement Ingredients

16. **Frost Essence** (`frost_essence.tres`)
    - **display_name**: `"Ice Shard"`
    - **description**: `"A crystal-clear shard of ice that never melts. Radiates cold water magic."`
    - **item_type**: `"material"`
    - **weight**: `0.2`
    - **Use**: Craft water element potions, ice resistance, water spell enhancement
    - **Source**: Water element areas, frozen regions

17. **Earth Core** (`earth_core.tres`)
    - **display_name**: `"Stone Heart"`
    - **description**: `"A dense, heavy stone that pulses like a heartbeat. Pure earth magic condensed."`
    - **item_type**: `"material"`
    - **weight**: `2.0`
    - **Use**: Craft earth element potions, defense potions, earth spell enhancement
    - **Source**: Earth element areas, deep caves, mining nodes

18. **Storm Dust** (`storm_dust.tres`)
    - **display_name**: `"Lightning Powder"`
    - **description**: `"Crackling dust that sparks with electricity. Smells of ozone and carries air magic."`
    - **item_type**: `"material"`
    - **weight**: `0.05`
    - **Use**: Craft air element potions, speed potions, air spell enhancement
    - **Source**: Air element areas, storm regions, high altitudes

### Special Effect Ingredients

19. **Shadow Root** (`shadow_root.tres`)
    - **display_name**: `"Darkroot"`
    - **description**: `"A twisted root that seems to absorb light. Used in stealth and invisibility potions."`
    - **item_type**: `"material"`
    - **weight**: `0.2`
    - **Use**: Craft invisibility potions, stealth items, shadow magic
    - **Source**: Dark areas, shadow magic regions

20. **Golden Petal** (`golden_petal.tres`)
    - **display_name**: `"Fortune Petal"`
    - **description**: `"A rare golden petal that brings good luck. Said to increase gold drops."`
    - **item_type**: `"material"`
    - **weight**: `0.05`
    - **Use**: Craft luck potions, gold-finding items, rare drop boosters
    - **Source**: Very rare plant nodes, treasure areas

21. **Crystal Geode** (`crystal_geode.tres`)
    - **display_name**: `"Mana Geode"`
    - **description**: `"A hollow rock filled with glowing crystals. Contains concentrated magical energy."`
    - **item_type**: `"material"`
    - **weight**: `1.0`
    - **Use**: Craft high-tier mana potions, spell power items, magical equipment
    - **Source**: Mining nodes, magical areas, rare drops

---

## Expanded Potion Ideas Using New Ingredients

### Combat Potions

**Strength Potion** (buff_strength)
- **Ingredients**: Orc Fang (2) + Iron Ore (1)
- **Effect**: `buff_strength`
- **Potency**: 20% damage increase
- **Duration**: 60 seconds

**Defense Potion** (buff_defense)
- **Ingredients**: Iron Ore (2) + Stonebloom (1)
- **Effect**: `buff_defense`
- **Potency**: 15% damage reduction
- **Duration**: 60 seconds

**Speed Potion** (buff_speed)
- **Ingredients**: Spider Silk (2) + Swiftroot (1)
- **Effect**: `buff_speed`
- **Potency**: 25% movement speed increase
- **Duration**: 45 seconds

### Elemental Potions

**Fire Resistance Potion**
- **Ingredients**: Phoenix Feather (1) + Emberleaf (2)
- **Effect**: Fire damage reduction (custom effect)
- **Duration**: 120 seconds

**Water Resistance Potion**
- **Ingredients**: Frost Essence (1) + Azure Kelp (2)
- **Effect**: Water damage reduction
- **Duration**: 120 seconds

### Utility Potions

**Stamina Potion** (restore_stamina)
- **Ingredients**: Swiftroot (2) + Healing Moss (1)
- **Effect**: `restore_stamina`
- **Potency**: 50 stamina restored
- **Duration**: 0.0 (instant)

**Greater Health Potion**
- **Ingredients**: Vital Essence (1) + Healing Moss (2) + Red Cap Mushroom (1)
- **Effect**: `restore_health`
- **Potency**: 100 health restored
- **Duration**: 0.0 (instant)

**Greater Mana Potion**
- **Ingredients**: Crystal Geode (1) + Arcane Dust (2) + Mana Crystal (1)
- **Effect**: `restore_mana`
- **Potency**: 75 mana restored
- **Duration**: 0.0 (instant)

**Intelligence Boost Potion**
- **Ingredients**: Wisdom Bloom (2) + Arcane Dust (1)
- **Effect**: Temporary INT boost (custom effect)
- **Potency**: +5 Intelligence
- **Duration**: 300 seconds (5 minutes)

---

## Ingredient Categories Summary

### By Source Type:
- **Herbs/Plants**: Emberleaf, Azure Kelp, Stonebloom, Zephyr Petal, Swiftroot, Wisdom Bloom, Healing Moss, Shadow Root, Golden Petal
- **Mushrooms**: Red Cap Mushroom
- **Crystals/Gems**: Mana Crystal, Frost Essence, Crystal Geode
- **Ore/Minerals**: Iron Ore, Earth Core
- **Creature Parts**: Orc Fang, Phoenix Feather, Spider Silk
- **Essences**: Vital Essence, Arcane Dust, Storm Dust

### By Primary Use:
- **Combat**: Orc Fang, Iron Ore, Phoenix Feather
- **Speed/Agility**: Spider Silk, Swiftroot, Storm Dust
- **Magic/Intelligence**: Arcane Dust, Wisdom Bloom, Mana Crystal, Crystal Geode
- **Health/Vitality**: Healing Moss, Vital Essence, Red Cap Mushroom
- **Elemental**: Emberleaf, Azure Kelp, Stonebloom, Zephyr Petal, Frost Essence, Earth Core, Storm Dust, Phoenix Feather
- **Special**: Shadow Root, Golden Petal

### By Rarity:
- **Common**: Emberleaf, Azure Kelp, Stonebloom, Zephyr Petal, Healing Moss, Iron Ore
- **Uncommon**: Red Cap Mushroom, Mana Crystal, Spider Silk, Arcane Dust, Swiftroot
- **Rare**: Orc Fang, Frost Essence, Earth Core, Storm Dust, Wisdom Bloom, Crystal Geode
- **Very Rare**: Phoenix Feather, Vital Essence, Shadow Root, Golden Petal

---

## Recommended Starting Set (10-12 ingredients)

For initial implementation, I recommend:

**Core Set (8 ingredients)**:
1. Emberleaf (fire)
2. Azure Kelp (water)
3. Stonebloom (earth)
4. Zephyr Petal (air)
5. Red Cap Mushroom (amanita)
6. Mana Crystal
7. **Orc Fang** (combat ingredient)
8. **Healing Moss** (health ingredient)

**Expansion Set (4 more for variety)**:
9. **Spider Silk** (speed/agility)
10. **Iron Ore** (defense/combat)
11. **Arcane Dust** (mana/magic)
12. **Swiftroot** (stamina/speed)

This gives you:
- All 4 elements covered
- Combat ingredients
- Health/mana ingredients
- Speed/stamina ingredients
- Good variety for interesting recipes

---

## Recipe Ideas with Expanded Ingredients

### Basic Potions (using core set):
- Health Potion: 2 Stonebloom + 1 Red Cap
- Mana Potion: 2 Zephyr Petal + 1 Mana Crystal

### Combat Potions:
- Strength Potion: 2 Orc Fang + 1 Iron Ore
- Defense Potion: 2 Iron Ore + 1 Stonebloom

### Utility Potions:
- Stamina Potion: 2 Swiftroot + 1 Healing Moss
- Speed Potion: 2 Spider Silk + 1 Swiftroot

### Elemental Potions:
- Fire Boost: 2 Emberleaf + 1 Phoenix Feather (if added)
- Water Boost: 2 Azure Kelp + 1 Frost Essence (if added)

---

## Implementation Notes

1. **Start Small**: Begin with 8-10 ingredients, expand later
2. **Balance**: Common ingredients for common potions, rare for powerful potions
3. **Theming**: Each ingredient should feel unique and serve a purpose
4. **Source Diversity**: Mix of enemy drops, plant nodes, mining nodes, rare finds
5. **Recipe Complexity**: Simple recipes (2-3 ingredients) for basic potions, complex for advanced

---

**Total Possible Ingredients**: 21 (6 existing + 15 new suggestions)

**Recommended Starting Set**: 8-12 ingredients for good variety without overwhelming complexity.

