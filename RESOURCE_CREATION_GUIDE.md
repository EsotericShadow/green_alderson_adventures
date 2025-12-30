# Resource Creation Guide

**Purpose**: Guide for creating ItemData, PotionData, EquipmentData, RecipeData, and MerchantData resources

---

## Ingredients (14 ItemData resources)

**Image Location**: `res://resources/assets/ingredients/`

### Elemental Herbs (4 items)

1. **Fire Herb** (`fire_herb.tres`)
   - **id**: `"fire_herb"`
   - **display_name**: `"Emberleaf"`
   - **description**: `"A vibrant red herb that radiates warmth. Its leaves curl like flames and smell of cinnamon and smoke."`
   - **icon**: `res://resources/assets/ingredients/emberleaf.png`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"material"`
   - **weight**: `0.1`

2. **Water Herb** (`water_herb.tres`)
   - **id**: `"water_herb"`
   - **display_name**: `"Azure Kelp"`
   - **description**: `"A cool, blue-green herb found near water sources. Its leaves shimmer like morning dew and taste of mint."`
   - **icon**: `res://resources/assets/ingredients/azure_kelp.png`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"material"`
   - **weight**: `0.1`

3. **Earth Herb** (`earth_herb.tres`)
   - **id**: `"earth_herb"`
   - **display_name**: `"Stonebloom"`
   - **description**: `"A hardy brown herb with thick, leathery leaves. It grows in rocky soil and has an earthy, mineral taste."`
   - **icon**: `res://resources/assets/ingredients/stonebloom.png`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"material"`
   - **weight**: `0.1`

4. **Air Herb** (`air_herb.tres`)
   - **id**: `"air_herb"`
   - **display_name**: `"Zephyr's Sage"`
   - **description**: `"A delicate, pale herb with feathery leaves that seem to float. It carries a light, floral scent on the breeze."`
   - **icon**: `res://resources/assets/ingredients/zephyr's_sage.png`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"material"`
   - **weight**: `0.05`

### Core Ingredients (2 items)

5. **Amanita Muscaria** (`amanita_muscaria.tres`)
   - **id**: `"amanita_muscaria"`
   - **display_name**: `"Red Cap Mushroom"`
   - **description**: `"A distinctive red and white spotted mushroom. Known for its potent magical properties, but handle with care."`
   - **icon**: `res://resources/assets/ingredients/red_cap_mushroom.png`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"material"`
   - **weight**: `0.2`

6. **Mana Crystal** (`mana_crystal.tres`)
   - **id**: `"mana_crystal"`
   - **display_name**: `"Mana Crystal"`
   - **description**: `"A small, glowing crystal fragment that pulses with magical energy. Essential for crafting powerful potions."`
   - **icon**: `res://resources/assets/ingredients/mana_crystal.png`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"material"`
   - **weight**: `0.3`

### Combat Ingredients (2 items)

7. **Orc Fang** (`orc_fang.tres`)
   - **id**: `"orc_fang"`
   - **display_name**: `"Orc Fang"`
   - **description**: `"A sharp fang from a defeated orc. Still warm to the touch and pulsing with residual aggression."`
   - **icon**: `res://resources/assets/ingredients/orc_fang.png`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"material"`
   - **weight**: `0.2`

8. **Phoenix Feather** (`phoenix_feather.tres`)
   - **id**: `"phoenix_feather"`
   - **display_name**: `"Phoenix Feather"`
   - **description**: `"A brilliant red feather that glows with inner fire. Extremely rare and powerful."`
   - **icon**: `res://resources/assets/ingredients/pheonix_feather.png` (note: typo in filename)
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"material"`
   - **weight**: `0.05`

### Speed/Agility Ingredients (2 items)

9. **Spider Silk** (`spider_silk.tres`)
   - **id**: `"spider_silk"`
   - **display_name**: `"Spider Silk"`
   - **description**: `"Silky thread spun by giant forest spiders. Light as air and incredibly strong."`
   - **icon**: `res://resources/assets/ingredients/spider_silk.png`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"material"`
   - **weight**: `0.1`

10. **Swiftroot** (`swiftroot.tres`)
    - **id**: `"swiftroot"`
    - **display_name**: `"Swiftroot"`
    - **description**: `"A gnarled root that seems to move on its own. Eating it makes you feel lighter."`
    - **icon**: `res://resources/assets/ingredients/swiftroot.png`
    - **stackable**: `true`
    - **max_stack**: `99`
    - **item_type**: `"material"`
    - **weight**: `0.2`

### Magic/Intelligence Ingredients (2 items)

11. **Arcane Dust** (`arcane_dust.tres`)
    - **id**: `"arcane_dust"`
    - **display_name**: `"Arcane Powder"`
    - **description**: `"Sparkling dust that glimmers with magical energy. Essential for mana restoration."`
    - **icon**: `res://resources/assets/ingredients/arcane_powder.png`
    - **stackable**: `true`
    - **max_stack**: `99`
    - **item_type**: `"material"`
    - **weight**: `0.05`

12. **Wisdom Bloom** (`wisdom_bloom.tres`)
    - **id**: `"wisdom_bloom"`
    - **display_name**: `"Wise Shade"`
    - **description**: `"A rare flower that blooms only in places of learning. Its petals shimmer with knowledge."`
    - **icon**: `res://resources/assets/ingredients/wise_shade.png`
    - **stackable**: `true`
    - **max_stack**: `99`
    - **item_type**: `"material"`
    - **weight**: `0.1`

### Health/Vitality Ingredients (1 item)

13. **Healing Moss** (`healing_moss.tres`)
    - **id**: `"healing_moss"`
    - **display_name**: `"Healing Moss"`
    - **description**: `"A vibrant green moss that glows softly. Known for its restorative properties."`
    - **icon**: `res://resources/assets/ingredients/healing_moss.png`
    - **stackable**: `true`
    - **max_stack**: `99`
    - **item_type**: `"material"`
    - **weight**: `0.1`

### Elemental Enhancement (1 item)

14. **Storm Dust** (`storm_dust.tres`)
    - **id**: `"storm_dust"`
    - **display_name**: `"Storm Dust"`
    - **description**: `"Crackling dust that sparks with electricity. Smells of ozone and carries air magic."`
    - **icon**: `res://resources/assets/ingredients/storm_dust.png`
    - **stackable**: `true`
    - **max_stack**: `99`
    - **item_type**: `"material"`
    - **weight**: `0.05`

---

## Potions (2 PotionData resources)

**Animation Location**: `res://resources/assets/animations/potions/`

1. **Health Potion** (`health_potion.tres`)
   - **id**: `"health_potion"`
   - **display_name**: `"Health Potion"`
   - **description**: `"Restores 50 health when consumed."`
   - **icon**: Use spritesheet from `res://resources/assets/animations/potions/health_potion_red/`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"consumable"`
   - **weight**: `0.2`
   - **effect**: `"restore_health"`
   - **potency**: `50`
   - **duration**: `0.0` (instant)

2. **Mana Potion** (`mana_potion.tres`)
   - **id**: `"mana_potion"`
   - **display_name**: `"Mana Potion"`
   - **description**: `"Restores 30 mana when consumed."`
   - **icon**: Use spritesheet from `res://resources/assets/animations/potions/mana_potion_blue/`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"consumable"`
   - **weight**: `0.2`
   - **effect**: `"restore_mana"`
   - **potency**: `30`
   - **duration**: `0.0` (instant)

3. **Gold Elixir** (`gold_elixir.tres`)
   - **id**: `"gold_elixir"`
   - **display_name**: `"Gold Elixir"`
   - **description**: `"A premium potion that restores health, mana, and stamina simultaneously."`
   - **icon**: Use spritesheet from `res://resources/assets/animations/potions/GOLD/`
   - **stackable**: `true`
   - **max_stack**: `99`
   - **item_type**: `"consumable"`
   - **weight**: `0.3`
   - **effect**: `"restore_all"`
   - **potency**: `50` (restores 50 HP, 50 MP, 50 stamina)
   - **duration**: `0.0` (instant)

---

## Recipes (Suggested RecipeData resources)

### Basic Potions

1. **Health Potion Recipe** (`recipe_health_potion.tres`)
   - **id**: `"recipe_health_potion"`
   - **display_name**: `"Health Potion Recipe"`
   - **result**: Reference to `health_potion.tres`
   - **result_count**: `1`
   - **ingredients**: 
     - `earth_herb.tres` (Stonebloom)
     - `amanita_muscaria.tres` (Red Cap Mushroom)
   - **ingredient_counts**: `[2, 1]` (2 Stonebloom + 1 Red Cap = 1 Health Potion)

2. **Mana Potion Recipe** (`recipe_mana_potion.tres`)
   - **id**: `"recipe_mana_potion"`
   - **display_name**: `"Mana Potion Recipe"`
   - **result**: Reference to `mana_potion.tres`
   - **result_count**: `1`
   - **ingredients**:
     - `air_herb.tres` (Zephyr's Sage)
     - `mana_crystal.tres` (Mana Crystal)
   - **ingredient_counts**: `[2, 1]` (2 Zephyr's Sage + 1 Mana Crystal = 1 Mana Potion)

### Combat Potions

3. **Strength Potion Recipe** (`recipe_strength_potion.tres`)
   - **id**: `"recipe_strength_potion"`
   - **display_name**: `"Strength Potion Recipe"`
   - **result**: Reference to `strength_potion.tres` (PotionData with effect="buff_strength", potency=20, duration=60.0)
   - **result_count**: `1`
   - **ingredients**:
     - `orc_fang.tres` (Orc Fang)
     - `phoenix_feather.tres` (Phoenix Feather)
   - **ingredient_counts**: `[2, 1]` (2 Orc Fang + 1 Phoenix Feather = 1 Strength Potion)

4. **Defense Potion Recipe** (`recipe_defense_potion.tres`)
   - **id**: `"recipe_defense_potion"`
   - **display_name**: `"Defense Potion Recipe"`
   - **result**: Reference to `defense_potion.tres` (PotionData with effect="buff_defense", potency=15, duration=60.0)
   - **result_count**: `1`
   - **ingredients**:
     - `earth_herb.tres` (Stonebloom)
     - `healing_moss.tres` (Healing Moss)
   - **ingredient_counts**: `[2, 1]` (2 Stonebloom + 1 Healing Moss = 1 Defense Potion)

### Utility Potions

5. **Stamina Potion Recipe** (`recipe_stamina_potion.tres`)
   - **id**: `"recipe_stamina_potion"`
   - **display_name**: `"Stamina Potion Recipe"`
   - **result**: Reference to `stamina_potion.tres` (PotionData with effect="restore_stamina", potency=50, duration=0.0)
   - **result_count**: `1`
   - **ingredients**:
     - `swiftroot.tres` (Swiftroot)
     - `healing_moss.tres` (Healing Moss)
   - **ingredient_counts**: `[2, 1]` (2 Swiftroot + 1 Healing Moss = 1 Stamina Potion)

6. **Speed Potion Recipe** (`recipe_speed_potion.tres`)
   - **id**: `"recipe_speed_potion"`
   - **display_name**: `"Speed Potion Recipe"`
   - **result**: Reference to `speed_potion.tres` (PotionData with effect="buff_speed", potency=25, duration=45.0)
   - **result_count**: `1`
   - **ingredients**:
     - `spider_silk.tres` (Spider Silk)
     - `swiftroot.tres` (Swiftroot)
   - **ingredient_counts**: `[2, 1]` (2 Spider Silk + 1 Swiftroot = 1 Speed Potion)

---

## Equipment (10 EquipmentData resources)

**Image Location**: `res://resources/assets/equipment/`

### Head
1. **Wizard Hat** (`wizard_hat.tres`)
   - **id**: `"wizard_hat"`
   - **display_name**: `"Apprentice's Cap"`
   - **description**: `"A simple pointed hat worn by novice mages."`
   - **icon**: `res://resources/assets/equipment/dark_wizard_hat.png`
   - **slot**: `"head"`
   - **resilience_bonus**: `1`
   - **int_bonus**: `2`
   - **weight**: `0.5`

### Body
2. **Robe** (`robe.tres`)
   - **id**: `"robe"`
   - **display_name**: `"Scholar's Robe"`
   - **description**: `"A comfortable robe favored by spellcasters."`
   - **icon**: `res://resources/assets/equipment/dark_wizard_robe_top.png`
   - **slot**: `"body"`
   - **resilience_bonus**: `2`
   - **int_bonus**: `3`
   - **weight**: `1.0`

### Gloves
3. **Mage Gloves** (`mage_gloves.tres`)
   - **id**: `"mage_gloves"`
   - **display_name**: `"Spellweaver's Gloves"`
   - **description**: `"Fine gloves that enhance magical precision."`
   - **icon**: `res://resources/assets/equipment/dark_wizard_gloves.png`
   - **slot**: `"gloves"`
   - **agility_bonus**: `1`
   - **int_bonus**: `2`
   - **weight**: `0.3`

### Boots
4. **Traveler's Boots** (`travelers_boots.tres`)
   - **id**: `"travelers_boots"`
   - **display_name**: `"Wanderer's Boots"`
   - **description**: `"Sturdy boots for long journeys."`
   - **icon**: `res://resources/assets/equipment/dark_wizard_boots.png`
   - **slot**: `"boots"`
   - **resilience_bonus**: `1`
   - **agility_bonus**: `2`
   - **weight**: `0.8`

### Weapon
5. **Staff** (`staff.tres`)
   - **id**: `"staff"`
   - **display_name**: `"Oak Staff"`
   - **description**: `"A simple wooden staff that channels magical energy."`
   - **icon**: `res://resources/assets/equipment/dark_wizard_corrupt_staff.png`
   - **slot**: `"weapon"`
   - **int_bonus**: `4`
   - **flat_damage_bonus**: `3`
   - **weight**: `1.5`

### Book (Off-hand)
6. **Spellbook** (`spellbook.tres`)
   - **id**: `"spellbook"`
   - **display_name**: `"Grimoire of Basics"`
   - **description**: `"A beginner's spellbook with fundamental incantations."`
   - **icon**: `res://resources/assets/equipment/dark_wizard_book.png`
   - **slot**: `"book"`
   - **int_bonus**: `3`
   - **damage_percentage_bonus**: `0.1` (10% spell damage)
   - **weight**: `1.2`

### Ring 1
7. **Copper Ring** (`copper_ring.tres`)
   - **id**: `"copper_ring"`
   - **display_name**: `"Ring of Focus"`
   - **description**: `"A simple copper ring that aids concentration."`
   - **icon**: `res://resources/assets/equipment/dark_wizard_ring.png`
   - **slot**: `"ring1"`
   - **int_bonus**: `1`
   - **weight**: `0.1`

### Ring 2
8. **Silver Ring** (`silver_ring.tres`)
   - **id**: `"silver_ring"`
   - **display_name**: `"Ring of Vitality"`
   - **description**: `"A silver ring that enhances life force."`
   - **icon**: `res://resources/assets/equipment/jiraiya's_blessing_ring.png`
   - **slot**: `"ring2"`
   - **vit_bonus**: `2`
   - **weight**: `0.1`

### Legs
9. **Mage Leggings** (`mage_leggings.tres`)
   - **id**: `"mage_leggings"`
   - **display_name**: `"Scholar's Leggings"`
   - **description**: `"Comfortable leggings worn under robes."`
   - **icon**: `res://resources/assets/equipment/dark_wizard_robe_bottom.png`
   - **slot**: `"legs"`
   - **resilience_bonus**: `1`
   - **agility_bonus**: `1`
   - **weight**: `0.6`

### Amulet
10. **Amulet of Power** (`amulet_of_power.tres`)
    - **id**: `"amulet_of_power"`
    - **display_name**: `"Amulet of Minor Power"`
    - **description**: `"A small amulet that amplifies magical abilities."`
    - **icon**: `res://resources/assets/equipment/dark_wizard_amulet.png`
    - **slot**: `"amulet"`
    - **int_bonus**: `2`
    - **damage_percentage_bonus**: `0.05` (5% spell damage)
    - **weight**: `0.2`

---

## Merchant (1 MerchantData resource)

1. **Village Merchant** (`merchant_village.tres`)
   - **id**: `"merchant_village"`
   - **display_name**: `"Village Shopkeeper"`
   - **greeting**: `"Welcome, traveler! I have fine wares for sale. What catches your eye?"`
   - **stock**: Array of ItemData references:
     - `health_potion.tres` (price: 25 gold)
     - `mana_potion.tres` (price: 20 gold)
     - `fire_herb.tres` (price: 5 gold)
     - `water_herb.tres` (price: 5 gold)
     - `earth_herb.tres` (price: 5 gold)
     - `air_herb.tres` (price: 5 gold)
     - `amanita_muscaria.tres` (price: 10 gold)
     - `crystal_shard.tres` (price: 15 gold)
     - `wizard_hat.tres` (price: 50 gold)
     - `robe.tres` (price: 75 gold)
     - `staff.tres` (price: 100 gold)
   - **prices**: `[25, 20, 5, 5, 5, 5, 10, 15, 50, 75, 100]`

---

## Summary

### Ingredients (14 ItemData):
**Elemental Herbs (4):**
1. Emberleaf (fire herb)
2. Azure Kelp (water herb)
3. Stonebloom (earth herb)
4. Zephyr's Sage (air herb)

**Core (2):**
5. Red Cap Mushroom (amanita muscaria)
6. Mana Crystal

**Combat (2):**
7. Orc Fang
8. Phoenix Feather

**Speed/Agility (2):**
9. Spider Silk
10. Swiftroot

**Magic/Intelligence (2):**
11. Arcane Powder
12. Wise Shade

**Health/Vitality (1):**
13. Healing Moss

**Elemental Enhancement (1):**
14. Storm Dust

### Potions (7 PotionData):
1. Health Potion (restores 50 HP) → RED animation
2. Mana Potion (restores 30 MP) → BLUE animation
3. Gold Elixir (restores 50 HP + 50 MP + 50 stamina) → GOLD animation
4. Strength Potion (buff_strength, +20% damage, 60s) → ORANGE animation
5. Defense Potion (buff_defense, +15% reduction, 60s) → BLACK animation
6. Stamina Potion (restores 50 stamina) → GREEN animation
7. Speed Potion (buff_speed, +25% speed, 45s) → YELLOW animation

**See `POTION_COLOR_MAPPING.md` for detailed color-to-mechanic mappings.**

### Recipes (6 RecipeData suggested):
1. Health Potion Recipe (2 Stonebloom + 1 Red Cap)
2. Mana Potion Recipe (2 Zephyr's Sage + 1 Mana Crystal)
3. Strength Potion Recipe (2 Orc Fang + 1 Phoenix Feather)
4. Defense Potion Recipe (2 Stonebloom + 1 Healing Moss)
5. Stamina Potion Recipe (2 Swiftroot + 1 Healing Moss)
6. Speed Potion Recipe (2 Spider Silk + 1 Swiftroot)

### Equipment (10 EquipmentData):
1. Apprentice's Cap (head)
2. Scholar's Robe (body)
3. Spellweaver's Gloves (gloves)
4. Wanderer's Boots (boots)
5. Oak Staff (weapon)
6. Grimoire of Basics (book)
7. Ring of Focus (ring1)
8. Ring of Vitality (ring2)
9. Scholar's Leggings (legs)
10. Amulet of Minor Power (amulet)

### Merchant (1 MerchantData):
1. Village Shopkeeper (sells all items above)

---

## Creation Steps

1. **Create ItemData resources** (6 files in `resources/items/`)
   - Right-click `resources/items/` → New Resource → ItemData
   - Fill in properties as listed above

2. **Create PotionData resources** (3 required files in `resources/potions/`)
   - Right-click `resources/potions/` → New Resource → PotionData
   - Fill in properties as listed above
   - Required: Health Potion, Mana Potion, Gold Elixir

3. **Create EquipmentData resources** (10 files in `resources/equipment/`)
   - Right-click `resources/equipment/` → New Resource → EquipmentData
   - Fill in properties as listed above

4. **Create RecipeData resources** (2 files in `resources/recipes/`)
   - Right-click `resources/recipes/` → New Resource → RecipeData
   - Set result to reference potion
   - Add ingredients array (drag ItemData resources)
   - Set ingredient_counts array

5. **Create MerchantData resource** (1 file in `resources/merchants/`)
   - Right-click `resources/merchants/` → New Resource → MerchantData
   - Add stock array (drag ItemData/EquipmentData/PotionData)
   - Set prices array

---

## Notes

- **Icons**: You can set icons later - the systems will work without them initially
- **Animations**: Potion animations can be added later
- **Balancing**: Stats can be adjusted later - these are starter values
- **Gold Prices**: Can be adjusted for balance

Once you create these resources, I'll build all the systems that use them!

---

**Total Resources to Create**: 33 files
- 14 ItemData (ingredients) ✅ **Images provided**
- 6 PotionData (potions) - suggested, you can create more/less
- 10 EquipmentData (equipment) ✅ **Images provided**
- 6 RecipeData (recipes) - suggested, you can create more/less
- 1 MerchantData (merchant)

