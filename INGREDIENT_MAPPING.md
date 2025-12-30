# Ingredient Mapping - Actual Files to Game Mechanics

**Purpose**: Map the actual ingredient image files to their game mechanics and resource properties

---

## Ingredient Files Provided (14 total)

### Elemental Herbs (4)
1. **emberleaf.png** → `fire_herb` (Emberleaf)
   - **Function**: Fire element ingredient
   - **Use**: Fire potions, fire spell enhancement, fire resistance

2. **azure_kelp.png** → `water_herb` (Azure Kelp)
   - **Function**: Water element ingredient
   - **Use**: Water potions, water spell enhancement, water resistance

3. **stonebloom.png** → `earth_herb` (Stonebloom)
   - **Function**: Earth element ingredient
   - **Use**: Earth potions, earth spell enhancement, defense potions

4. **zephyr's_sage.png** → `air_herb` (Zephyr's Sage - renamed from Zephyr Petal)
   - **Function**: Air element ingredient
   - **Use**: Air potions, air spell enhancement, speed potions, stamina potions

### Core Ingredients (2)
5. **red_cap_mushroom.png** → `amanita_muscaria` (Red Cap Mushroom)
   - **Function**: Health/restoration ingredient
   - **Use**: Health potions, vitality potions

6. **mana_crystal.png** → `mana_crystal` (Mana Crystal)
   - **Function**: Magic/mana ingredient
   - **Use**: Mana potions, spell enhancement, intelligence potions

### Combat Ingredients (2)
7. **orc_fang.png** → `orc_fang` (Orc Fang)
   - **Function**: Combat/strength ingredient
   - **Use**: Strength potions, damage potions, combat buffs

8. **pheonix_feather.png** → `phoenix_feather` (Phoenix Feather - note: typo in filename)
   - **Function**: Fire element + high-tier combat
   - **Use**: Fire potions, high-tier fire spells, resurrection items, fire resistance

### Speed/Agility Ingredients (2)
9. **spider_silk.png** → `spider_silk` (Spider Silk)
   - **Function**: Speed/agility ingredient
   - **Use**: Speed potions, agility potions, light armor crafting

10. **swiftroot.png** → `swiftroot` (Swiftroot)
    - **Function**: Speed/stamina ingredient
    - **Use**: Stamina potions, movement speed buffs, agility potions

### Magic/Intelligence Ingredients (2)
11. **arcane_powder.png** → `arcane_dust` (Arcane Powder - renamed from Arcane Dust)
    - **Function**: Magic/mana ingredient
    - **Use**: Mana potions, spell enhancement, intelligence potions

12. **wise_shade.png** → `wisdom_bloom` (Wise Shade - renamed from Wisdom Bloom)
    - **Function**: Intelligence/wisdom ingredient
    - **Use**: Intelligence potions, spell power boosts, XP gain items

### Health/Vitality Ingredients (1)
13. **healing_moss.png** → `healing_moss` (Healing Moss)
    - **Function**: Health/restoration ingredient
    - **Use**: Health potions, regeneration potions, vitality potions

### Elemental Enhancement (1)
14. **storm_dust.png** → `storm_dust` (Storm Dust)
    - **Function**: Air element + speed enhancement
    - **Use**: Air potions, speed potions, air spell enhancement, lightning effects

---

## Resource Creation Mapping

### ItemData Resources to Create (14 total)

| Image File | Resource ID | Display Name | Primary Use |
|------------|-------------|--------------|-------------|
| emberleaf.png | `fire_herb` | Emberleaf | Fire element |
| azure_kelp.png | `water_herb` | Azure Kelp | Water element |
| stonebloom.png | `earth_herb` | Stonebloom | Earth element |
| zephyr's_sage.png | `air_herb` | Zephyr's Sage | Air element |
| red_cap_mushroom.png | `amanita_muscaria` | Red Cap Mushroom | Health |
| mana_crystal.png | `mana_crystal` | Mana Crystal | Mana |
| orc_fang.png | `orc_fang` | Orc Fang | Combat/Strength |
| pheonix_feather.png | `phoenix_feather` | Phoenix Feather | Fire/Combat |
| spider_silk.png | `spider_silk` | Spider Silk | Speed/Agility |
| swiftroot.png | `swiftroot` | Swiftroot | Speed/Stamina |
| arcane_powder.png | `arcane_dust` | Arcane Powder | Mana/Magic |
| wise_shade.png | `wisdom_bloom` | Wise Shade | Intelligence |
| healing_moss.png | `healing_moss` | Healing Moss | Health |
| storm_dust.png | `storm_dust` | Storm Dust | Air/Speed |

---

## Suggested Potion Recipes

### Basic Potions
1. **Health Potion**
   - 2 Stonebloom + 1 Red Cap Mushroom
   - Restores 50 HP

2. **Mana Potion**
   - 2 Zephyr's Sage + 1 Mana Crystal
   - Restores 30 MP

### Combat Potions
3. **Strength Potion** (buff_strength)
   - 2 Orc Fang + 1 Phoenix Feather
   - +20% damage for 60 seconds

4. **Defense Potion** (buff_defense)
   - 2 Stonebloom + 1 Healing Moss
   - +15% damage reduction for 60 seconds

### Utility Potions
5. **Stamina Potion** (restore_stamina)
   - 2 Swiftroot + 1 Healing Moss
   - Restores 50 stamina

6. **Speed Potion** (buff_speed)
   - 2 Spider Silk + 1 Swiftroot
   - +25% movement speed for 45 seconds

### Elemental Potions
7. **Fire Resistance Potion**
   - 1 Phoenix Feather + 2 Emberleaf
   - Fire damage reduction (custom effect)

8. **Air Boost Potion**
   - 1 Storm Dust + 2 Zephyr's Sage
   - Air spell enhancement (custom effect)

### Advanced Potions
9. **Greater Health Potion**
   - 1 Healing Moss + 2 Red Cap Mushroom + 1 Phoenix Feather
   - Restores 100 HP

10. **Greater Mana Potion**
    - 1 Arcane Powder + 2 Mana Crystal + 1 Wise Shade
    - Restores 75 MP

11. **Intelligence Boost Potion**
    - 2 Wise Shade + 1 Arcane Powder
    - Temporary INT boost (custom effect)

---

## Resource File Paths

All ingredient ItemData resources should be created in:
`res://resources/items/`

And reference the images from:
`res://resources/assets/ingredients/`

Example:
- Resource: `res://resources/items/fire_herb.tres`
- Icon: `res://resources/assets/ingredients/emberleaf.png`

---

## Notes

- **Renamed items**: Functionality assumed similar to original suggestions
  - `zephyr's_sage` = Zephyr Petal (air element)
  - `arcane_powder` = Arcane Dust (mana/magic)
  - `wise_shade` = Wisdom Bloom (intelligence)

- **Filename typo**: `pheonix_feather.png` (should be "phoenix" but that's fine)

- **Total ingredients**: 14 (more than the original 6-12 suggested, great for variety!)

- **Coverage**: All game mechanics covered:
  - ✅ All 4 elements (fire, water, earth, air)
  - ✅ Health restoration
  - ✅ Mana restoration
  - ✅ Stamina restoration
  - ✅ Combat buffs (strength, defense)
  - ✅ Speed buffs
  - ✅ Intelligence/magic enhancement

---

**Ready to create resources!** Once you create the 14 ItemData resources using these images, I'll build all the systems that use them.

