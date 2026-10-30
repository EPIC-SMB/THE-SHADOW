# test_modules.py — Tests for Shadow Protocol new modules
# Tests RoomBuilder, EntityAI, and GameManager with stubbed Roblox API

import lupa
import os

base = "C:/Users/WINDOWS 10/Desktop/ShadowProtocol"
lua = lupa.LuaRuntime(unpack_returned_tuples=True)

# ============================================================================
# Roblox API Stubs
# ============================================================================
lua.execute('''
local Vector3MT = {}
Vector3MT.__index = Vector3MT
Vector3MT.__add = function(a, b) return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
Vector3MT.__sub = function(a, b) return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
Vector3MT.__mul = function(a, b)
	if type(b) == "number" then return Vector3.new(a.X * b, a.Y * b, a.Z * b) end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
Vector3MT.__dot = function(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
Vector3 = {}
function Vector3.new(x, y, z)
	local t = {X = x or 0, Y = y or 0, Z = z or 0}
	setmetatable(t, Vector3MT)
	local mag = math.sqrt((x or 0)^2 + (y or 0)^2 + (z or 0)^2)
	local ux, uy, uz = 0, 0, 0
	if mag > 0 then ux, uy, uz = (x or 0)/mag, (y or 0)/mag, (z or 0)/mag end
	t.Unit = { X = ux, Y = uy, Z = uz, Dot = function(self, other) return self.X * other.X + self.Y * other.Y + self.Z * other.Z end }
	t.Dot = function(self, other) return self.X * other.X + self.Y * other.Y + self.Z * other.Z end
	return t
end
Vector3.zero = Vector3.new(0,0,0)

local function setParent(self, parent)
	if self._parent and self._parent._children then
		self._parent._children[self.Name] = nil
	end
	self._parent = parent
	if parent then
		parent._children = parent._children or {}
		parent._children[self.Name] = self
	end
end

local InstanceMT = {}
InstanceMT.__index = InstanceMT
function InstanceMT:FindFirstChild(name) return self._children and self._children[name] end
function InstanceMT:FindFirstChildOfClass(className)
	if self._children then
		for _, child in pairs(self._children) do
			if child._className == className then return child end
		end
	end
	return nil
end
function InstanceMT:GetChildren()
	local t = {}
	if self._children then for _, v in pairs(self._children) do table.insert(t, v) end end
	return t
end
function InstanceMT:SetAttribute(name, value) self._attributes = self._attributes or {}; self._attributes[name] = value end
function InstanceMT:GetAttribute(name) return self._attributes and self._attributes[name] end
function InstanceMT:Destroy()
	if self._parent and self._parent._children then
		self._parent._children[self.Name] = nil
	end
	self._parent = nil
	self._destroyed = true
end

Instance = {}
function Instance.new(className, parent)
	local self = setmetatable({}, InstanceMT)
	self._className = className
	self._children = {}
	self._attributes = {}
	self.Name = className
	self._parent = nil
	self._destroyed = false
	self.Fire = function(self, ...) end
	self.Event = { Connect = function(self, fn) return { Disconnect = function() end } end }
	-- Remote event/function stubs
	if className == "RemoteEvent" then
		self.OnServerEvent = { Connect = function(self, fn) return { Disconnect = function() end } end }
		self.OnClientEvent = { Connect = function(self, fn) return { Disconnect = function() end } end }
		self.FireClient = function(self, ...) end
		self.FireAllClients = function(self, ...) end
		self.FireServer = function(self, ...) end
	elseif className == "RemoteFunction" then
		self.OnServerInvoke = nil
		self.InvokeServer = function(self, ...) return nil end
	end
	local mt = getmetatable(self)
	mt.__newindex = function(t, k, v)
		if k == "Parent" then
			setParent(t, v)
		elseif k == "PrimaryPart" then
			rawset(t, "_primaryPart", v)
		else
			rawset(t, k, v)
		end
	end
	mt.__index = function(t, k)
		local v = rawget(t, k)
		if v ~= nil then return v end
		if k == "PrimaryPart" then return t._primaryPart end
		if k == "Parent" then return t._parent end
		return InstanceMT[k]
	end
	if parent then setParent(self, parent) end
	return self
end

-- Services
local services = {}
game = {}
game.GetService = function(name)
	if not services[name] then
		local svc = { Name = name, _children = {}, _attributes = {},
			FindFirstChild = function(self, n) return self._children[n] end,
			WaitForChild = function(self, n)
				if not self._children[n] then
					-- Auto-create for testing
					local child = Instance.new(n)
					child.Name = n
					child.Parent = self
					self._children[n] = child
				end
				return self._children[n]
			end,
			GetChildren = function(self)
				local t = {}
				for _, v in pairs(self._children) do table.insert(t, v) end
				return t
			end,
			SetAttribute = function(self, n, v) self._attributes[n] = v end,
			GetAttribute = function(self, n) return self._attributes[n] end,
		}
		services[name] = svc
	end
	return services[name]
end

-- Players service
local Players = game:GetService("Players")
local playerObjects = {}
Players.GetPlayerByUserId = function(self, userId) return playerObjects[userId] end
Players.GetPlayers = function() return {} end
Players.PlayerAdded = { Connect = function(self, fn) end }
Players.PlayerRemoving = { Connect = function(self, fn) end }

-- RunService
local RunService = game:GetService("RunService")
local heartbeatHandlers = {}
RunService.Heartbeat = {
	Connect = function(self, fn)
		table.insert(heartbeatHandlers, fn)
		return { Disconnect = function() end }
	end
}

-- PathfindingService
local PathfindingService = game:GetService("PathfindingService")
PathfindingService.CreatePath = function() return {
	ComputeAsync = function() end,
	GetWaypoints = function() return {} end
} end

-- ServerStorage
local ServerStorage = game:GetService("ServerStorage")

-- ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Lighting
local Lighting = game:GetService("Lighting")

-- Workspace
local Workspace = game:GetService("Workspace")
workspace = Workspace

-- Enums
Color3 = { fromRGB = function(r,g,b) return {r=r,g=g,b=b} end }
Enum = {
	Material = { Concrete = "Concrete", SmoothPlastic = "SmoothPlastic", Wood = "Wood",
		Fabric = "Fabric", Neon = "Neon" },
	Font = { GothamBold = "GothamBold", Gotham = "Gotham" },
	FontSize = { Size9 = 9, Size11 = 11, Size14 = 14, Size18 = 18, Size20 = 20, Size28 = 28 },
	TextXAlignment = { Left = "Left" },
}

-- Roblox globals
tick = function() return os.clock() * 1000 end
spawn = function(fn, ...) if type(fn) == "function" then pcall(fn, ...) end end
wait = function(t) end
task = { delay = function(t, fn) if type(fn) == "function" then pcall(fn) end end, wait = function(t) end }
math.randomseed = math.randomseed or function() end

-- SPC config (loaded from file)
''')

# Load SPC config
lua.execute("""
require = function(obj)
	local name = nil
	if type(obj) == "string" then name = obj end
	if type(obj) == "table" then name = obj.Name or obj._className end
	if name then
		if name:find("ShadowProtocolConfig") then return SPC end
		if name:find("ShadowProtocolRoomBuilder") then return RoomBuilder end
		if name:find("ShadowProtocolEntityAI") then return EntityAI end
		if name:find("ShadowProtocolGameManager") then return GameManager end
	end
	if type(obj) == "table" and obj.Source then
		return load(obj.Source, "module", "t", _G)()
	end
	return nil
end
""")

config_code = open(os.path.join(base, "ShadowProtocolConfig.lua")).read()
lua.execute(f'SPC = load({repr(config_code)}, "config")()')

# Load RoomBuilder
rb_code = open(os.path.join(base, "ShadowProtocolRoomBuilder.lua")).read()
lua.execute(f'RoomBuilder = load({repr(rb_code)}, "RoomBuilder")()')

# Load EntityAI
ea_code = open(os.path.join(base, "ShadowProtocolEntityAI.lua")).read()
lua.execute(f'EntityAI = load({repr(ea_code)}, "EntityAI")()')

# Load GameManager (ModuleScript)
gm_code = open(os.path.join(base, "ShadowProtocolGameManager.lua")).read()
lua.execute(f'GameManager = load({repr(gm_code)}, "GameManager")()')

# ============================================================================
# TESTS
# ============================================================================
passed = 0
failed = 0

def test(name, condition):
	global passed, failed
	if condition:
		passed += 1
		print(f"  PASS: {name}")
	else:
		failed += 1
		print(f"  FAIL: {name}")

print("\n=== RoomBuilder Tests ===")

# Test 1: BuildRoom creates a room with expected children
lua.execute('''
local room = RoomBuilder.BuildRoom(1, Vector3.new(0,0,0), true, true)
local hasFloor = room:FindFirstChild("Floor") ~= nil
local hasCeiling = room:FindFirstChild("Ceiling") ~= nil
local hasHidingSpot = room:FindFirstChild("HidingSpot") ~= nil
local hasSpawnPoint = room:FindFirstChild("SpawnPoint") ~= nil
local hasLight = room:FindFirstChild("LightFixture") ~= nil
local childCount = #room:GetChildren()
-- Store results
_roomHasFloor = hasFloor
_roomHasCeiling = hasCeiling
_roomHasHidingSpot = hasHidingSpot
_roomHasSpawnPoint = hasSpawnPoint
_roomHasLight = hasLight
_roomChildCount = childCount
_roomName = room.Name
''')
test("BuildRoom creates room with Floor", lua.eval("_roomHasFloor") == True)
test("BuildRoom creates room with Ceiling", lua.eval("_roomHasCeiling") == True)
test("BuildRoom creates room with HidingSpot (hasHidingSpot=true)", lua.eval("_roomHasHidingSpot") == True)
test("BuildRoom creates room with SpawnPoint", lua.eval("_roomHasSpawnPoint") == True)
test("BuildRoom creates room with LightFixture", lua.eval("_roomHasLight") == True)
test("BuildRoom room name is Room_1", lua.eval("_roomName") == "Room_1")
test("BuildRoom has >= 10 children", lua.eval("_roomChildCount") >= 10)

# Test 2: BuildRoom without hiding spot
lua.execute('''
local room = RoomBuilder.BuildRoom(2, Vector3.new(50,0,0), false, false)
_room2HasHidingSpot = room:FindFirstChild("HidingSpot") ~= nil
_room2HasDoor = room:FindFirstChild("DoorPanel") ~= nil
''')
test("BuildRoom without hiding spot (hasHidingSpot=false)", lua.eval("_room2HasHidingSpot") == False)
test("BuildRoom without door (hasDoor=false)", lua.eval("_room2HasDoor") == False)

# Test 3: BuildFloor creates correct number of rooms
lua.execute('''
local floorModel, rooms, doors = RoomBuilder.BuildFloor(1, 5)
_floorRoomCount = #rooms
_floorDoorCount = #doors
_floorAttrRoomCount = floorModel:GetAttribute("RoomCount")
_floorAttrFloorNumber = floorModel:GetAttribute("FloorIndex")
_floorName = floorModel.Name
''')
test("BuildFloor creates 5 rooms", lua.eval("_floorRoomCount") == 5)
test("BuildFloor creates 5 doors", lua.eval("_floorDoorCount") == 5)
test("BuildFloor RoomCount attr = 5", lua.eval("_floorAttrRoomCount") == 5)
test("BuildFloor FloorIndex attr = 1", lua.eval("_floorAttrFloorNumber") == 1)
test("BuildFloor name is Floor_1", lua.eval("_floorName") == "Floor_1")

# Test 4: GetSpawnPosition
lua.execute('''
local floorModel, rooms, doors = RoomBuilder.BuildFloor(1, 3)
local pos = RoomBuilder.GetSpawnPosition(floorModel, 1)
_spawnPosX = pos.X
_spawnPosY = pos.Y
_spawnPosZ = pos.Z
''')
test("GetSpawnPosition returns valid position", lua.eval("_spawnPosY") == 3.5)

# Test 5: GetHidingSpots
lua.execute('''
local floorModel, rooms, doors = RoomBuilder.BuildFloor(1, 5)
-- Room 1 has hiding spot (every 3rd room: 3, 6, 9...)
local spots1 = RoomBuilder.GetHidingSpots(floorModel, 1)
-- Room 3 has hiding spot
local spots3 = RoomBuilder.GetHidingSpots(floorModel, 3)
_hidingSpots1 = #spots1
_hidingSpots3 = #spots3
''')
test("Room 1 has 1 hiding spot (first room)", lua.eval("_hidingSpots1") == 1)
test("Room 3 has 1 hiding spot (every 3rd)", lua.eval("_hidingSpots3") == 1)

# Test 6: BuildFloor with exit door
lua.execute('''
local floorModel, rooms, doors = RoomBuilder.BuildFloor(1, 3)
local lastDoor = doors[#doors]
_exitAttr = lastDoor:GetAttribute("IsExit")
''')
test("Last door has IsExit=true", lua.eval("_exitAttr") == True)

print("\n=== EntityAI Tests ===")

# Test 7: CreateEntityModel
lua.execute('''
local model = EntityAI.CreateEntityModel("Watcher", Vector3.new(10, 0, 10))
_entityName = model.Name
_hasBody = model:FindFirstChild("Body") ~= nil
_hasLeftEye = model:FindFirstChild("LeftEye") ~= nil
_hasRightEye = model:FindFirstChild("RightEye") ~= nil
_hasHumanoid = model:FindFirstChildOfClass("Humanoid") ~= nil
_bodyColor = model:FindFirstChild("Body").Color.r
''')
test("CreateEntityModel name is Watcher", lua.eval("_entityName") == "Watcher")
test("CreateEntityModel has Body", lua.eval("_hasBody") == True)
test("CreateEntityModel has LeftEye", lua.eval("_hasLeftEye") == True)
test("CreateEntityModel has RightEye", lua.eval("_hasRightEye") == True)
test("CreateEntityModel has Humanoid", lua.eval("_hasHumanoid") == True)

# Test 8: Spawn entity
lua.execute('''
local ws = Instance.new("Folder")
ws.Name = "Workspace"
local entityId, model = EntityAI.Spawn("Watcher", Vector3.new(5, 0, 5), ws)
_spawnedId = entityId
_spawnedModelParent = model.Parent and model.Parent.Name or "nil"
_activeCount = 0
for _ in pairs(EntityAI.ActiveEntities) do _activeCount = _activeCount + 1 end
_entityState = EntityAI.ActiveEntities[entityId].State
''')
test("Spawn returns entity ID", lua.eval("_spawnedId") is not None)
test("Spawned entity parent is Workspace", lua.eval("_spawnedModelParent") == "Workspace")
test("Spawned entity is active", lua.eval("_activeCount") == 1)
test("Spawned entity state is Patrolling", lua.eval("_entityState") == "Patrolling")

# Test 9: Despawn entity
lua.execute('''
EntityAI.DespawnAll()
local ws = Instance.new("Folder")
local entityId, model = EntityAI.Spawn("Watcher", Vector3.new(0,0,0), ws)
EntityAI.Despawn(entityId)
_afterDespawnCount = 0
for _ in pairs(EntityAI.ActiveEntities) do _afterDespawnCount = _afterDespawnCount + 1 end
''')
test("Despawn removes entity", lua.eval("_afterDespawnCount") == 0)

# Test 10: DespawnAll
lua.execute('''
local ws = Instance.new("Folder")
EntityAI.Spawn("Watcher", Vector3.new(0,0,0), ws)
EntityAI.Spawn("Watcher", Vector3.new(10,0,10), ws)
_beforeAll = 0
for _ in pairs(EntityAI.ActiveEntities) do _beforeAll = _beforeAll + 1 end
EntityAI.DespawnAll()
_afterAll = 0
for _ in pairs(EntityAI.ActiveEntities) do _afterAll = _afterAll + 1 end
''')
test("DespawnAll clears all entities", lua.eval("_afterAll") == 0)

# Test 11: GetPosition
lua.execute('''
local ws = Instance.new("Folder")
local entityId, model = EntityAI.Spawn("Watcher", Vector3.new(5, 0, 5), ws)
local pos = EntityAI.GetPosition(entityId)
_posX = pos.X
_posY = pos.Y
_posZ = pos.Z
''')
test("GetPosition returns entity position", lua.eval("_posX") == 5)

# Test 12: IsPlayerLookingAt
lua.execute('''
-- Create a mock player
local player = { Character = nil }
local char = Instance.new("Model")
char.Name = "Character"
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Position = Vector3.new(0, 0, 0)
root.Parent = char
local head = Instance.new("Part")
head.Name = "Head"
head.Position = Vector3.new(0, 5, 0)
head.CFrame = { LookVector = Vector3.new(0, 0, -1) }
head.Parent = char
player.Character = char
-- Target is in front of player
_lookingResult = EntityAI.IsPlayerLookingAt(player, Vector3.new(0, 5, -10))
''')
test("IsPlayerLookingAt detects looking", lua.eval("_lookingResult") == True)

print("\n=== GameManager Tests ===")

# Test 13: Init
lua.execute('''
GameManager.Init()
_phase = GameManager.GetPhase()
''')
test("GameManager initial phase is Lobby", lua.eval("_phase") == "Lobby")

# Test 14: initPlayer
lua.execute('''
local player = { UserId = 123, Name = "TestPlayer" }
GameManager.initPlayer(player)
_playerHealth = GameManager.GetGameState().Players[player].Health
_playerStamina = GameManager.GetGameState().Players[player].Stamina
_playerAlive = GameManager.GetGameState().Players[player].IsAlive
''')
test("initPlayer sets health to 100", lua.eval("_playerHealth") == 100)
test("initPlayer sets stamina to 100", lua.eval("_playerStamina") == 100)
test("initPlayer sets IsAlive to true", lua.eval("_playerAlive") == True)

# Test 15: damagePlayer
lua.execute('''
local player = { UserId = 456, Name = "TestPlayer2" }
GameManager.initPlayer(player)
GameManager.DamagePlayer(player, 30)
_afterDamageHealth = GameManager.GetGameState().Players[player].Health
''')
test("DamagePlayer reduces health", lua.eval("_afterDamageHealth") == 70)

# Test 16: damagePlayer with hiding
lua.execute('''
local player = { UserId = 789, Name = "TestPlayer3" }
GameManager.initPlayer(player)
GameManager.GetGameState().Players[player].IsHiding = true
GameManager.DamagePlayer(player, 50)
_afterHideDamageHealth = GameManager.GetGameState().Players[player].Health
''')
test("DamagePlayer with hiding reduces damage by 80%", lua.eval("_afterHideDamageHealth") == 90)

# Test 17: healPlayer
lua.execute('''
local player = { UserId = 101, Name = "TestPlayer4" }
GameManager.initPlayer(player)
GameManager.DamagePlayer(player, 50)
GameManager.HealPlayer(player, 20)
_afterHealHealth = GameManager.GetGameState().Players[player].Health
''')
test("HealPlayer increases health", lua.eval("_afterHealHealth") == 70)

# Test 18: cleanupPlayer
lua.execute('''
local player = { UserId = 202, Name = "TestPlayer5" }
GameManager.initPlayer(player)
GameManager.cleanupPlayer(player)
_cleanedUp = GameManager.GetGameState().Players[player] == nil
''')
test("cleanupPlayer removes player", lua.eval("_cleanedUp") == True)

# Test 19: StartRound (basic)
lua.execute('''
-- Add a player first
local player = { UserId = 303, Name = "TestPlayer6" }
GameManager.initPlayer(player)
-- Start round
GameManager.StartRound()
_roundPhase = GameManager.GetPhase()
_roundRoomCount = GameManager.GetGameState().RoomCount
_roundHasFloorModel = GameManager.GetGameState().FloorModel ~= nil
_roundDoorCount = 0
for _ in pairs(GameManager.GetGameState().Doors) do _roundDoorCount = _roundDoorCount + 1 end
''')
test("StartRound sets phase to Playing", lua.eval("_roundPhase") == "Playing")
test("StartRound sets RoomCount", lua.eval("_roundRoomCount") >= 1)
test("StartRound creates FloorModel", lua.eval("_roundHasFloorModel") == True)
test("StartRound creates doors", lua.eval("_roundDoorCount") >= 1)

# Test 20: EndRound
lua.execute('''
local _p = { UserId = 999, Name = "TestPlayer" }
GameManager.initPlayer(_p)
GameManager.GetGameState().Phase = "Playing"
GameManager.EndRound("Escape", nil)
_endPhase = GameManager.GetPhase()
''')
test("EndRound auto-restarts (phase becomes Playing)", lua.eval("_endPhase") == "Playing")

print(f"\n========================================")
print(f"Tests passed: {passed}")
print(f"Tests failed: {failed}")

print("Total: " + str(passed) + " passed, " + str(failed) + " failed")


# G1 Test: Floor progression on escape
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 1
GameManager.GetGameState().Phase = "Lobby"
GameManager.StartRound()
_g1_floor_before = GameManager.GetGameState().CurrentFloor
GameManager.EndRound("Escape", nil)
_g1_floor_after_escape = GameManager.GetGameState().CurrentFloor
""")
test("G1: Floor increments from 1 to 2 on escape", lua.eval("_g1_floor_after_escape") == 2)

# G1 Test: Floor 8 wraps to 1
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 8
GameManager.GetGameState().Phase = "Lobby"
GameManager.StartRound()
GameManager.EndRound("Escape", nil)
_g1_floor_after_last = GameManager.GetGameState().CurrentFloor
""")
test("G1: Floor 8 wraps to 1 on escape (victory reset)", lua.eval("_g1_floor_after_last") == 1)

# G1 Test: Death does not change floor
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 3
GameManager.GetGameState().Phase = "Lobby"
GameManager.StartRound()
_g1_floor_before_death = GameManager.GetGameState().CurrentFloor
GameManager.EndRound("Death", nil)
_g1_floor_after_death = GameManager.GetGameState().CurrentFloor
""")
test("G1: Death does not change current floor", lua.eval("_g1_floor_after_death") == 3)

print("Total: " + str(passed) + " passed, " + str(failed) + " failed")

# G1.1 Test: EndRound sets phase to Results (intermission starts)
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 2
GameManager.GetGameState().Phase = "Lobby"
local _p = { UserId = 999, Name = "TestPlayer" }
GameManager.initPlayer(_p)
GameManager.StartRound()
_g11_phase_before = GameManager.GetPhase()
GameManager.EndRound("Escape", nil)
_g11_phase_after_escape = GameManager.GetPhase()
_g11_floor_after = GameManager.GetGameState().CurrentFloor
""")
test("G1.1: Auto-start fires after intermission (phase becomes Playing)", lua.eval("_g11_phase_after_escape") == "Playing")
test("G1.1: Floor still increments on escape", lua.eval("_g11_floor_after") == 3)

# G1.1 Test: EndRound on death sets phase to Results
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 5
GameManager.GetGameState().Phase = "Lobby"
local _p = { UserId = 999, Name = "TestPlayer" }
GameManager.initPlayer(_p)
GameManager.StartRound()
GameManager.EndRound("Death", nil)
_g11_phase_after_death = GameManager.GetPhase()
_g11_floor_after_death = GameManager.GetGameState().CurrentFloor
""")
test("G1.1: Death auto-restarts (phase becomes Playing)", lua.eval("_g11_phase_after_death") == "Playing")
test("G1.1: Death does not change floor", lua.eval("_g11_floor_after_death") == 5)

# G1.1 Test: EndRound on TimeUp sets phase to Results
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 4
GameManager.GetGameState().Phase = "Lobby"
local _p = { UserId = 999, Name = "TestPlayer" }
GameManager.initPlayer(_p)
GameManager.StartRound()
GameManager.EndRound("TimeUp", nil)
_g11_phase_after_timeout = GameManager.GetPhase()
_g11_floor_after_timeout = GameManager.GetGameState().CurrentFloor
""")
test("G1.1: TimeUp auto-restarts (phase becomes Playing)", lua.eval("_g11_phase_after_timeout") == "Playing")
test("G1.1: TimeUp does not change floor", lua.eval("_g11_floor_after_timeout") == 4)

# G1.1 Test: Victory flow on Floor 8
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 8
GameManager.GetGameState().Phase = "Lobby"
-- Ensure no leftover players trigger auto-restart during the test
for _p in pairs(GameManager.GetGameState().Players) do GameManager.GetGameState().Players[_p] = nil end
GameManager.StartRound()
GameManager.EndRound("Escape", nil)
_g11_victory_floor = GameManager.GetGameState().CurrentFloor
_g11_victory_allcleared = GameManager.GetGameState().LastRoundAllCleared
""")
test("G1.1: Floor 8 escape resets to Floor 1", lua.eval("_g11_victory_floor") == 1)
test("G1.1: Floor 8 escape sets AllFloorsCleared flag", lua.eval("_g11_victory_allcleared") == True)

print("Total: " + str(passed) + " passed, " + str(failed) + " failed")


# G1.3 Tests: Victory flag lifecycle
print("\n=== G1.3: Victory Flag Lifecycle Tests ===")

def _clear_players():
    for _p in pairs(GameManager.GetGameState().Players):
        GameManager.GetGameState().Players[_p] = nil

# G1.3 Test 1: Victory flag true after Floor 8 escape (no auto-restart)
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 8
GameManager.GetGameState().Phase = "Lobby"
for _p in pairs(GameManager.GetGameState().Players) do GameManager.GetGameState().Players[_p] = nil end
GameManager.StartRound()
GameManager.EndRound("Escape", nil)
_g13_victory_flag_after_escape = GameManager.GetGameState().LastRoundAllCleared
""")
test("G1.3: Victory flag true after Floor 8 escape", lua.eval("_g13_victory_flag_after_escape") == True)

# G1.3 Test 2: StartRound resets the victory flag for the next round
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 8
GameManager.GetGameState().Phase = "Lobby"
for _p in pairs(GameManager.GetGameState().Players) do GameManager.GetGameState().Players[_p] = nil end
GameManager.StartRound()
GameManager.EndRound("Escape", nil)
-- Next round begins; reset via StartRound
GameManager.StartRound()
_g13_flag_after_reset = GameManager.GetGameState().LastRoundAllCleared
""")
test("G1.3: StartRound resets victory flag to false", lua.eval("_g13_flag_after_reset") == False)

# G1.3 Test 3: Death does not carry a stale victory flag
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 3
GameManager.GetGameState().Phase = "Lobby"
for _p in pairs(GameManager.GetGameState().Players) do GameManager.GetGameState().Players[_p] = nil end
GameManager.GetGameState().LastRoundAllCleared = True
GameManager.StartRound()
GameManager.EndRound("Death", nil)
_g13_death_flag = GameManager.GetGameState().LastRoundAllCleared
""")
test("G1.3: Death resets victory flag to false", lua.eval("_g13_death_flag") == False)

# G1.3 Test 4: TimeUp does not carry a stale victory flag
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 4
GameManager.GetGameState().Phase = "Lobby"
for _p in pairs(GameManager.GetGameState().Players) do GameManager.GetGameState().Players[_p] = nil end
GameManager.GetGameState().LastRoundAllCleared = True
GameManager.StartRound()
GameManager.EndRound("TimeUp", nil)
_g13_timeup_flag = GameManager.GetGameState().LastRoundAllCleared
""")
test("G1.3: TimeUp resets victory flag to false", lua.eval("_g13_timeup_flag") == False)

# G1.3 Test 5: Non-victory escape (floor < 8) clears the flag
lua.execute("""
EntityAI.DespawnAll()
GameManager.GetGameState().CurrentFloor = 2
GameManager.GetGameState().Phase = "Lobby"
for _p in pairs(GameManager.GetGameState().Players) do GameManager.GetGameState().Players[_p] = nil end
GameManager.GetGameState().LastRoundAllCleared = True
GameManager.StartRound()
GameManager.EndRound("Escape", nil)
_g13_normal_escape_flag = GameManager.GetGameState().LastRoundAllCleared
""")
test("G1.3: Normal escape (floor<8) sets victory flag false", lua.eval("_g13_normal_escape_flag") == False)

print("Total: " + str(passed) + " passed, " + str(failed) + " failed")
