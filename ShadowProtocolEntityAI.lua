-- ShadowProtocolEntityAI.lua — ModuleScript (ReplicatedStorage)
-- Entity AI system for Shadow Protocol.
-- Handles spawning, pathfinding, detection, and damage for entities.
-- Server-authoritative: all entity state and decisions are server-side.

local EntityAI = {}

-- ============================================================================
-- Services
-- ============================================================================
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ============================================================================
-- Entity state tracking
-- ============================================================================
EntityAI.ActiveEntities = {}  -- [entityId] = { model, type, target, state, ... }

-- ============================================================================
-- Configuration (from config)
-- ============================================================================
EntityAI.Config = {
	Watcher = {
		DetectionRange = 30,       -- studs: player detected within this range
		DamageRange = 5,           -- studs: instant kill within this range
		MoveSpeed = 8,             -- studs/sec
		TeleportCooldown = 10,     -- seconds between teleports
		LookAwayDamageDelay = 2,   -- seconds of eye contact before damage
		PatrolSpeed = 4,           -- studs/sec when patrolling
	},
}

-- ============================================================================
-- Create an entity model (placeholder geometry)
-- ============================================================================
function EntityAI.CreateEntityModel(entityType, position)
	local model = Instance.new("Model")
	model.Name = entityType

	-- Main body (dark, menacing)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 7, 2)
	body.Position = position + Vector3.new(0, 3.5, 0)
	body.Anchored = false
	body.CanCollide = false
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(20, 15, 25)
	body.Transparency = 0.1
	body.Parent = model

	-- "Eyes" (glowing, the tell)
	local leftEye = Instance.new("Part")
	leftEye.Name = "LeftEye"
	leftEye.Size = Vector3.new(0.6, 0.3, 0.3)
	leftEye.Position = position + Vector3.new(-0.6, 5.5, -1)
	leftEye.Anchored = false
	leftEye.CanCollide = false
	leftEye.Material = Enum.Material.Neon
	leftEye.Color = Color3.fromRGB(180, 50, 200)  -- purple glow = Watcher tell
	leftEye.Parent = model

	local rightEye = Instance.new("Part")
	rightEye.Name = "RightEye"
	rightEye.Size = Vector3.new(0.6, 0.3, 0.3)
	rightEye.Position = position + Vector3.new(0.6, 5.5, -1)
	rightEye.Anchored = false
	rightEye.CanCollide = false
	rightEye.Material = Enum.Material.Neon
	rightEye.Color = Color3.fromRGB(180, 50, 200)
	rightEye.Parent = model

	-- Weld eyes to body
	for _, eye in ipairs({leftEye, rightEye}) do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = eye
		weld.Parent = body
	end

	-- Humanoid for movement
	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = EntityAI.Config.Watcher.MoveSpeed
	humanoid.MaxHealth = 9999
	humanoid.Health = 9999
	humanoid.Parent = model

	-- Root part
	model.PrimaryPart = body

	-- Point light (purple glow, visible from distance)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(180, 50, 200)
	glow.Brightness = 2
	glow.Range = 15
	glow.Shadows = false
	glow.Parent = body

	return model
end

-- ============================================================================
-- Spawn an entity
-- ============================================================================
function EntityAI.Spawn(entityType, position, floorModel)
	local entityModel = EntityAI.CreateEntityModel(entityType, position)
	entityModel.Parent = floorModel or workspace

	local entityId = entityType .. "_" .. tostring(math.random(100000, 999999))

	local entityData = {
		Id = entityId,
		Type = entityType,
		Model = entityModel,
		Position = position,
		State = "Patrolling",  -- Patrolling, Chasing, Teleporting, Idle
		Target = nil,
		LastTeleport = 0,
		LookTimer = 0,  -- tracks how long a player has been looking
		Active = true,
	}

	EntityAI.ActiveEntities[entityId] = entityData

	-- Start AI loop
	EntityAI.StartAI(entityId)

	return entityId, entityModel
end

-- ============================================================================
-- AI Loop for an entity
-- ============================================================================
function EntityAI.StartAI(entityId)
	local entityData = EntityAI.ActiveEntities[entityId]
	if not entityData then return end

	local config = EntityAI.Config[entityData.Type]
	if not config then return end

	-- Run AI on Heartbeat
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not entityData.Active then
			connection:Disconnect()
			return
		end

		local model = entityData.Model
		if not model or not model.Parent then
			entityData.Active = false
			connection:Disconnect()
			return
		end

		local body = model:FindFirstChild("Body")
		if not body then return end

		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		-- Find nearest player
		local nearestPlayer = nil
		local nearestDist = config.DetectionRange

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					local dist = (root.Position - body.Position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearestPlayer = player
					end
				end
			end
		end

		entityData.Target = nearestPlayer

		if nearestPlayer then
			local char = nearestPlayer.Character
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local dist = (root.Position - body.Position).Magnitude

				-- Check if player is looking at entity (for Watcher)
				local isLooking = EntityAI.IsPlayerLookingAt(nearestPlayer, body.Position)

				if dist <= config.DamageRange then
					-- Close enough to damage
					if isLooking then
						entityData.LookTimer = entityData.LookTimer + dt
						if entityData.LookTimer >= config.LookAwayDamageDelay then
							-- Damage player
							EntityAI.DamagePlayer(nearestPlayer, config.DamageRange * 20)
							entityData.LookTimer = 0
						end
					else
						entityData.LookTimer = 0
					end
				elseif dist <= config.DetectionRange then
					-- Chase
					entityData.State = "Chasing"
					humanoid.WalkSpeed = config.MoveSpeed
					-- Move toward player using PathfindingService
					EntityAI.MoveToTarget(model, root.Position)
				else
					entityData.State = "Patrolling"
					entityData.LookTimer = 0
				end
			end
		else
			entityData.State = "Patrolling"
			entityData.LookTimer = 0
		end
	end)
end

-- ============================================================================
-- Check if player is looking at a position
-- ============================================================================
function EntityAI.IsPlayerLookingAt(player, targetPos)
	local char = player.Character
	if not char then return false end
	local root = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")
	if not root or not head then return false end

	local lookVector = head.CFrame.LookVector
	local toTarget = (targetPos - head.Position).Unit
	local dot = lookVector:Dot(toTarget)

	-- If dot product > 0.5, player is roughly looking at target
	return dot > 0.5
end

-- ============================================================================
-- Move entity to target position using pathfinding
-- ============================================================================
function EntityAI.MoveToTarget(model, targetPos)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Simple direct movement (pathfinding can be added for complex layouts)
	local body = model.PrimaryPart
	if body then
		humanoid:MoveTo(targetPos)
	end
end

-- Damage callback (set by GameManager to route damage through server health system)
EntityAI.DamageCallback = nil

-- ============================================================================
-- Damage a player (routes through GameManager health system if callback set)
-- ============================================================================
function EntityAI.DamagePlayer(player, damage)
	-- Visual feedback remote
	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("ShadowRemotes")
	if remotes and remotes:FindFirstChild("EntityDamage") then
		remotes.EntityDamage:FireClient(player, damage)
	end

	-- Route through GameManager health system (respects hiding, death handling)
	if EntityAI.DamageCallback then
		EntityAI.DamageCallback(player, damage)
	else
		-- Fallback: direct humanoid damage (not recommended)
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid:TakeDamage(damage)
			end
		end
	end
end

-- ============================================================================
-- Despawn an entity
-- ============================================================================
function EntityAI.Despawn(entityId)
	local entityData = EntityAI.ActiveEntities[entityId]
	if entityData then
		entityData.Active = false
		if entityData.Model then
			entityData.Model:Destroy()
		end
		EntityAI.ActiveEntities[entityId] = nil
	end
end

-- ============================================================================
-- Despawn all entities
-- ============================================================================
function EntityAI.DespawnAll()
	for entityId, _ in pairs(EntityAI.ActiveEntities) do
		EntityAI.Despawn(entityId)
	end
end

-- ============================================================================
-- Get entity position
-- ============================================================================
function EntityAI.GetPosition(entityId)
	local entityData = EntityAI.ActiveEntities[entityId]
	if entityData and entityData.Model and entityData.Model.PrimaryPart then
		return entityData.Model.PrimaryPart.Position
	end
	return nil
end

return EntityAI