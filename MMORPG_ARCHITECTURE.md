# MMORPG Architecture Plan

**Purpose**: Architectural changes to prepare the codebase for MMORPG conversion while maintaining current single-player functionality.

---

## Core Principles

1. **Separation of Concerns**: Game state separate from presentation
2. **Server Authority**: All critical game logic must be server-validatable
3. **Network Abstraction**: Local and networked implementations can be swapped
4. **Entity System**: Unified system for players, NPCs, enemies
5. **Serialization**: All game state must be serializable
6. **Authority Management**: Clear distinction between server and client authority

---

## 1. Entity System Architecture

### Current State
- `player.gd` - Player-specific logic
- `base_enemy.gd` - Enemy-specific logic
- No unified entity system

### Proposed Structure

```
scripts/
├── entities/
│   ├── base_entity.gd          # Base class for all entities (player, enemy, NPC)
│   ├── entity_data.gd          # Serializable entity state (Resource)
│   ├── entity_controller.gd    # Client-side entity control
│   └── entity_server.gd         # Server-side entity authority
├── network/
│   ├── network_manager.gd       # Network abstraction layer
│   ├── network_entity.gd        # Networked entity synchronization
│   └── network_authority.gd     # Authority management
└── server/
    ├── server_entity_manager.gd # Server-side entity management
    └── server_validation.gd     # Server-side validation logic
```

**Benefits**:
- Unified system for all entities
- Easy to add NPCs, pets, etc.
- Network synchronization built-in
- Server can manage all entities

---

## 2. State Management Layer

### Current State
- `PlayerStats` - Direct access, client-side only
- `InventorySystem` - Direct access, client-side only
- `SpellSystem` - Direct access, client-side only
- No serialization layer

### Proposed Structure

```
scripts/
├── state/
│   ├── game_state.gd            # Central game state container
│   ├── player_state.gd          # Serializable player state
│   ├── inventory_state.gd       # Serializable inventory state
│   ├── spell_state.gd           # Serializable spell progression state
│   └── world_state.gd           # Serializable world state
├── persistence/
│   ├── state_serializer.gd      # JSON/Variant serialization
│   ├── database_adapter.gd      # Database interface (SQLite/PostgreSQL)
│   └── save_system.gd           # Save/load system
```

**Benefits**:
- All state is serializable
- Easy to save/load
- Easy to sync over network
- Database-ready

---

## 3. Network Abstraction Layer

### Proposed Structure

```
scripts/
├── network/
│   ├── network_interface.gd     # Abstract interface for local/network
│   ├── local_network.gd          # Local implementation (current behavior)
│   ├── multiplayer_network.gd   # Godot MultiplayerAPI implementation
│   ├── network_commands.gd       # Command pattern for actions
│   └── network_sync.gd           # State synchronization
```

**Benefits**:
- Can swap between local and networked
- Current game works unchanged
- Easy to add networking later
- Command pattern prevents cheating

---

## 4. Authority System

### Proposed Structure

```
scripts/
├── authority/
│   ├── authority_manager.gd     # Manages who controls what
│   ├── server_authority.gd      # Server-authoritative actions
│   └── client_authority.gd      # Client-authoritative actions (input, UI)
```

**Server Authority** (must validate):
- Damage calculation
- XP gain
- Item acquisition
- Stat changes
- Combat actions
- Inventory changes

**Client Authority** (can predict):
- Movement (with server reconciliation)
- Animation
- UI updates
- Camera control
- Visual effects

---

## 5. Action/Command System

### Current State
- Direct method calls (e.g., `PlayerStats.take_damage()`)
- No validation layer
- No command history

### Proposed Structure

```
scripts/
├── commands/
│   ├── command_base.gd           # Base command class
│   ├── damage_command.gd         # Damage action
│   ├── move_command.gd           # Movement action
│   ├── cast_spell_command.gd    # Spell casting action
│   ├── use_item_command.gd       # Item usage action
│   └── command_queue.gd          # Command execution queue
```

**Benefits**:
- All actions are commands
- Server can validate/reject
- Easy to replay/undo
- Cheat prevention

---

## 6. Database Layer

### Proposed Structure

```
scripts/
├── database/
│   ├── database_interface.gd     # Abstract database interface
│   ├── sqlite_adapter.gd         # SQLite implementation (dev/testing)
│   ├── postgresql_adapter.gd     # PostgreSQL implementation (production)
│   ├── player_repository.gd      # Player data access
│   ├── inventory_repository.gd   # Inventory data access
│   └── world_repository.gd        # World state data access
```

**Data to Persist**:
- Player stats and progression
- Inventory and equipment
- Spell progression
- World state (chests, NPCs, etc.)
- Character position (optional)

---

## 7. Server Architecture

### Proposed Structure

```
scripts/
├── server/
│   ├── server_main.gd            # Server entry point
│   ├── server_loop.gd            # Server game loop
│   ├── server_validation.gd     # All validation logic
│   ├── server_combat.gd          # Server-side combat
│   ├── server_spawner.gd         # Entity spawning
│   └── server_world.gd           # World state management
```

**Server Responsibilities**:
- Validate all player actions
- Manage all entities
- Calculate all damage/XP
- Spawn/despawn entities
- Maintain world state
- Anti-cheat measures

---

## Implementation Phases

### Phase 1: Foundation (Non-Breaking)
1. Create entity system (keep player/enemy working)
2. Create state management layer (wrap existing systems)
3. Add serialization to all state
4. Create command system (optional, can add later)

### Phase 2: Network Abstraction (Non-Breaking)
1. Create network interface
2. Implement local network (current behavior)
3. Refactor systems to use network interface
4. Test that nothing breaks

### Phase 3: Server Preparation
1. Create server architecture
2. Move validation logic to server
3. Create authority system
4. Implement server-authoritative actions

### Phase 4: Multiplayer Integration
1. Implement multiplayer network
2. Add entity synchronization
3. Add player connection handling
4. Test multiplayer

### Phase 5: Database Integration
1. Create database layer
2. Implement persistence
3. Add character saves
4. Add world persistence

---

## Migration Strategy

### Step 1: Wrap Existing Systems
- Create `GameState` that wraps `PlayerStats`, `InventorySystem`, etc.
- Keep existing autoloads working
- Gradually migrate code to use `GameState`

### Step 2: Add Entity System
- Create `BaseEntity` class
- Make `Player` and `BaseEnemy` extend it
- Keep existing functionality

### Step 3: Add Serialization
- Make all state classes extend `Resource`
- Add `to_dict()` and `from_dict()` methods
- Test save/load

### Step 4: Add Network Layer
- Create network interface
- Implement local version first
- Swap implementations when ready

---

## Key Design Decisions

1. **Backward Compatibility**: All changes must maintain current functionality
2. **Gradual Migration**: Can migrate piece by piece
3. **Test-Driven**: Each phase should be testable independently
4. **Server-First**: Design for server authority from the start
5. **Data-Driven**: All game data should be Resources (already done!)

---

## Files to Create

### Immediate (Phase 1)
- `scripts/entities/base_entity.gd`
- `scripts/entities/entity_data.gd`
- `scripts/state/game_state.gd`
- `scripts/state/player_state.gd`
- `scripts/persistence/state_serializer.gd`

### Future (Phase 2+)
- `scripts/network/network_interface.gd`
- `scripts/network/local_network.gd`
- `scripts/commands/command_base.gd`
- `scripts/server/server_main.gd`
- `scripts/database/database_interface.gd`

---

## Benefits of This Architecture

1. **Scalable**: Can handle thousands of players
2. **Secure**: Server validates everything
3. **Maintainable**: Clear separation of concerns
4. **Testable**: Each layer can be tested independently
5. **Flexible**: Can run local or networked
6. **Future-Proof**: Easy to add features

---

## Notes

- Current single-player game continues to work
- Can implement phases incrementally
- No breaking changes required
- All existing code can be gradually migrated

