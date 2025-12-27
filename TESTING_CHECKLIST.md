# Manual Testing Checklist

**Date**: Current Session  
**Purpose**: Comprehensive manual testing flow for Milestones 1-3

---

## Pre-Test: Automated Validation

✅ **Automated System Validator** runs automatically on game start
- Check console output for test results
- All systems should pass validation before manual testing

---

## Test Flow 1: Combat & Leveling

### Objective: Kill 3 orcs with fireball, leveling up fire element

**Steps:**
1. [ ] Locate first orc
2. [ ] Cast fireball at orc until it dies
3. [ ] Verify fire element XP gained (check console logs)
4. [ ] Verify fire element level-up if applicable (check console logs)
5. [ ] Repeat for 2nd orc
6. [ ] Repeat for 3rd orc
7. [ ] Verify fire element has leveled up at least once

**Expected Results:**
- Fire element gains XP on each hit
- Fire element levels up when XP threshold is met
- Console shows XP gain and level-up messages
- Spell damage increases with level

---

## Test Flow 2: UI Navigation

### Objective: Navigate through all sidebar tabs and verify UI updates

**Steps:**
1. [ ] Open sidebar (if applicable) or access UI panels
2. [ ] Click through Stats tab
   - [ ] Verify all base stats display (Resilience, Agility, INT, VIT)
   - [ ] Verify XP bars show current XP
   - [ ] Verify levels are displayed correctly
   - [ ] Verify elemental levels display (Fire, Water, Earth, Air)
3. [ ] Click through Equipment tab
   - [ ] Verify all equipment slots display
   - [ ] Verify equipment slots are empty (if no items equipped)
   - [ ] Verify equipment UI updates when items are equipped
4. [ ] Click through Inventory tab
   - [ ] Verify inventory grid displays
   - [ ] Verify inventory slots are visible
   - [ ] Verify inventory updates when items are added/removed
5. [ ] Click through Spells tab
   - [ ] Verify spell hotbar displays
   - [ ] Verify spells are shown in slots
   - [ ] Verify spell selection works
6. [ ] Click through Settings tab (if exists)
   - [ ] Verify settings options display

**Expected Results:**
- All tabs are accessible
- UI updates reflect current game state
- No UI errors or missing elements
- Stats show correct values

---

## Test Flow 3: Movement & Direction Testing

### Objective: Test movement in all directions and states

**Steps:**
1. [ ] **Walking in all directions:**
   - [ ] Walk North (W/Up Arrow)
   - [ ] Walk South (S/Down Arrow)
   - [ ] Walk East (D/Right Arrow)
   - [ ] Walk West (A/Left Arrow)
   - [ ] Walk Northeast (diagonal)
   - [ ] Walk Northwest (diagonal)
   - [ ] Walk Southeast (diagonal)
   - [ ] Walk Southwest (diagonal)
   - [ ] Verify player sprite faces correct direction
   - [ ] Verify animation plays correctly

2. [ ] **Idling in all directions:**
   - [ ] Stop moving while facing North
   - [ ] Stop moving while facing South
   - [ ] Stop moving while facing East
   - [ ] Stop moving while facing West
   - [ ] Stop moving while facing each diagonal
   - [ ] Verify idle animation plays
   - [ ] Verify player maintains facing direction

3. [ ] **Running in all directions:**
   - [ ] Run North (Ctrl+W)
   - [ ] Run South (Ctrl+S)
   - [ ] Run East (Ctrl+D)
   - [ ] Run West (Ctrl+A)
   - [ ] Run in all diagonals
   - [ ] Verify stamina decreases while running
   - [ ] Verify stamina regenerates when not running
   - [ ] Verify movement speed is faster than walking

4. [ ] **Spell casting from all directions:**
   - [ ] Cast spell while facing North
   - [ ] Cast spell while facing South
   - [ ] Cast spell while facing East
   - [ ] Cast spell while facing West
   - [ ] Cast spell while facing each diagonal
   - [ ] Verify projectile spawns in correct direction
   - [ ] Verify projectile travels in facing direction
   - [ ] Verify mana is consumed

**Expected Results:**
- All 8 directions work correctly
- Animations match movement direction
- Stamina system works (consumption and regeneration)
- Spells cast in correct direction
- No movement glitches or stuck states

---

## Test Flow 4: Enemy Interaction

### Objective: Test all enemy attack and movement directions

**Steps:**
1. [ ] Approach orc from North
   - [ ] Verify orc detects player
   - [ ] Verify orc chases player
   - [ ] Verify orc attacks when in range
   - [ ] Verify orc faces correct direction when attacking

2. [ ] Approach orc from South
   - [ ] Repeat detection/chase/attack checks

3. [ ] Approach orc from East
   - [ ] Repeat detection/chase/attack checks

4. [ ] Approach orc from West
   - [ ] Repeat detection/chase/attack checks

5. [ ] Approach orc from diagonals
   - [ ] Repeat detection/chase/attack checks

6. [ ] Move around orc in circle
   - [ ] Verify orc tracks player position
   - [ ] Verify orc faces player while chasing
   - [ ] Verify orc attacks when in range

7. [ ] Test orc leash behavior
   - [ ] Lead orc away from spawn
   - [ ] Verify orc returns to spawn if too far
   - [ ] Verify orc stops chasing at leash distance

**Expected Results:**
- Orcs detect player from all directions
- Orcs chase player correctly
- Orcs attack in correct direction
- Orc AI behaves correctly
- No enemy glitches or stuck states

---

## Test Flow 5: Damage & Death

### Objective: Test taking damage and death mechanics

**Steps:**
1. [ ] **Take damage:**
   - [ ] Let orc hit player
   - [ ] Verify health decreases
   - [ ] Verify health bar updates
   - [ ] Verify Resilience XP gained (check console)
   - [ ] Verify damage reduction applies (check console logs)
   - [ ] Verify screen shake (if implemented)
   - [ ] Verify invincibility frames (if implemented)

2. [ ] **Take multiple hits:**
   - [ ] Take 3-5 hits from orc
   - [ ] Verify health decreases each time
   - [ ] Verify health bar updates continuously
   - [ ] Verify Resilience XP gained for each hit

3. [ ] **Death test (FINAL TEST):**
   - [ ] Continue taking damage until health reaches 0
   - [ ] Verify player dies
   - [ ] Verify death signal is emitted (check console)
   - [ ] Verify death state is set
   - [ ] Note: No death animation yet (expected)

**Expected Results:**
- Damage is applied correctly
- Health bar updates in real-time
- Resilience XP gained on taking damage
- Damage reduction formula works
- Death triggers correctly
- No health going below 0 or above max

---

## Issues to Document

If any issues are found during testing, document them here:

### Critical Issues:
- 

### Minor Issues:
- 

### Suggestions:
- 

---

## Test Completion

- [ ] All test flows completed
- [ ] All expected results verified
- [ ] Issues documented
- [ ] Console logs reviewed
- [ ] Ready for next milestone

