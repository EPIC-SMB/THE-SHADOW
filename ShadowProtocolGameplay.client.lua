-- ShadowProtocolGameplay.client.lua — LocalScript (StarterPlayerScripts)
-- Client-side gameplay for Shadow Protocol.
-- Handles: flashlight, hiding, door interaction, health/stamina display.
-- This runs alongside ShadowProtocolClient.client.lua (HUD/store).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- ============================================================================
-- Remote References
-- ============================================================================
local remotes = ReplicatedStorage:WaitForChild("ShadowRemotes")
local DoorInteractRemote = remotes:WaitForChild("DoorInteract")
local HideRemote = remotes:WaitForChild("Hide")
local FlashlightRemote = remotes:WaitForChild("Flashlight")
local HealthUpdateRemote = remotes:WaitForChild("HealthUpdate")
local GameStartRemote = remotes:WaitForChild("GameStart")
local GameEndRemote = remotes:WaitForChild("GameEnd")
local RoomUpdateRemote = remotes:WaitForChild("RoomUpdate")
local EntityDamageRemote = remotes:WaitForChild("EntityDamage")

-- ============================================================================
-- Player State
-- ============================================================================
local playerState = {
	Health = 100,
	MaxHealth = 100,
	Stamina = 100,
	MaxStamina = 100,
	IsHiding = false,
	FlashlightOn = false,
	FlashlightBattery = 100,
	CurrentRoom = 0,
	TotalRooms = 10,
}

-- ============================================================================
-- Flashlight
-- ============================================================================
local flashlightPart = nil
local flashlightLight = nil

local function createFlashlight()
	if flashlightPart then return end

	flashlightPart = Instance.new("Part")
	flashlightPart.Name = "Flashlight"
	flashlightPart.Size = Vector3.new(0.3, 0.3, 1)
	flashlightPart.Material = Enum.Material.Metal
	flashlightPart.Color = Color3.fromRGB(50, 50, 50)
	flashlightPart.CanCollide = false
	flashlightPart.Anchored = false
	flashlightPart.Parent = character

	flashlightLight = Instance.new("SpotLight")
	flashlightLight.Color = Color3.fromRGB(255, 240, 200)
	flashlightLight.Brightness = 3
	flashlightLight.Range = 40
	flashlightLight.Angle = 45
	flashlightLight.Shadows = true
	flashlightLight.Enabled = false
	flashlightLight.Parent = flashlightPart

	-- Weld to right hand
	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if rightHand then
		local weld = Instance.new("Weld")
		weld.Part0 = rightHand
		weld.Part1 = flashlightPart
		weld.C0 = CFrame.new(0, -0.5, -0.5) * CFrame.Angles(0, math.rad(90), 0)
		weld.Parent = rightHand
	end
end

local function toggleFlashlight()
	playerState.FlashlightOn = not playerState.FlashlightOn

	if flashlightLight then
		flashlightLight.Enabled = playerState.FlashlightOn
	end

	FlashlightRemote:FireServer(playerState.FlashlightOn)
end

-- ============================================================================
-- Hiding
-- ============================================================================
local function toggleHide()
	playerState.IsHiding = not playerState.IsHiding
	HideRemote:FireServer(playerState.IsHiding)

	-- Visual feedback
	if playerState.IsHiding then
		-- Darken screen slightly
		Lighting.Ambient = Color3.fromRGB(5, 5, 8)
	else
		Lighting.Ambient = Color3.fromRGB(10, 10, 15)
	end
end

-- ============================================================================
-- Door Interaction
-- ============================================================================
local function interactWithDoor(doorPart)
	if not doorPart then return end

	local doorIndex = doorPart:GetAttribute("DoorIndex")
	if not doorIndex then return end

	local success, message = DoorInteractRemote:InvokeServer(doorIndex)
	if success then
		-- Door opened successfully
		print("Door " .. doorIndex .. " opened: " .. message)
	else
		print("Cannot open door: " .. message)
	end
end

-- Proximity prompt handler
local function setupDoorPrompts()
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") and desc.Parent and desc.Parent.Name == "DoorPanel" then
			desc.Triggered:Connect(function()
				interactWithDoor(desc.Parent)
			end)
		end
	end
end

-- ============================================================================
-- Input Handling
-- ============================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.F then
		toggleFlashlight()
	elseif input.KeyCode == Enum.KeyCode.H then
		toggleHide()
	elseif input.KeyCode == Enum.KeyCode.E then
		-- Interact with nearest door
		local nearestDoor = nil
		local nearestDist = 10
		for _, desc in ipairs(workspace:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Name == "DoorPanel" then
				local dist = (desc.Position - root.Position).Magnitude
				if dist < nearestDist then
					nearestDist = dist
					nearestDoor = desc
				end
			end
		end
		if nearestDoor then
			interactWithDoor(nearestDoor)
		end
	end
end)

-- ============================================================================
-- Health/Stamina Update (from server)
-- ============================================================================
HealthUpdateRemote.OnClientEvent:Connect(function(health, maxHealth)
	playerState.Health = health
	playerState.MaxHealth = maxHealth
	-- Update HUD (handled by ShadowProtocolClient)
end)

-- ============================================================================
-- Game Start/End
-- ============================================================================
GameStartRemote.OnClientEvent:Connect(function(floor, roomCount)
	playerState.CurrentRoom = 0
	playerState.TotalRooms = roomCount
	playerState.Health = 100
	playerState.Stamina = 100
	playerState.FlashlightBattery = 100
	print("Game started! Floor " .. floor .. " with " .. roomCount .. " rooms")
end)

GameEndRemote.OnClientEvent:Connect(function(reason, data)
	if reason == "Death" then
		print("You died at room " .. (data.Room or 0))
	elseif reason == "Escape" then
		print("You escaped! Floor " .. (data.Floor or 0) .. " cleared in " .. (data.Time or 0) .. "s")
	elseif reason == "TimeUp" then
		print("Time's up!")
	end
end)

RoomUpdateRemote.OnClientEvent:Connect(function(roomIndex, playerName)
	playerState.CurrentRoom = roomIndex
	print(playerName .. " opened door " .. roomIndex)
end)

EntityDamageRemote.OnClientEvent:Connect(function(damage)
	-- Screen shake / red flash effect
	print("Took " .. damage .. " damage!")
end)

-- ============================================================================
-- Flashlight Battery Update (client-side prediction)
-- ============================================================================
RunService.Heartbeat:Connect(function(dt)
	if playerState.FlashlightOn then
		playerState.FlashlightBattery = math.max(0, playerState.FlashlightBattery - 2 * dt)
		if flashlightLight then
			flashlightLight.Brightness = 3 * (playerState.FlashlightBattery / 100)
		end
	end

	-- Stamina drain (client-side prediction for responsiveness)
	local isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
	if isSprinting and playerState.Stamina > 0 then
		playerState.Stamina = math.max(0, playerState.Stamina - 20 * dt)
	elseif not isSprinting then
		playerState.Stamina = math.min(100, playerState.Stamina + 10 * dt)
	end
end)

-- ============================================================================
-- Initialize
-- ============================================================================
createFlashlight()
setupDoorPrompts()

-- Re-setup door prompts when new doors are added
workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("ProximityPrompt") then
		task.wait(0.1)
		if desc.Parent and desc.Parent.Name == "DoorPanel" then
			desc.Triggered:Connect(function()
				interactWithDoor(desc.Parent)
			end)
		end
	end
end)

print("Shadow Protocol Gameplay loaded")