# Shadow Protocol — Roblox Studio Setup Guide

## Overview

This guide walks you through setting up Shadow Protocol in Roblox Studio for the playable MVP (Floor 1: Reception).

## Prerequisites

- Roblox Studio (latest version)
- Basic familiarity with Roblox Studio interface

## Step 1: Create a New Place

1. Open Roblox Studio
2. Create a new **Baseplate** template
3. Save as "Shadow Protocol MVP"

## Step 2: Set Up Lighting

1. In the Explorer, select **Lighting**
2. Set properties:
   - `Ambient`: R=10, G=10, B=15
   - `Brightness`: 0.5
   - `ColorShift_Bottom`: R=0, G=0, B=0
   - `ColorShift_Top`: R=0, G=0, B=0
   - `OutdoorAmbient`: R=5, G=5, B=10
   - `ShadowSoftness`: 0.5
   - `Technology`: Future (or ShadowMap)
3. Add a **ColorCorrectionEffect** to Lighting:
   - `Brightness`: -0.1
   - `Contrast`: 0.2
   - `Saturation`: -0.3
   - `TintColor`: R=200, G=180, B=150

## Step 3: Add Scripts

### 3.1 Config (ModuleScript)
1. In **ReplicatedStorage**, create a `ModuleScript` named `ShadowProtocolConfig`
2. Paste contents of `ShadowProtocolConfig.lua`

### 3.2 RoomBuilder (ModuleScript)
1. In **ReplicatedStorage**, create a `ModuleScript` named `ShadowProtocolRoomBuilder`
2. Paste contents of `ShadowProtocolRoomBuilder.lua`

### 3.3 EntityAI (ModuleScript)
1. In **ReplicatedStorage**, create a `ModuleScript` named `ShadowProtocolEntityAI`
2. Paste contents of `ShadowProtocolEntityAI.lua`

### 3.4 GameManager (ModuleScript)
1. In **ReplicatedStorage**, create a `ModuleScript` named `ShadowProtocolGameManager`
2. Paste contents of `ShadowProtocolGameManager.lua`

### 3.5 Economy Server (Script)
1. In **ServerScriptService**, create a `Script` named `ShadowProtocolServer`
2. Paste contents of `ShadowProtocolServer.server.lua`

### 3.6 Game Loop (Script)
1. In **ServerScriptService**, create a `Script` named `GameLoop`
2. Paste contents of `GameLoop.server.lua`

### 3.7 Client HUD (LocalScript)
1. In **StarterPlayer > StarterPlayerScripts**, create a `LocalScript` named `ShadowProtocolClient`
2. Paste contents of `ShadowProtocolClient.client.lua`

### 3.8 Client Gameplay (LocalScript)
1. In **StarterPlayer > StarterPlayerScripts**, create a `LocalScript` named `ShadowProtocolGameplay`
2. Paste contents of `ShadowProtocolGameplay.client.lua`

### 3.8 Remote Events Folder
1. In **ReplicatedStorage**, create a `Folder` named `ShadowRemotes`
2. The server scripts will auto-create remote events inside this folder

## Step 4: Configure Game Settings

1. Go to **Home > Game Settings**
2. Under **Basic Info**:
   - Set genre to "Horror"
   - Set max players to 4 (MVP)
3. Under **Security**:
   - Enable "Studio Access to API Services" (for DataStore testing)
4. Under **Permissions**:
   - Set to "Friends" or "Everyone" for testing

## Step 5: Test the MVP

### Single-Player Test
1. Press **Play** (F5) in Studio
2. Wait 5 seconds for auto-start
3. You should spawn in Room 1
4. Walk forward, press **E** near doors to open them
5. Press **F** to toggle flashlight
6. Press **H** to hide in closets (must be near a hiding spot)
7. The Watcher entity spawns in a random room (3-9)
8. When you see the purple glow, **look away** to avoid damage
9. Reach the final door (Door 10) to escape

### Multiplayer Test
1. Go to **Test > Start Server** (or use Team Test)
2. Set number of players to 2-4
3. Start the test
4. Each player should spawn in Room 1
5. Entities are shared across all players
6. Test door opening, hiding, and flashlight sync

### Expected Behavior
- Player spawns with 100 health, 100 stamina
- Flashlight toggles with F key, drains battery
- Hiding in closets reduces entity damage by 80%
- Opening doors progresses through rooms
- Reaching the exit door triggers escape
- Death occurs when health reaches 0
- Daily rewards, achievements, and economy work as configured

## Step 6: Monetization Setup (Optional)

1. Go to [Creator Dashboard](https://create.roblox.com)
2. Create Game Passes and Developer Products
3. Copy the IDs into `ShadowProtocolConfig.lua`
4. Replace all `0` placeholder IDs with real ones
5. **Do NOT enable paid random items** until PolicyService is properly configured

## Troubleshooting

### "Module not found" errors
- Ensure all ModuleScripts are in ReplicatedStorage
- Check script names match exactly (case-sensitive)

### Entity not spawning
- Check Output window for errors
- Ensure RoomBuilder module loaded successfully
- Verify entity spawn room is within range

### Doors not opening
- Check that DoorInteractRemote exists in ShadowRemotes folder
- Verify player is within 10 studs of door
- Check Output for "Too far" messages

### Flashlight not working
- Ensure ShadowProtocolGameplay client script is running
- Check that character has RightHand or Right Arm
- Verify FlashlightRemote exists

### DataStore errors
- Enable "Studio Access to API Services" in Game Settings
- Check that you're not in a local test (use Play Solo or Server test)

## File Checklist

- [ ] `ShadowProtocolConfig.lua` → ReplicatedStorage (ModuleScript)
- [ ] `ShadowProtocolRoomBuilder.lua` → ReplicatedStorage (ModuleScript)
- [ ] `ShadowProtocolEntityAI.lua` → ReplicatedStorage (ModuleScript)
- [ ] `ShadowProtocolGameManager.lua` → ReplicatedStorage (ModuleScript)
- [ ] `ShadowProtocolServer.server.lua` → ServerScriptService (Script)
- [ ] `GameLoop.server.lua` → ServerScriptService (Script)
- [ ] `ShadowProtocolClient.client.lua` → StarterPlayerScripts (LocalScript)
- [ ] `ShadowProtocolGameplay.client.lua` → StarterPlayerScripts (LocalScript)
- [ ] `ShadowRemotes` folder → ReplicatedStorage (Folder)

## Architecture Notes

### Server Authority
- All game state (health, position, entity AI) is server-authoritative
- Client only sends intents (open door, toggle flashlight, hide)
- Server validates all actions before applying

### Entity AI
- The Watcher uses simple pathfinding (MoveTo) for MVP
- Detection range: 30 studs
- Damage range: 5 studs
- Looking at entity for 2+ seconds = damage
- Purple glow is the visual tell

### Room Generation
- Linear floor layout (Room 1 → Room N)
- Every 3rd room has a hiding spot
- Alternating lights for atmosphere
- Corridors connect rooms
- Exit door at the end

### Security
- Rate limiting: 10 actions per second per action type per player
- Input validation: type checking on all remote parameters
- Distance validation: door interaction requires proximity
- Hiding spot validation: must be near a valid hiding spot
- DataStore: retry logic (3 attempts) + session locking
- No client-intent reward remotes (FloorCleared, EntityEncounter removed from client)
- Rewards granted server-side only via BindableEvents

### Economy Integration
- GameManager fires BindableEvents to ServerStorage
- Server.server.lua listens and grants rewards
- Floor clear: shards, XP, rep, achievements
- Entity encounter: shards, XP, variable drops
- All rewards are server-verified (no client spoofing)