-- ShadowProtocolGameManager.lua — ModuleScript (ReplicatedStorage)
-- Main game loop for Shadow Protocol.
-- Manages round state, player spawning, entity spawning, win/lose conditions.
-- Server-authoritative: all game state and decisions are server-side.
-- This is a ModuleScript — call GameManager.Init() to set up, then
-- GameManager.StartRound() to begin play.

local GameManager = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- Load modules
local RoomBuilder = require(ReplicatedStorage:WaitForChild("ShadowProtocolRoomBuilder"))
local EntityAI = require(ReplicatedStorage:WaitForChild("ShadowProtocolEntityAI"))
local SPC = require(ReplicatedStorage:WaitForChild("ShadowProtocolConfig"))

-- ============================================================================
-- Game State
-- ============================================================================
local GameState = {
	Phase = "Lobby",       -- Lobby, Playing, Results
	CurrentFloor = 1,
	RoomCount = 10,
	CurrentRoom = 0,
	StartTime = 0,
	TimeLimit = 600,
	Players = {},
	Entities = {},
	FloorModel = nil,
	Doors = {},
	Rooms = {},
	HeartbeatConnection = nil,
	LastRoundAllCleared = false,
}

-- ============================================================================
-- Rate Limiting (security)
-- ============================================================================
local rateLimits = {}  -- [player] = { [action] = { lastTime, count } }
local RATE_LIMIT_WINDOW = 1  -- seconds
local RATE_LIMIT_MAX = 10    -- max actions per window

local function checkRateLimit(player, action)
	rateLimits[player] = rateLimits[player] or {}
	local rl = rateLimits[player][action]
	local now = tick()
	if not rl or now - rl.lastTime > RATE_LIMIT_WINDOW then
		rateLimits[player][action] = { lastTime = now, count = 1 }
		return true
	end
	if rl.count >= RATE_LIMIT_MAX then
		return false
	end
	rl.count = rl.count + 1
	return true
end

-- ============================================================================
-- Bindable Events (communication with economy Server script)
-- ============================================================================
local ServerStorage = game:GetService("ServerStorage")
local floorClearedBindable = ServerStorage:FindFirstChild("FloorClearedServer")
if not floorClearedBindable then
	floorClearedBindable = Instance.new("BindableEvent")
	floorClearedBindable.Name = "FloorClearedServer"
	floorClearedBindable.Parent = ServerStorage
end

local entityEncounterBindable = ServerStorage:FindFirstChild("EntityEncounterServer")
if not entityEncounterBindable then
	entityEncounterBindable = Instance.new("BindableEvent")
	entityEncounterBindable.Name = "EntityEncounterServer"
	entityEncounterBindable.Parent = ServerStorage
end

-- ============================================================================
-- Remote Events
-- ============================================================================
local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "ShadowRemotes"
	remotes.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name, className)
	local existing = remotes:FindFirstChild(name)
	if existing then return existing end
	local remote = Instance.new(className or "RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local GameStartRemote = getOrCreateRemote("GameStart", "RemoteEvent")
local GameEndRemote = getOrCreateRemote("GameEnd", "RemoteEvent")
local RoomUpdateRemote = getOrCreateRemote("RoomUpdate", "RemoteEvent")
local HealthUpdateRemote = getOrCreateRemote("HealthUpdate", "RemoteEvent")
local EntitySpawnRemote = getOrCreateRemote("EntitySpawn", "RemoteEvent")
local EntityDamageRemote = getOrCreateRemote("EntityDamage", "RemoteEvent")
local DoorInteractRemote = getOrCreateRemote("DoorInteract", "RemoteFunction")
local HideRemote = getOrCreateRemote("Hide", "RemoteEvent")
local FlashlightRemote = getOrCreateRemote("Flashlight", "RemoteEvent")

-- ============================================================================
-- Player Management
-- ============================================================================
local function initPlayer(player)
	GameState.Players[player] = {
		Health = 100,
		MaxHealth = 100,
		Stamina = 100,
		MaxStamina = 100,
		CurrentRoom = 0,
		IsHiding = false,
		IsAlive = true,
		FlashlightOn = false,
		FlashlightBattery = 100,
	}
end

local function cleanupPlayer(player)
	GameState.Players[player] = nil
	rateLimits[player] = nil
end

-- ============================================================================
-- Health System
-- ============================================================================
local function damagePlayer(player, amount)
	local data = GameState.Players[player]
	if not data or not data.IsAlive then return end
	if data.IsHiding then
		amount = amount * 0.2
	end

	data.Health = math.max(0, data.Health - amount)
	HealthUpdateRemote:FireClient(player, data.Health, data.MaxHealth)

	if data.Health <= 0 then
		data.IsAlive = false
		GameEndRemote:FireClient(player, "Death", {
			Room = data.CurrentRoom,
			Floor = GameState.CurrentFloor,
		})
		-- Notify economy system of entity encounter (death)
		entityEncounterBindable:Fire(player, "Watcher", false)
	end
end

EntityAI.DamageCallback = damagePlayer

local function healPlayer(player, amount)
	local data = GameState.Players[player]
	if not data or not data.IsAlive then return end
	data.Health = math.min(data.MaxHealth, data.Health + amount)
	HealthUpdateRemote:FireClient(player, data.Health, data.MaxHealth)
end

-- ============================================================================
-- Stamina System
-- ============================================================================
local function updateStamina(player, dt)
	local data = GameState.Players[player]
	if not data or not data.IsAlive then return end

	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local isSprinting = humanoid.WalkSpeed > 16
	if isSprinting and data.Stamina > 0 then
		data.Stamina = math.max(0, data.Stamina - 20 * dt)
	elseif not isSprinting then
		data.Stamina = math.min(data.MaxStamina, data.Stamina + 10 * dt)
	end

	if data.Stamina <= 0 then
		humanoid.WalkSpeed = 8
	else
		humanoid.WalkSpeed = 16
	end
end

-- ============================================================================
-- Round Management
-- ============================================================================
function GameManager.StartRound()
	GameState.Phase = "Playing"
	GameState.CurrentRoom = 0
	GameState.StartTime = tick()
	GameState.TimeLimit = 600
	GameState.LastRoundAllCleared = false

	EntityAI.DespawnAll()
	if GameState.FloorModel then
		GameState.FloorModel:Destroy()
	end

	local roomCount = SPC.Floors[GameState.CurrentFloor].Rooms or 10
	GameState.RoomCount = math.min(roomCount, 10)

	GameState.FloorModel, GameState.Rooms, GameState.Doors = RoomBuilder.BuildFloor(
		GameState.CurrentFloor,
		GameState.RoomCount
	)
	GameState.FloorModel.Parent = workspace

	-- Spawn entity
	local spawnRoom = math.random(3, GameState.RoomCount - 1)
	local spawnPos = RoomBuilder.GetSpawnPosition(GameState.FloorModel, spawnRoom)
	local entityId, entityModel = EntityAI.Spawn("Watcher", spawnPos, GameState.FloorModel)
	table.insert(GameState.Entities, entityId)

	EntitySpawnRemote:FireAllClients("Watcher", spawnRoom)

	-- Spawn players at room 1
	for player, data in pairs(GameState.Players) do
		data.IsAlive = true
		data.Health = 100
		data.Stamina = 100
		data.CurrentRoom = 0
		data.IsHiding = false
		data.FlashlightOn = false
		data.FlashlightBattery = 100

		local spawnPos = RoomBuilder.GetSpawnPosition(GameState.FloorModel, 1)
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = CFrame.new(spawnPos)
			end
		end
	end

	GameStartRemote:FireAllClients(GameState.CurrentFloor, GameState.RoomCount)

	-- Start heartbeat loop if not running
	if not GameState.HeartbeatConnection then
		GameState.HeartbeatConnection = RunService.Heartbeat:Connect(function(dt)
			if GameState.Phase ~= "Playing" then return end

			local elapsed = tick() - GameState.StartTime
			if elapsed >= GameState.TimeLimit then
				GameManager.EndRound("TimeUp", nil)
				return
			end

			for player, data in pairs(GameState.Players) do
				if data.IsAlive then
					updateStamina(player, dt)

					if data.FlashlightOn then
						data.FlashlightBattery = math.max(0, data.FlashlightBattery - 2 * dt)
						if data.FlashlightBattery <= 0 then
							data.FlashlightOn = false
							FlashlightRemote:FireClient(player, false)
						end
					else
						data.FlashlightBattery = math.min(100, data.FlashlightBattery + 0.5 * dt)
					end
				end
			end
		end)
	end
end

function GameManager.EndRound(reason, winner)
	GameState.Phase = "Results"

	EntityAI.DespawnAll()
	GameState.Entities = {}

	if reason == "Escape" then
		for player, data in pairs(GameState.Players) do
			if data.IsAlive then
				-- Award floor clear via economy system (server-side, not client-reported)
				local timeTaken = tick() - GameState.StartTime
				local damageTaken = 100 - data.Health
				floorClearedBindable:Fire(player, GameState.CurrentFloor, GameState.CurrentFloor, timeTaken, damageTaken)
				-- Entity encounter survived
				entityEncounterBindable:Fire(player, "Watcher", true)
			end
		end

		-- G1 FIX: Progress to next floor on escape
		local wasLastFloor = (GameState.CurrentFloor >= 8)
		if GameState.CurrentFloor < 8 then
			GameState.CurrentFloor = GameState.CurrentFloor + 1
		else
			-- All 8 floors cleared — victory! Reset for replay
			GameState.CurrentFloor = 1
		end

		-- Store victory flag for GameEndRemote
		GameState.LastRoundAllCleared = wasLastFloor
	end

	-- On death, do NOT reset CurrentFloor (player retries same floor)
	-- On time up, do NOT reset CurrentFloor (player retries same floor)

	GameEndRemote:FireAllClients(reason, {
		Floor = GameState.CurrentFloor,
		Room = GameState.CurrentRoom,
		Time = tick() - GameState.StartTime,
		AllFloorsCleared = GameState.LastRoundAllCleared or false,
	})

	task.delay(10, function()
		GameState.Phase = "Lobby"
	end)
end

-- ============================================================================
-- Door Interaction
-- ============================================================================
DoorInteractRemote.OnServerInvoke = function(player, doorIndex)
	-- Rate limit
	if not checkRateLimit(player, "DoorInteract") then
		return false, "Rate limited"
	end

	-- Validate input
	if type(doorIndex) ~= "number" then
		return false, "Invalid door index"
	end
	doorIndex = math.floor(doorIndex)
	if doorIndex < 1 or doorIndex > GameState.RoomCount then
		return false, "Door out of range"
	end

	local data = GameState.Players[player]
	if not data or not data.IsAlive then
		return false, "Player not alive"
	end

	if GameState.Phase ~= "Playing" then
		return false, "Not in game"
	end

	local door = GameState.Doors[doorIndex]
	if not door then
		return false, "Door not found"
	end

	-- Check distance
	local char = player.Character
	if not char then return false, "No character" end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return false, "No root" end

	local dist = (root.Position - door.Position).Magnitude
	if dist > 10 then
		return false, "Too far"
	end

	local isOpen = door:GetAttribute("IsOpen")
	if isOpen then
		return true, "Already open"
	end

	door:SetAttribute("IsOpen", true)
	door.Transparency = 0.5
	door.CanCollide = false

	data.CurrentRoom = doorIndex
	RoomUpdateRemote:FireAllClients(doorIndex, player.Name)

	if door:GetAttribute("IsExit") then
		GameManager.EndRound("Escape", player)
	end

	return true, "Door opened"
end

-- ============================================================================
-- Hide Mechanic
-- ============================================================================
HideRemote.OnServerEvent:Connect(function(player, isHiding)
	if not checkRateLimit(player, "Hide") then return end
	if type(isHiding) ~= "boolean" then return end

	local data = GameState.Players[player]
	if not data or not data.IsAlive then return end
	if GameState.Phase ~= "Playing" then return end

	if isHiding then
		local char = player.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local roomIndex = data.CurrentRoom
		if roomIndex < 1 then roomIndex = 1 end

		local hidingSpots = RoomBuilder.GetHidingSpots(GameState.FloorModel, roomIndex)
		local nearSpot = false
		for _, spot in ipairs(hidingSpots) do
			if (root.Position - spot.Position).Magnitude < 6 then
				nearSpot = true
				break
			end
		end

		if not nearSpot then
			for _, spot in ipairs(RoomBuilder.GetHidingSpots(GameState.FloorModel, roomIndex + 1)) do
				if (root.Position - spot.Position).Magnitude < 6 then
					nearSpot = true
					break
				end
			end
		end

		if not nearSpot then
			isHiding = false
		end
	end

	data.IsHiding = isHiding

	local char = player.Character
	if char then
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = isHiding and 0.5 or 0
			end
		end
	end
end)

-- ============================================================================
-- Flashlight
-- ============================================================================
FlashlightRemote.OnServerEvent:Connect(function(player, isOn)
	if not checkRateLimit(player, "Flashlight") then return end
	if type(isOn) ~= "boolean" then return end

	local data = GameState.Players[player]
	if not data or not data.IsAlive then return end

	data.FlashlightOn = isOn
end)

-- ============================================================================
-- Player Lifecycle
-- ============================================================================
local function onPlayerAdded(player)
	initPlayer(player)

	player.CharacterAdded:Connect(function(char)
		local root = char:WaitForChild("HumanoidRootPart", 10)
		if root then
			if GameState.Phase == "Playing" and GameState.FloorModel then
				local spawnPos = RoomBuilder.GetSpawnPosition(GameState.FloorModel, 1)
				root.CFrame = CFrame.new(spawnPos)
			end
		end
	end)
end

local function onPlayerRemoving(player)
	cleanupPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- ============================================================================
-- Public API (additional)
-- ============================================================================
function GameManager.Init()
	-- Already initialized on module load; this is a no-op for compatibility
end

function GameManager.GetPhase()
	return GameState.Phase
end

function GameManager.GetGameState()
	return GameState
end

function GameManager.DamagePlayer(player, amount)
	damagePlayer(player, amount)
end

function GameManager.HealPlayer(player, amount)
	healPlayer(player, amount)
end

function GameManager.initPlayer(player)
	initPlayer(player)
end

function GameManager.cleanupPlayer(player)
	cleanupPlayer(player)
end

return GameManager