-- ShadowProtocolRoomBuilder.lua — ModuleScript (ReplicatedStorage)
-- Procedural room generation for Shadow Protocol floors.
-- Generates a linear sequence of rooms connected by corridors and doors.
-- All parts are created server-side and replicated to clients.

local RoomBuilder = {}

-- ============================================================================
-- Configuration
-- ============================================================================
RoomBuilder.Config = {
	RoomWidth = 24,        -- studs
	RoomDepth = 24,        -- studs
	RoomHeight = 12,       -- studs
	CorridorLength = 12,   -- studs
	CorridorWidth = 6,     -- studs
	WallThickness = 1,     -- studs
	DoorWidth = 4,         -- studs
	DoorHeight = 8,        -- studs
	LightColor = Color3.fromRGB(200, 180, 150),
	LightBrightness = 0.5,
	AmbientColor = Color3.fromRGB(10, 10, 15),
}

-- ============================================================================
-- Material palette (original, not copied)
-- ============================================================================
RoomBuilder.Materials = {
	Floor = Enum.Material.Concrete,
	Wall = Enum.Material.SmoothPlastic,
	Ceiling = Enum.Material.SmoothPlastic,
	Door = Enum.Material.Wood,
	HidingSpot = Enum.Material.Fabric,
}

-- ============================================================================
-- Color palette (original, dark horror aesthetic)
-- ============================================================================
RoomBuilder.Colors = {
	Floor = Color3.fromRGB(40, 40, 45),
	Wall = Color3.fromRGB(60, 55, 50),
	Ceiling = Color3.fromRGB(30, 30, 35),
	Door = Color3.fromRGB(80, 60, 40),
	DoorFrame = Color3.fromRGB(50, 40, 30),
	HidingSpot = Color3.fromRGB(30, 25, 20),
	Accent = Color3.fromRGB(180, 160, 120),
}

-- ============================================================================
-- Helper: Create a part with properties
-- ============================================================================
local function createPart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = true
	for k, v in pairs(props) do
		part[k] = v
	end
	return part
end

-- ============================================================================
-- Build a single room
-- Returns: Model containing floor, walls, ceiling, and optional hiding spot
-- ============================================================================
function RoomBuilder.BuildRoom(index, position, hasHidingSpot, hasLight)
	local config = RoomBuilder.Config
	local colors = RoomBuilder.Colors
	local materials = RoomBuilder.Materials

	local room = Instance.new("Model")
	room.Name = "Room_" .. index

	local w = config.RoomWidth
	local d = config.RoomDepth
	local h = config.RoomHeight
	local t = config.WallThickness

	-- Floor
	local floor = createPart({
		Name = "Floor",
		Size = Vector3.new(w, t, d),
		Position = position,
		Material = materials.Floor,
		Color = colors.Floor,
	})
	floor.Parent = room

	-- Ceiling
	local ceiling = createPart({
		Name = "Ceiling",
		Size = Vector3.new(w, t, d),
		Position = position + Vector3.new(0, h, 0),
		Material = materials.Ceiling,
		Color = colors.Ceiling,
	})
	ceiling.Parent = room

	-- Walls (4 sides, with door openings on front/back)
	-- Front wall (with door opening)
	local frontWallLeft = createPart({
		Name = "FrontWallLeft",
		Size = Vector3.new((w - config.DoorWidth) / 2, h, t),
		Position = position + Vector3.new(-(w + config.DoorWidth) / 4, h / 2, -d / 2),
		Material = materials.Wall,
		Color = colors.Wall,
	})
	frontWallLeft.Parent = room

	local frontWallRight = createPart({
		Name = "FrontWallRight",
		Size = Vector3.new((w - config.DoorWidth) / 2, h, t),
		Position = position + Vector3.new((w + config.DoorWidth) / 4, h / 2, -d / 2),
		Material = materials.Wall,
		Color = colors.Wall,
	})
	frontWallRight.Parent = room

	-- Back wall (with door opening)
	local backWallLeft = createPart({
		Name = "BackWallLeft",
		Size = Vector3.new((w - config.DoorWidth) / 2, h, t),
		Position = position + Vector3.new(-(w + config.DoorWidth) / 4, h / 2, d / 2),
		Material = materials.Wall,
		Color = colors.Wall,
	})
	backWallLeft.Parent = room

	local backWallRight = createPart({
		Name = "BackWallRight",
		Size = Vector3.new((w - config.DoorWidth) / 2, h, t),
		Position = position + Vector3.new((w + config.DoorWidth) / 4, h / 2, d / 2),
		Material = materials.Wall,
		Color = colors.Wall,
	})
	backWallRight.Parent = room

	-- Left wall (solid)
	local leftWall = createPart({
		Name = "LeftWall",
		Size = Vector3.new(t, h, d),
		Position = position + Vector3.new(-w / 2, h / 2, 0),
		Material = materials.Wall,
		Color = colors.Wall,
	})
	leftWall.Parent = room

	-- Right wall (solid)
	local rightWall = createPart({
		Name = "RightWall",
		Size = Vector3.new(t, h, d),
		Position = position + Vector3.new(w / 2, h / 2, 0),
		Material = materials.Wall,
		Color = colors.Wall,
	})
	rightWall.Parent = room

	-- Hiding spot (closet)
	if hasHidingSpot then
		local closet = createPart({
			Name = "HidingSpot",
			Size = Vector3.new(4, 6, 3),
			Position = position + Vector3.new(-w / 2 + 3, 3, -d / 2 + 3),
			Material = materials.HidingSpot,
			Color = colors.HidingSpot,
			CanCollide = true,
		})
		closet.Parent = room

		-- Closet door (transparent when hiding)
		local closetDoor = createPart({
			Name = "ClosetDoor",
			Size = Vector3.new(4, 6, 0.5),
			Position = position + Vector3.new(-w / 2 + 3, 3, -d / 2 + 1.5),
			Material = materials.Door,
			Color = colors.Door,
			Transparency = 0.3,
			CanCollide = false,
		})
		closetDoor.Parent = room
	end

	-- Light (flickering ambient)
	if hasLight then
		local lightPart = createPart({
			Name = "LightFixture",
			Size = Vector3.new(2, 0.5, 2),
			Position = position + Vector3.new(0, h - 1, 0),
			Material = Enum.Material.Neon,
			Color = colors.Accent,
			CanCollide = false,
		})
		lightPart.Parent = room

		local light = Instance.new("PointLight")
		light.Color = config.LightColor
		light.Brightness = config.LightBrightness
		light.Range = 20
		light.Shadows = true
		light.Parent = lightPart
	end

	-- Spawn point marker
	local spawnPoint = Instance.new("Part")
	spawnPoint.Name = "SpawnPoint"
	spawnPoint.Size = Vector3.new(2, 0.5, 2)
	spawnPoint.Position = position + Vector3.new(0, 0.5, 0)
	spawnPoint.Anchored = true
	spawnPoint.CanCollide = false
	spawnPoint.Transparency = 1
	spawnPoint.Parent = room

	return room
end

-- ============================================================================
-- Build a door between two rooms
-- ============================================================================
function RoomBuilder.BuildDoor(index, position, isOpen)
	local config = RoomBuilder.Config
	local colors = RoomBuilder.Colors

	local doorModel = Instance.new("Model")
	doorModel.Name = "Door_" .. index

	-- Door frame
	local frameLeft = createPart({
		Name = "FrameLeft",
		Size = Vector3.new(0.5, config.DoorHeight, 0.5),
		Position = position + Vector3.new(-config.DoorWidth / 2, config.DoorHeight / 2, 0),
		Material = RoomBuilder.Materials.Door,
		Color = RoomBuilder.Colors.DoorFrame,
	})
	frameLeft.Parent = doorModel

	local frameRight = createPart({
		Name = "FrameRight",
		Size = Vector3.new(0.5, config.DoorHeight, 0.5),
		Position = position + Vector3.new(config.DoorWidth / 2, config.DoorHeight / 2, 0),
		Material = RoomBuilder.Materials.Door,
		Color = RoomBuilder.Colors.DoorFrame,
	})
	frameRight.Parent = doorModel

	local frameTop = createPart({
		Name = "FrameTop",
		Size = Vector3.new(config.DoorWidth + 1, 0.5, 0.5),
		Position = position + Vector3.new(0, config.DoorHeight, 0),
		Material = RoomBuilder.Materials.Door,
		Color = RoomBuilder.Colors.DoorFrame,
	})
	frameTop.Parent = doorModel

	-- Door panel
	local door = createPart({
		Name = "DoorPanel",
		Size = Vector3.new(config.DoorWidth, config.DoorHeight, 0.5),
		Position = position + Vector3.new(0, config.DoorHeight / 2, 0),
		Material = RoomBuilder.Materials.Door,
		Color = colors.Door,
		CanCollide = not isOpen,
		Transparency = isOpen and 0.5 or 0,
	})
	door.Parent = doorModel

	-- Door interaction prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open Door"
	prompt.ObjectText = "Door " .. index
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = door

	-- Door state attribute
	door:SetAttribute("IsOpen", isOpen)
	door:SetAttribute("DoorIndex", index)

	return doorModel, door
end

-- ============================================================================
-- Build a complete floor
-- Returns: Model containing all rooms, corridors, and doors
-- ============================================================================
function RoomBuilder.BuildFloor(floorIndex, roomCount)
	local config = RoomBuilder.Config
	local floorModel = Instance.new("Model")
	floorModel.Name = "Floor_" .. floorIndex

	local currentPos = Vector3.new(0, 0, 0)
	local rooms = {}
	local doors = {}

	for i = 1, roomCount do
		-- Determine room properties
		local hasHiding = (i % 3 == 0) or (i == 1) -- hiding spots every 3rd room + first
		local hasLight = (i % 2 == 1) -- alternating lights

		-- Build room
		local room = RoomBuilder.BuildRoom(i, currentPos, hasHiding, hasLight)
		room.Parent = floorModel
		rooms[i] = room

		-- Build door to next room (except last)
		if i < roomCount then
			local doorPos = currentPos + Vector3.new(0, 0, config.RoomDepth / 2 + config.CorridorLength / 2)
			local doorModel, doorPart = RoomBuilder.BuildDoor(i, doorPos, false)
			doorModel.Parent = floorModel
			doors[i] = doorPart

			-- Corridor between rooms
			local corridor = createPart({
				Name = "Corridor_" .. i,
				Size = Vector3.new(config.CorridorWidth, config.RoomHeight, config.CorridorLength),
				Position = currentPos + Vector3.new(0, config.RoomHeight / 2, config.RoomDepth / 2 + config.CorridorLength / 2),
				Material = RoomBuilder.Materials.Floor,
				Color = RoomBuilder.Colors.Floor,
			})
			corridor.Parent = floorModel

			-- Corridor walls
			local leftCorrWall = createPart({
				Name = "CorrWallLeft_" .. i,
				Size = Vector3.new(1, config.RoomHeight, config.CorridorLength),
				Position = currentPos + Vector3.new(-config.CorridorWidth / 2, config.RoomHeight / 2, config.RoomDepth / 2 + config.CorridorLength / 2),
				Material = RoomBuilder.Materials.Wall,
				Color = RoomBuilder.Colors.Wall,
			})
			leftCorrWall.Parent = floorModel

			local rightCorrWall = createPart({
				Name = "CorrWallRight_" .. i,
				Size = Vector3.new(1, config.RoomHeight, config.CorridorLength),
				Position = currentPos + Vector3.new(config.CorridorWidth / 2, config.RoomHeight / 2, config.RoomDepth / 2 + config.CorridorLength / 2),
				Material = RoomBuilder.Materials.Wall,
				Color = RoomBuilder.Colors.Wall,
			})
			rightCorrWall.Parent = floorModel

			-- Corridor ceiling
			local corrCeiling = createPart({
				Name = "CorrCeiling_" .. i,
				Size = Vector3.new(config.CorridorWidth, 1, config.CorridorLength),
				Position = currentPos + Vector3.new(0, config.RoomHeight, config.RoomDepth / 2 + config.CorridorLength / 2),
				Material = RoomBuilder.Materials.Ceiling,
				Color = RoomBuilder.Colors.Ceiling,
			})
			corrCeiling.Parent = floorModel

			-- Next room position
			currentPos = currentPos + Vector3.new(0, 0, config.RoomDepth + config.CorridorLength)
		end
	end

	-- Exit door (final room, leads to escape)
	local exitDoorPos = currentPos + Vector3.new(0, 0, config.RoomDepth / 2)
	local exitDoorModel, exitDoorPart = RoomBuilder.BuildDoor(roomCount, exitDoorPos, false)
	exitDoorModel.Parent = floorModel
	exitDoorPart:SetAttribute("IsExit", true)
	doors[roomCount] = exitDoorPart

	-- Store metadata
	floorModel:SetAttribute("RoomCount", roomCount)
	floorModel:SetAttribute("FloorIndex", floorIndex)

	return floorModel, rooms, doors
end

-- ============================================================================
-- Utility: Get spawn position for a room
-- ============================================================================
function RoomBuilder.GetSpawnPosition(floorModel, roomIndex)
	local room = floorModel:FindFirstChild("Room_" .. roomIndex)
	if room then
		local spawnPoint = room:FindFirstChild("SpawnPoint")
		if spawnPoint then
			return spawnPoint.Position + Vector3.new(0, 3, 0)
		end
	end
	return Vector3.new(0, 5, 0)
end

-- ============================================================================
-- Utility: Get hiding spots in a room
-- ============================================================================
function RoomBuilder.GetHidingSpots(floorModel, roomIndex)
	local spots = {}
	local room = floorModel:FindFirstChild("Room_" .. roomIndex)
	if room then
		for _, child in ipairs(room:GetChildren()) do
			if child.Name == "HidingSpot" then
				table.insert(spots, child)
			end
		end
	end
	return spots
end

return RoomBuilder