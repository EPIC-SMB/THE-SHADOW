# Shadow Protocol — Security & Bug Audit Report

## Date: October 30, 2026

## Scope
Full codebase audit focusing on **Gameplay**, **Payment Pipeline**, and **Security**.

Files audited:
- ShadowProtocolConfig.lua (379 lines)
- ShadowProtocolRoomBuilder.lua (400 lines)
- ShadowProtocolEntityAI.lua (316 lines)
- ShadowProtocolGameManager.lua (491 lines)
- ShadowProtocolServer.server.lua (862 lines)
- ShadowProtocolClient.client.lua (651 lines)
- ShadowProtocolGameplay.client.lua (246 lines)
- GameLoop.server.lua (39 lines)

---

## 1. CRITICAL BUGS (Must Fix Before Release)

### Gameplay

| # | Issue | Location | Impact | Fix |
|---|-------|----------|--------|-----|
| G1 | No floor progression — CurrentFloor never increments after escape. Players repeat Floor 1 forever. | GameManager:EndRound | Game unplayable beyond Floor 1 | Increment CurrentFloor on escape, cap at 8 |
| G2 | No "all players dead" check — If all players die, round continues until time runs out. | GameManager:heartbeat | Wasted resources, poor UX | Check all dead → EndRound("Death") |
| G3 | Stamina uses WalkSpeed as sprint indicator — isSprinting = WalkSpeed > 16. Default is 16, so sprinting never triggers. | GameManager:updateStamina | Stamina never drains | Add sprint input handling on client, send to server |
| G4 | Entity walks through walls/doors — CanCollide = false on all entity parts. | EntityAI:CreateEntityModel | Entity ignores level design | Set CanCollide=true, use PathfindingService |
| G5 | Entity damage uses magic number — DamageRange * 20 = 100 instead of config Damage. | EntityAI:StartAI | Incorrect damage if config changes | Use SPC.Entities.Watcher.Damage |
| G6 | Client health not updated by EntityDamageRemote — Handler only prints. | ShadowProtocolClient | No damage feedback | Update healthLabel on EntityDamage |
| G7 | Door sequential validation missing — Can open Door 10 without opening 1-9. | GameManager:DoorInteractRemote | Progression bypass | Validate doorIndex == CurrentRoom + 1 |
| G8 | HeartbeatConnection never disconnected — Accumulates across rounds. | GameManager:StartRound | Performance degradation | Disconnect on EndRound |
| G9 | BuyShardItem doesn't check duplicate ownership — Can buy same item twice. | Server:BuyShardItem | Wasted currency | Check ownership before purchase |

### Payment Pipeline

| # | Issue | Location | Impact | Fix |
|---|-------|----------|--------|-----|
| P1 | MysteryCrate doesn't check PolicyService — grantProduct doesn't verify PaidRandomAllowed. | Server:grantProduct | Policy violation | Check PaidRandomAllowed before granting |
| P2 | grantPass doesn't check PolicyService — Same issue for passes. | Server:grantPass | Policy violation | Check PaidRandomAllowed |
| P3 | ProcessReceipt returns PurchaseGranted for unknown products — Silently acknowledges. | Server:processReceipt | Lost purchases | Return NotProcessedYet for unknown |
| P4 | saveProfile uses deprecated wait() — Should use task.wait(). | Server:saveProfile | Deprecated API | Replace wait() with task.wait() |
| P5 | grantProduct returns false but receipt acknowledged — Edge case. | Server:processReceipt | Potential double-grant | Already handled (receipt not recorded) |

### Security

| # | Issue | Location | Impact | Fix |
|---|-------|----------|--------|-----|
| S1 | No anti-exploit for teleportation — Server doesn't validate positions. | GameManager | Complete game bypass | Add position validation (max speed check) |
| S2 | No speed hack detection — Server doesn't validate movement speed. | GameManager | Unfair advantage | Validate WalkSpeed <= 16 + tolerance |
| S3 | EntityAI.DamageCallback set at module load — Fragile dependency. | EntityAI:DamageCallback | Fallback bypasses hiding | Set callback in GameManager.Init() |
| S4 | Door interaction race condition — Two players can simultaneously pass "already open" check. | GameManager:DoorInteractRemote | State corruption | Add per-door lock |
| S5 | setupRemotes uses deprecated spawn/wait — Should use task.delay. | Server:setupRemotes | Deprecated API | Replace with task.delay |
| S6 | CoilBoost typo in boost cleanup — Should be CoinBoost. Never cleaned up. | Server:Heartbeat | CoinBoost persists indefinitely | Fix typo |
| S7 | floorTimers table is dead code — Never used. | Server | Code clutter | Remove |
| S8 | Client flashlight claim with 0 battery — 1-frame exploit window. | Gameplay client | Minor flicker exploit | Server already turns off at 0 |
| S9 | Entity walks through walls — CanCollide=false. | EntityAI:CreateEntityModel | Ignores level geometry | Set CanCollide=true |
| S10 | QuickChat broadcasts to all players — Privacy issue. | Server:QuickChat | Information leakage | Scope to proximity (50 studs) |

---

## 2. MODERATE ISSUES

| # | Issue | Location | Fix |
|---|-------|----------|-----|
| M1 | EntityAI.StartAI creates Heartbeat connection per entity — potential leak. | EntityAI:StartAI | Track connections |
| M2 | No maximum entity count. | GameManager:StartRound | Cap at 1 (done) |
| M3 | math.random without seed — same layouts. | RoomBuilder:BuildFloor | math.randomseed(os.time()) |
| M4 | No ProfileLoaded handling in Gameplay client. | Gameplay client | Add listener |
| M5 | EntitySpawnRemote fires before players spawn — race condition. | GameManager:StartRound | Spawn players first |
| M6 | No spectator mode on death — dead players can move. | GameManager:damagePlayer | Set WalkSpeed=0 |
| M7 | awardFloorClear uses CurrentFloor for both floorIndex and difficulty. | GameManager:EndRound | Pass difficulty from SPC.Floors |
| M8 | No StatsUpdate after entity encounter. | Server:onEntityEncounter | Fire StatsUpdate |
| M9 | Client-side stamina not synced with server. | Gameplay client | Send sprint state |
| M10 | EntityDamageRemote handler only prints — no visual feedback. | ShadowProtocolClient | Add screen flash |
| M11 | Rate limiter uses deprecated tick(). | Both checkRateLimit | Use os.clock() |
| M12 | Entity doesn't respect doors — passes through closed doors. | EntityAI:MoveToTarget | Door-aware pathfinding |

---

## 3. MINOR ISSUES

| # | Issue | Location |
|---|-------|----------|
| L1 | FloorCleared remote dead code in client (listeners exist but server no longer fires as client-intent). | ShadowProtocolClient |
| L2 | EntityEncounter remote dead code in client. | ShadowProtocolClient |
| L3 | Store overlay close-on-outside-click bug. | ShadowProtocolClient |
| L4 | Enum.FontSize deprecated (still works). | Multiple client files |
| L5 | Social proof banner shows hardcoded fake numbers. | ShadowProtocolClient |
| L6 | FOMO banner shows hardcoded dates. | ShadowProtocolClient |
| L7 | EntityAI.Config only has Watcher config. | EntityAI:Config |
| L8 | No Magnitude method on Vector3 in test stubs (not relevant for Roblox). | test_modules.py |
| L9 | RoomBuilder.BuildRoom creates 6 walls but uses 4. | RoomBuilder:BuildRoom |
| L10 | No task library usage (uses deprecated spawn, wait, delay). | Multiple files |

---

## 4. ALREADY FIXED (From Previous Audit)

| Issue | Status |
|-------|--------|
| ProcessReceipt idempotency (PurchaseId tracking) | Fixed |
| PolicyService integration (age/region filtering) | Fixed |
| DataStore retry logic (3 attempts, exponential backoff) | Fixed |
| Session locking on loadProfile | Fixed |
| Server-authoritative rewards (no client-intent remotes) | Fixed |
| Rate limiting on all remotes | Fixed |
| Input validation on all remote parameters | Fixed |
| Hiding spot proximity validation | Fixed |
| Entity damage routes through GameManager | Fixed |
| GameManager converted from Script to ModuleScript | Fixed |

---

## 5. RECOMMENDED FIX PRIORITY

### Phase 1 (Before any testing)
1. Fix G1 (floor progression)
2. Fix G4 (entity walks through walls)
3. Fix G7 (door sequential validation)
4. Fix S6 (CoinBoost typo)
5. Fix P1/P2 (PolicyService checks)

### Phase 2 (Before release)
6. Fix G2 (all players dead)
7. Fix G3 (sprint input)
8. Fix G5 (entity damage config)
9. Fix G6 (client health display)
10. Fix G8 (heartbeat disconnect)
11. Fix G9 (duplicate purchase)
12. Fix S1/S2 (anti-exploit)
13. Fix S3 (DamageCallback dependency)
14. Fix S4 (door race condition)
15. Fix S5 (deprecated spawn/wait)
16. Fix S9 (entity CanCollide)
17. Fix S10 (QuickChat proximity)
18. Fix P3 (unknown product)
19. Fix P4 (task.wait)

### Phase 3 (Polish)
20. Fix M1-M12
21. Fix L1-L10

---

## 6. TEST COVERAGE

- verify.py: 40 tests (economy, receipts, daily rewards, achievements, config)
- test_modules.py: 44 tests (RoomBuilder, EntityAI, GameManager)
- Total: 84 tests, 0 failures

### Missing Test Coverage
- Multiplayer entity sync (no automated test)
- Floor progression (not implemented yet)
- Anti-exploit validation (no test)
- PolicyService enforcement (mocked only)
- DataStore failure recovery (mocked only)
- Roblox runtime behavior (requires Studio playtest)
