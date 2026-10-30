# Shadow Protocol — Roblox Horror Survival Game

A horror survival game inspired by top-trending Roblox games (DOORS, DONT SPLASH, The Hollow). Players navigate through a dark, abandoned research facility, avoiding entities with unique behaviors, solving puzzles, and reaching the final floor to escape.

## Features

### Gameplay
- **8 Floors** with increasing difficulty (Reception → The Core)
- **8 Entity Types**: The Watcher, Rush, Ambush, The Figure, The Seeker, Screech, The Void, The Mimic
- **Procedural rooms** with random generation for replayability
- **Quick chat wheel** (no free-text chat — satisfies Roblox chat guidelines)
- **Achievement system** with 6 achievements

### Psychology-Driven Engagement
- **Variable ratio rewards** (Skinner box) — unpredictable loot drops create dopamine anticipation
- **Zeigarnik effect** — progress bars and "X doors remaining" create cognitive tension
- **Loss aversion** — near-miss messages ("You were only 3 doors away!")
- **FOMO** — limited-time seasonal cosmetics with truthful availability dates
- **Commitment/consistency** — daily login streaks with escalating rewards
- **Sunk cost bias** — investment in progression and cosmetic collection
- **Endowment effect** — ownership of items and stats
- **Social proof** — "X players escaped today" banner
- **Dopamine anticipation** — variable rewards keep engagement high

### Robux Monetization (Roblox-Compliant)
- **3 Game Passes**: Shadow Survivor (299 Robux), Skip Queue (99 Robux), Night Vision (149 Robux)
- **9 Developer Products**: Revive Token, Entity Repellent, Lucky Charm, Speed Surge, Battery Pack, Mystery Crate, XP Boost, Coin Boost, Daily Booster
- **Free currency (Shards)** earnable by playing, spendable on cosmetics
- **PolicyService integration** for age/region compliance
- **Odds disclosure** for paid random items (Mystery Crate)
- **No pay-to-win** — paid items are cosmetics/convenience only

## File Structure

```
ShadowProtocol/
├── ShadowProtocolConfig.lua          -- ModuleScript (ReplicatedStorage)
├── ShadowProtocolServer.server.lua   -- Script (ServerScriptService)
├── ShadowProtocolClient.client.lua   -- LocalScript (StarterPlayerScripts)
├── verify.py                         -- Verification harness
├── _test_harness.lua                 -- Generated Lua test (auto-generated)
└── README.md                         -- This file
```

## Setup in Roblox Studio

1. Open Roblox Studio and create a new place (or use an existing one)
2. In **ReplicatedStorage**, create a `ModuleScript` named `ShadowProtocolConfig` and paste the contents of `ShadowProtocolConfig.lua`
3. In **ServerScriptService**, create a `Script` named `ShadowProtocolServer` and paste the contents of `ShadowProtocolServer.server.lua`
4. In **StarterPlayer > StarterPlayerScripts**, create a `LocalScript` named `ShadowProtocolClient` and paste the contents of `ShadowProtocolClient.client.lua`
5. In **ReplicatedStorage**, create a `Folder` named `ShadowRemotes` (the server will auto-create remote events)
6. Set up your **Game Passes** and **Developer Products** in the Creator Dashboard
7. Replace the `0` placeholder IDs in `ShadowProtocolConfig.lua` with your real IDs
8. Test in Studio, then publish

## Roblox Creator Guidelines Compliance

- ✅ No free-text chat (quick chat wheel with fixed phrases only)
- ✅ No UGC uploads (no moderation surface)
- ✅ No pay-to-win (paid items are cosmetics/convenience)
- ✅ PolicyService integrated for age/region filtering
- ✅ Paid random items (Mystery Crate) have disclosed odds
- ✅ No misleading claims about scarcity or timers
- ✅ All content appropriate for Moderate maturity rating
- ✅ Transparent, honest monetization presentation

## Verification

Set up a Python environment once:

```bash
python -m venv .venv
# Windows:
.venv\Scriptsctivate
# macOS/Linux:
# source .venv/bin/activate
pip install -r requirements.txt
```

Then run the test suites:

```bash
python verify.py
python test_modules.py
```

This stubs the Roblox API and tests:
- ProcessReceipt grants correct amounts
- Receipt idempotency (no double-grants)
- Non-Open statuses acknowledged without grants
- Unknown products rejected
- Pass multipliers boost earnings
- Free loop (rep tiers grant free gear)
- Free gear granted on join
- Offline player receipt deferral
- Active boosts change grant amounts
- Daily reward system
- Achievement system
- Entity encounter rewards
- Lucky charm doubles rewards
- Near-miss logic
- Mystery crate grants items
- Streak bonus multipliers
- Configuration validation

## Psychology References

Based on research into gaming monetization psychology:
- Variable ratio reinforcement (Skinner, 1938)
- Zeigarnik effect (1927) — incomplete tasks create cognitive tension
- Loss aversion (Kahneman & Tversky, 1979)
- Fear of missing out (FoMO) in time-limited systems
- Sunk cost bias in continued investment
- Endowment effect in ownership valuation
- Near-miss effects in engagement
- Social comparison and competition
- Dopamine anticipation in reward prediction (Schultz)
