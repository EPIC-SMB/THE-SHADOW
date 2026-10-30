# Shadow Protocol — Project Audit Report

## Date: October 29, 2026

---

## 1. What Is Genuinely Implemented

### Server-Side (ShadowProtocolServer.server.lua)
- ✅ **Economy system**: Shard currency, XP, Rep (level), rep tiers with gear unlocks
- ✅ **Developer product receipt processing**: ProcessReceipt with idempotency (PurchaseId tracking)
- ✅ **Game pass ownership checking**: UserOwnsGamePassAsync on join
- ✅ **PolicyService integration**: Age/region filtering for paid random items
- ✅ **Player data persistence**: DataStore save/load with forward-fill for new fields
- ✅ **Daily reward system**: Streak tracking, 7-day cycle, milestone bonuses
- ✅ **Achievement system**: 6 achievements with reward grants
- ✅ **Free gear granting**: On join and on rep tier-up
- ✅ **Multiplier system**: VIP pass, boost products, streak bonus, lucky charm
- ✅ **Remote event handlers**: FloorCleared, EntityEncounter, BuyShardItem, QuickChat, ClaimDaily
- ✅ **Shard shop**: Free currency sink with 8 items

### Client-Side (ShadowProtocolClient.client.lua)
- ✅ **HUD**: Shards, Rep/XP, Floor/Door counter, streak display
- ✅ **Progress bar**: Zeigarnik completion tension
- ✅ **Store overlay**: Shard shop + Robux shop with odds disclosure
- ✅ **Quick chat wheel**: 16 fixed phrases, Q key toggle
- ✅ **Psychology popups**: Daily reward, near-miss, bonus reward, achievement unlock
- ✅ **FOMO banner**: Limited-time items display
- ✅ **Social proof banner**: Player counts
- ✅ **Tab/P/Esc keyboard shortcuts**

### Configuration (ShadowProtocolConfig.lua)
- ✅ **8 entity definitions** with tells, actions, damage, spawn chances
- ✅ **8 floor definitions** with themes, difficulty, room counts
- ✅ **Monetization config**: 3 passes, 9 products, prices, IDs
- ✅ **Loot tables**: Mystery crate with disclosed odds (sums to 100)
- ✅ **Psychology hooks**: Daily rewards, variable rewards, near-miss messages, achievements
- ✅ **Validation functions**: Gear sources, loot tables, monetization

### Testing (verify.py)
- ✅ **40 automated tests** covering economy, receipts, daily rewards, achievements, entities, config validation

---

## 2. What Is Only Described/Configured (NOT Implemented)

| Feature | Status | Location |
|---------|--------|----------|
| Entity AI behavior | Config only | SPC.Entities defines tells/damage but no AI code |
| Room generation | Config only | SPC.Floors defines room counts but no generation code |
| Round/floor timer | Config only | SPC.Round.TimeLimitPerFloor defined but no timer |
| Survival mechanics | Not implemented | No hiding, crouching, or flashlight code |
| Health/stamina system | Not implemented | No health or stamina tracking |
| Win/lose conditions | Not implemented | No escape or death handling |
| Game loop (lobby→play→results) | Not implemented | No round state machine |
| Multiplayer entity sync | Not implemented | No shared entity state |
| Leaderboards | Config only | SPC.Psychology.SocialProof defined but no implementation |
| Night vision pass effect | Config only | No visual effect code |
| Cosmetic application | Config only | Gear owned but never equipped visually |
| Collection achievement tracking | Partial | collector_5 checks owned items but no UI |

---

## 3. Existing Bugs and Security Vulnerabilities

### Security Issues
1. **No server-side validation of client intents**: `FloorCleared` remote can be spoofed to grant rewards without playing
2. **No rate limiting**: Remotes can be spammed
3. **No input validation on BuyShardItem**: Client could request items with insufficient shards (server does check, but no logging/alerting)
4. **Entity encounter rewards on client claim**: `EntityEncounter` remote grants rewards based on client report; no server verification
5. **No anti-exploit**: Speed hacks, teleportation not detected
6. **DataStore race conditions**: No session locking; concurrent saves can lose data
7. **No retry logic on DataStore failures**: Single pcall, data lost on failure
8. **Quick chat broadcasts to all players**: Should be proximity-based

### Architectural Issues
1. **No separation of concerns**: Game logic, economy, and UI all in 3 files
2. **No module system for shared logic**: Config is the only ModuleScript
3. **No state machine for round flow**: Round state is implicit
4. **Client trusts server data**: No client-side prediction or reconciliation
5. **No error recovery**: Failed DataStore operations silently fail

### Bugs
1. `spawn()` and `tick()` are Roblox globals (work in real Roblox, break in test stubs)
2. `checkAchievements` was called before definition (fixed with forward declaration)
3. `saveProfile`/`loadProfile` were called before definition (fixed with forward declaration)
4. `Players:GetPlayerByUserId` stub needed self parameter (fixed)
5. Client UI uses deprecated `Enum.FontSize` (should use `Enum.FontSize` size values)
6. Store overlay close-on-outside-click has a bug (`shopOverlay.MouseButton1Click` conflicts with inner clicks)

---

## 4. What Is Missing for a Playable Experience

### Critical (Must Have)
- [ ] 3D environment (rooms, corridors, doors, hiding spots)
- [ ] Entity spawning and AI (pathfinding, detection, chase)
- [ ] Door interaction system
- [ ] Hiding mechanic
- [ ] Health/stamina system
- [ ] Win condition (reach final door)
- [ ] Lose condition (entity catches player)
- [ ] Game loop (lobby → play → results → lobby)
- [ ] Player spawning system
- [ ] Server-authoritative movement validation

### Important (Should Have)
- [ ] Flashlight mechanic
- [ ] Audio cues (entity sounds, ambient)
- [ ] Lighting (darkness, flickering)
- [ ] Multiplayer entity sync
- [ ] Round timer
- [ ] Respawn system
- [ ] Spectator mode

### Nice to Have
- [ ] Multiple entity types
- [ ] Procedural room generation
- [ ] Cosmetic application
- [ ] Leaderboards
- [ ] Daily challenges

---

## 5. Recommended Architecture for Playable MVP

```
Server:
├── GameManager (round state, player management, win/lose)
├── EntityAI (spawn, pathfinding, detection, damage)
├── RoomBuilder (procedural room generation)
├── Economy (existing, needs validation)
└── DataStore (existing, needs retry + session locking)

Client:
├── GameplayController (input, camera, flashlight)
├── HUD (existing, needs health/stamina)
├── EntityWarningUI (visual/audio cues)
└── Store (existing)

Shared:
├── Config (existing)
└── Remote definitions (new)
```

---

## 6. Implementation Priority

1. **Server game loop** — round state machine, player spawning
2. **Room builder** — procedural generation of one floor
3. **Entity AI** — one entity type (The Watcher) with detection + damage
4. **Client gameplay** — flashlight, hiding, door interaction
5. **Health/stamina** — damage, regeneration, death
6. **Win/lose** — escape condition, death handling
7. **Multiplayer** — shared state, player sync
8. **Security** — remote validation, rate limiting, anti-exploit

---

## 7. Test Strategy

- **Unit tests**: Economy, receipts, config validation (existing 40 tests)
- **Integration tests**: Round flow, entity encounters, reward granting
- **Studio playtests**: Multiplayer, performance, feel
- **Security tests**: Remote spoofing, speed hacks, data manipulation

Mocked tests (verify.py) validate logic but NOT Roblox runtime behavior. Studio playtests are required for final validation.