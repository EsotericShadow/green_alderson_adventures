# Ingredient Quick Reference - Create These Resources

**Image Location**: `res://resources/assets/ingredients/`

---

## Create These 14 ItemData Resources

### In `res://resources/items/` directory:

| Resource File | ID | Display Name | Icon Path |
|---------------|-----|--------------|-----------|
| `fire_herb.tres` | `fire_herb` | Emberleaf | `res://resources/assets/ingredients/emberleaf.png` |
| `water_herb.tres` | `water_herb` | Azure Kelp | `res://resources/assets/ingredients/azure_kelp.png` |
| `earth_herb.tres` | `earth_herb` | Stonebloom | `res://resources/assets/ingredients/stonebloom.png` |
| `air_herb.tres` | `air_herb` | Zephyr's Sage | `res://resources/assets/ingredients/zephyr's_sage.png` |
| `amanita_muscaria.tres` | `amanita_muscaria` | Red Cap Mushroom | `res://resources/assets/ingredients/red_cap_mushroom.png` |
| `mana_crystal.tres` | `mana_crystal` | Mana Crystal | `res://resources/assets/ingredients/mana_crystal.png` |
| `orc_fang.tres` | `orc_fang` | Orc Fang | `res://resources/assets/ingredients/orc_fang.png` |
| `phoenix_feather.tres` | `phoenix_feather` | Phoenix Feather | `res://resources/assets/ingredients/pheonix_feather.png` |
| `spider_silk.tres` | `spider_silk` | Spider Silk | `res://resources/assets/ingredients/spider_silk.png` |
| `swiftroot.tres` | `swiftroot` | Swiftroot | `res://resources/assets/ingredients/swiftroot.png` |
| `arcane_dust.tres` | `arcane_dust` | Arcane Powder | `res://resources/assets/ingredients/arcane_powder.png` |
| `wisdom_bloom.tres` | `wisdom_bloom` | Wise Shade | `res://resources/assets/ingredients/wise_shade.png` |
| `healing_moss.tres` | `healing_moss` | Healing Moss | `res://resources/assets/ingredients/healing_moss.png` |
| `storm_dust.tres` | `storm_dust` | Storm Dust | `res://resources/assets/ingredients/storm_dust.png` |

---

## Common Properties for All Ingredients

- **stackable**: `true`
- **max_stack**: `99`
- **item_type**: `"material"`
- **weight**: `0.1` (most), `0.05` (light ones), `0.2` (heavier ones), `0.3` (Mana Crystal)

---

## Function Mapping (Your Renames → Original Concept)

- **zephyr's_sage** = Zephyr Petal (air element, speed/stamina)
- **arcane_powder** = Arcane Dust (mana/magic)
- **wise_shade** = Wisdom Bloom (intelligence)
- **pheonix_feather** = Phoenix Feather (fire element, combat)

All other names match exactly!

---

## Next Steps

1. Create 14 ItemData resources in `res://resources/items/`
2. Set the icon path for each (from table above)
3. Fill in id, display_name, description (see RESOURCE_CREATION_GUIDE.md for descriptions)
4. Then create potions, recipes, equipment, and merchant

Once you create these, I'll build all the systems!

