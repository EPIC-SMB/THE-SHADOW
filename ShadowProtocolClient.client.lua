-- ShadowProtocolClient.client.lua — LocalScript (StarterPlayerScripts)
-- Shadow Protocol client: HUD, store UI, entity warnings, psychology-driven
-- UI (progress bars, streaks, near-miss, FOMO banners, social proof).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SPC = require(ReplicatedStorage:WaitForChild("ShadowProtocolConfig"))

-- ============================================================================
-- UI Helpers
-- ============================================================================
local function createElement(class, parent, props)
	local el = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			el.Parent = v
		else
			el[k] = v
		end
	end
	return el
end

local function tweenIn(element, duration)
	element.Visible = true
	element.BackgroundTransparency = 1
	local tween = TweenService:Create(element, TweenInfo.new(duration or 0.3), { BackgroundTransparency = 0.3 })
	tween:Play()
end

-- ============================================================================
-- Screen GUI
-- ============================================================================
local screenGui = createElement("ScreenGui", playerGui, {
	Name = "ShadowProtocolUI",
	ResetOnSpawn = false,
})

-- ============================================================================
-- HUD (top-left: shards, rep, floor, streak)
-- ============================================================================
local hudFrame = createElement("Frame", screenGui, {
	Size = UDim2.new(0, 260, 0, 140),
	Position = UDim2.new(0, 16, 0, 12),
	BackgroundColor3 = Color3.fromRGB(10, 10, 20),
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
})

local shardLabel = createElement("TextLabel", hudFrame, {
	Size = UDim2.new(1, -16, 0, 28),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size18,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(180, 220, 255),
	Text = "Shards: 0",
})

local repLabel = createElement("TextLabel", hudFrame, {
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 8, 0, 38),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	FontSize = Enum.FontSize.Size14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(200, 200, 255),
	Text = "Rep: 0 | XP: 0",
})

local floorLabel = createElement("TextLabel", hudFrame, {
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 8, 0, 62),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	FontSize = Enum.FontSize.Size14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(180, 220, 180),
	Text = "Floor: 0/8 | Door: 0/100",
})

local streakLabel = createElement("TextLabel", hudFrame, {
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 8, 0, 86),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(255, 200, 80),
	Text = "Streak: 0 days",
})

-- Health/stamina display (added for gameplay)
local healthLabel = createElement("TextLabel", hudFrame, {
	Size = UDim2.new(1, -16, 0, 22),
	Position = UDim2.new(0, 8, 0, 110),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(255, 100, 100),
	Text = "HP: 100/100 | Stamina: 100",
})

-- Progress bar (Zeigarnik: completion tension)
local progressBarBg = createElement("Frame", hudFrame, {
	Size = UDim2.new(1, -16, 0, 8),
	Position = UDim2.new(0, 8, 0, 136),
	BackgroundColor3 = Color3.fromRGB(40, 40, 60),
	BorderSizePixel = 0,
})
local progressBarFill = createElement("Frame", progressBarBg, {
	Size = UDim2.new(0, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(100, 180, 255),
	BorderSizePixel = 0,
})

-- ============================================================================
-- Daily Reward Popup (commitment/consistency)
-- ============================================================================
local dailyPopup = createElement("Frame", screenGui, {
	Size = UDim2.new(0, 320, 0, 200),
	Position = UDim2.new(0.5, -160, 0.5, -100),
	BackgroundColor3 = Color3.fromRGB(15, 15, 30),
	BackgroundTransparency = 0.1,
	BorderSizePixel = 2,
	BorderColor3 = Color3.fromRGB(255, 200, 80),
	Visible = false,
})
local dailyTitle = createElement("TextLabel", dailyPopup, {
	Size = UDim2.new(1, 0, 0, 36),
	Position = UDim2.new(0, 0, 0, 8),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size20,
	TextColor3 = Color3.fromRGB(255, 200, 80),
	Text = "Daily Reward!",
})
local dailyInfo = createElement("TextLabel", dailyPopup, {
	Size = UDim2.new(1, -24, 0, 60),
	Position = UDim2.new(0, 12, 0, 50),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	FontSize = Enum.FontSize.Size14,
	TextColor3 = Color3.fromRGB(220, 220, 240),
	Text = "Day 1: +10 Shards, +2 XP",
	TextWrapped = true,
})
local dailyClaimBtn = createElement("TextButton", dailyPopup, {
	Size = UDim2.new(0, 140, 0, 36),
	Position = UDim2.new(0.5, -70, 1, -50),
	BackgroundColor3 = Color3.fromRGB(60, 120, 60),
	BorderColor3 = Color3.fromRGB(100, 200, 100),
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size14,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "Claim Reward",
})

-- ============================================================================
-- Store Overlay (Shard Shop + Robux Shop)
-- ============================================================================
local storeOverlay = createElement("Frame", screenGui, {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.5,
	Visible = false,
})

local storeTitle = createElement("TextLabel", storeOverlay, {
	Size = UDim2.new(0, 300, 0, 40),
	Position = UDim2.new(0.5, -150, 0, 16),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size28,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	Text = "Store",
})

-- Tab buttons
local shardTabBtn = createElement("TextButton", storeOverlay, {
	Size = UDim2.new(0, 120, 0, 32),
	Position = UDim2.new(0.5, -130, 0, 60),
	BackgroundColor3 = Color3.fromRGB(60, 60, 80),
	BorderColor3 = Color3.fromRGB(100, 100, 130),
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size14,
	TextColor3 = Color3.fromRGB(180, 220, 255),
	Text = "Shard Shop",
})
local robuxTabBtn = createElement("TextButton", storeOverlay, {
	Size = UDim2.new(0, 120, 0, 32),
	Position = UDim2.new(0.5, 10, 0, 60),
	BackgroundColor3 = Color3.fromRGB(60, 60, 80),
	BorderColor3 = Color3.fromRGB(100, 100, 130),
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size14,
	TextColor3 = Color3.fromRGB(255, 215, 0),
	Text = "Robux Shop",
})

-- Content frames
local shardShopFrame = createElement("ScrollingFrame", storeOverlay, {
	Size = UDim2.new(0, 400, 0, 400),
	Position = UDim2.new(0.5, -200, 0, 100),
	BackgroundColor3 = Color3.fromRGB(20, 20, 35),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	Visible = true,
})
local robuxShopFrame = createElement("ScrollingFrame", storeOverlay, {
	Size = UDim2.new(0, 400, 0, 400),
	Position = UDim2.new(0.5, -200, 0, 100),
	BackgroundColor3 = Color3.fromRGB(20, 20, 35),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	Visible = false,
})

-- ============================================================================
-- Shard Shop Items
-- ============================================================================
local function buildShardShop()
	for _, child in ipairs(shardShopFrame:GetChildren()) do
		if child.Name == "ShardItem" then child:Destroy() end
	end
	local y = 8
	for i, item in ipairs(SPC.ShardShop) do
		local btn = createElement("TextButton", shardShopFrame, {
			Name = "ShardItem",
			Size = UDim2.new(1, -16, 0, 40),
			Position = UDim2.new(0, 8, 0, y),
			BackgroundColor3 = Color3.fromRGB(35, 35, 55),
			BorderColor3 = Color3.fromRGB(80, 80, 110),
			Font = Enum.Font.Gotham,
			FontSize = Enum.FontSize.Size14,
			TextColor3 = Color3.fromRGB(220, 220, 240),
			Text = string.format("%s — %d Shards", item.Name, item.Price),
		})
		btn.MouseButton1Click:Connect(function()
			local remotes = ReplicatedStorage:WaitForChild("ShadowRemotes")
			remotes.BuyShardItem:FireServer(item.Name)
		end)
		y = y + 48
	end
	shardShopFrame.CanvasSize = UDim2.new(0, 0, 0, y + 8)
end

-- ============================================================================
-- Robux Shop Items (with odds disclosure)
-- ============================================================================
local function buildRobuxShop()
	for _, child in ipairs(robuxShopFrame:GetChildren()) do
		if child.Name == "RobuxItem" then child:Destroy() end
	end
	local y = 8

	-- Odds disclosure banner (required for paid random items)
	local oddsBanner = createElement("TextLabel", robuxShopFrame, {
		Name = "RobuxItem",
		Size = UDim2.new(1, -16, 0, 60),
		Position = UDim2.new(0, 8, 0, y),
		BackgroundColor3 = Color3.fromRGB(60, 40, 20),
		BorderSizePixel = 1,
		BorderColor3 = Color3.fromRGB(200, 150, 50),
		Font = Enum.Font.Gotham,
		FontSize = Enum.FontSize.Size11,
		TextColor3 = Color3.fromRGB(255, 230, 180),
		Text = SPC.OddsDisclosure.Body,
		TextWrapped = true,
	})
	y = y + 68

	-- Passes section
	local passesHeader = createElement("TextLabel", robuxShopFrame, {
		Name = "RobuxItem",
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.new(0, 8, 0, y),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		FontSize = Enum.FontSize.Size16,
		TextColor3 = Color3.fromRGB(255, 215, 0),
		Text = "— Game Passes (Permanent) —",
	})
	y = y + 32

	for passKey, price in pairs(SPC.PassPrices) do
		local btn = createElement("TextButton", robuxShopFrame, {
			Name = "RobuxItem",
			Size = UDim2.new(1, -16, 0, 44),
			Position = UDim2.new(0, 8, 0, y),
			BackgroundColor3 = Color3.fromRGB(50, 40, 20),
			BorderColor3 = Color3.fromRGB(200, 170, 50),
			Font = Enum.Font.GothamBold,
			FontSize = Enum.FontSize.Size14,
			TextColor3 = Color3.fromRGB(255, 215, 0),
			Text = string.format("%s — %d Robux", passKey, price),
		})
		btn.MouseButton1Click:Connect(function()
			local passId = SPC.PASS_IDS[passKey]
			if passId == 0 then
				print("Pass not configured yet")
				return
			end
			MarketplaceService:PromptGamePassPurchase(player, passId)
		end)
		y = y + 52
	end

	-- Products section
	local productsHeader = createElement("TextLabel", robuxShopFrame, {
		Name = "RobuxItem",
		Size = UDim2.new(1, -16, 0, 24),
		Position = UDim2.new(0, 8, 0, y),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		FontSize = Enum.FontSize.Size16,
		TextColor3 = Color3.fromRGB(100, 180, 255),
		Text = "— Developer Products (Repeatable) —",
	})
	y = y + 32

	for productKey, price in pairs(SPC.RobuxPrices) do
		local btn = createElement("TextButton", robuxShopFrame, {
			Name = "RobuxItem",
			Size = UDim2.new(1, -16, 0, 40),
			Position = UDim2.new(0, 8, 0, y),
			BackgroundColor3 = Color3.fromRGB(25, 35, 55),
			BorderColor3 = Color3.fromRGB(60, 100, 160),
			Font = Enum.Font.Gotham,
			FontSize = Enum.FontSize.Size14,
			TextColor3 = Color3.fromRGB(200, 220, 255),
			Text = string.format("%s — %d Robux", productKey, price),
		})
		btn.MouseButton1Click:Connect(function()
			local productId = SPC.PRODUCT_IDS[productKey]
			if productId == 0 then
				print("Product not configured yet")
				return
			end
			MarketplaceService:PromptProductPurchase(player, productId)
		end)
		y = y + 48
	end

	robuxShopFrame.CanvasSize = UDim2.new(0, 0, 0, y + 8)
end

-- ============================================================================
-- Tab switching
-- ============================================================================
shardTabBtn.MouseButton1Click:Connect(function()
	shardShopFrame.Visible = true
	robuxShopFrame.Visible = false
	shardTabBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 110)
	robuxTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
end)
robuxTabBtn.MouseButton1Click:Connect(function()
	shardShopFrame.Visible = false
	robuxShopFrame.Visible = true
	shardTabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	robuxTabBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 110)
end)

-- ============================================================================
-- Near-Miss Popup (loss aversion)
-- ============================================================================
local nearMissPopup = createElement("Frame", screenGui, {
	Size = UDim2.new(0, 340, 0, 80),
	Position = UDim2.new(0.5, -170, 0.4, 0),
	BackgroundColor3 = Color3.fromRGB(80, 20, 20),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 2,
	BorderColor3 = Color3.fromRGB(255, 80, 80),
	Visible = false,
})
local nearMissLabel = createElement("TextLabel", nearMissPopup, {
	Size = UDim2.new(1, -16, 1, -16),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size16,
	TextColor3 = Color3.fromRGB(255, 200, 200),
	Text = "So close! Just 3 more rooms...",
	TextWrapped = true,
})

-- ============================================================================
-- Bonus Reward Popup (variable ratio — dopamine hit)
-- ============================================================================
local bonusPopup = createElement("Frame", screenGui, {
	Size = UDim2.new(0, 260, 0, 60),
	Position = UDim2.new(0.5, -130, 0.3, 0),
	BackgroundColor3 = Color3.fromRGB(20, 60, 30),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 2,
	BorderColor3 = Color3.fromRGB(80, 220, 120),
	Visible = false,
})
local bonusLabel = createElement("TextLabel", bonusPopup, {
	Size = UDim2.new(1, -16, 1, -16),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size14,
	TextColor3 = Color3.fromRGB(180, 255, 200),
	Text = "Bonus Reward!",
	TextWrapped = true,
})

-- ============================================================================
-- Achievement Popup
-- ============================================================================
local achPopup = createElement("Frame", screenGui, {
	Size = UDim2.new(0, 300, 0, 70),
	Position = UDim2.new(0.5, -150, 0.2, 0),
	BackgroundColor3 = Color3.fromRGB(40, 30, 60),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 2,
	BorderColor3 = Color3.fromRGB(180, 130, 255),
	Visible = false,
})
local achLabel = createElement("TextLabel", achPopup, {
	Size = UDim2.new(1, -16, 1, -16),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size14,
	TextColor3 = Color3.fromRGB(220, 190, 255),
	Text = "Achievement Unlocked!",
	TextWrapped = true,
})

-- ============================================================================
-- Social Proof Banner (bottom)
-- ============================================================================
local socialBanner = createElement("Frame", screenGui, {
	Size = UDim2.new(0, 400, 0, 28),
	Position = UDim2.new(0.5, -200, 1, -40),
	BackgroundColor3 = Color3.fromRGB(10, 10, 20),
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
})
local socialLabel = createElement("TextLabel", socialBanner, {
	Size = UDim2.new(1, -16, 1, 0),
	Position = UDim2.new(0, 8, 0, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	FontSize = Enum.FontSize.Size12,
	TextColor3 = Color3.fromRGB(150, 150, 180),
	Text = "12,847 players escaped today | 4,201 online now",
})

-- ============================================================================
-- Limited-Time FOMO Banner (top)
-- ============================================================================
local fomoBanner = createElement("Frame", screenGui, {
	Size = UDim2.new(1, 0, 0, 32),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Color3.fromRGB(80, 40, 10),
	BackgroundTransparency = 0.2,
	BorderSizePixel = 0,
	Visible = true,
})
local fomoLabel = createElement("TextLabel", fomoBanner, {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	FontSize = Enum.FontSize.Size13,
	TextColor3 = Color3.fromRGB(255, 220, 150),
	Text = "LIMITED TIME: Halloween Trail & Pumpkin Flashlight — Available until Nov 15!",
})

-- ============================================================================
-- Quick Chat Wheel
-- ============================================================================
local chatWheel = createElement("Frame", screenGui, {
	Name = "QuickChatWheel",
	Size = UDim2.new(0, 160, 0, 160),
	Position = UDim2.new(0.5, -80, 0.5, -80),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.4,
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
})
local function setupQuickChat()
	local total = #SPC.QuickChat
	local radius = 65
	local center = 80
	for i, phrase in ipairs(SPC.QuickChat) do
		local angle = (2 * math.pi * (i - 1) / total) - math.pi / 2
		local x = center + radius * math.cos(angle)
		local y = center + radius * math.sin(angle)
		local btn = createElement("TextButton", chatWheel, {
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.new(0, x - 14, 0, y - 14),
			BackgroundColor3 = Color3.fromRGB(40, 40, 60),
			BorderColor3 = Color3.fromRGB(150, 150, 200),
			Font = Enum.Font.Gotham,
			FontSize = Enum.FontSize.Size9,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Text = tostring(i),
		})
		btn.MouseButton1Click:Connect(function()
			local remotes = ReplicatedStorage:WaitForChild("ShadowRemotes")
			remotes.QuickChat:FireServer(phrase)
			chatWheel.Visible = false
		end)
	end
end
setupQuickChat()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Q then
		chatWheel.Visible = not chatWheel.Visible
	elseif input.KeyCode == Enum.KeyCode.Tab then
		storeOverlay.Visible = true
		buildShardShop()
		buildRobuxShop()
	elseif input.KeyCode == Enum.KeyCode.Escape then
		storeOverlay.Visible = false
		chatWheel.Visible = false
	end
end)

-- ============================================================================
-- Remote Event Handlers
-- ============================================================================
local remotes = ReplicatedStorage:WaitForChild("ShadowRemotes")

remotes.ProfileLoaded.OnClientEvent:Connect(function(profile)
	shardLabel.Text = "Shards: " .. (profile.Shards or 0)
	repLabel.Text = string.format("Rep: %d | XP: %d", profile.Rep or 0, profile.XP or 0)
	floorLabel.Text = string.format("Floor: %d/8 | Door: %d/100", profile.CurrentFloor or 1, (profile.DoorsOpened or 0) % 100)
	streakLabel.Text = "Streak: " .. (profile.DailyStreak or 0) .. " days"
end)

remotes.StatsUpdate.OnClientEvent:Connect(function(stats)
	shardLabel.Text = "Shards: " .. (stats.Shards or 0)
	repLabel.Text = string.format("Rep: %d | XP: %d", stats.Rep or 0, stats.XP or 0)
	floorLabel.Text = string.format("Floor: %d/8 | Door: %d/100", stats.CurrentFloor or 1, (stats.DoorsOpened or 0) % 100)
end)

remotes.DailyReward.OnClientEvent:Connect(function(dayIndex, reward, streak)
	dailyPopup.Visible = true
	dailyInfo.Text = string.format("Day %d: +%d Shards, +%d XP\nStreak: %d days!", dayIndex, reward.Shards or 0, reward.XP or 0, streak)
	dailyClaimBtn.Text = "Claimed!"
end)

remotes.AchievementUnlocked.OnClientEvent:Connect(function(achId, achName, reward)
	achPopup.Visible = true
	achLabel.Text = string.format("Achievement: %s!\n+%d Shards, +%d XP", achName, reward.Shards or 0, reward.XP or 0)
	delay(4, function() achPopup.Visible = false end)
end)

remotes.NearMiss.OnClientEvent:Connect(function(msg)
	nearMissPopup.Visible = true
	nearMissLabel.Text = msg
	delay(3, function() nearMissPopup.Visible = false end)
end)

remotes.BonusReward.OnClientEvent:Connect(function(title, desc)
	bonusPopup.Visible = true
	bonusLabel.Text = title .. "\n" .. desc
	delay(2.5, function() bonusPopup.Visible = false end)
end)

remotes.PurchaseGranted.OnClientEvent:Connect(function(productKey, extra)
	-- Show purchase confirmation
	bonusPopup.Visible = true
	bonusLabel.Text = productKey .. " purchased!\n" .. (extra or "")
	delay(3, function() bonusPopup.Visible = false end)
end)

remotes.QuickChat.OnClientEvent:Connect(function(playerName, phrase)
	-- Show chat bubble (simplified)
	print(playerName .. ": " .. phrase)
end)

-- ============================================================================
-- Gameplay Remote Handlers
-- ============================================================================
remotes:WaitForChild("GameStart").OnClientEvent:Connect(function(floor, roomCount)
	floorLabel.Text = string.format("Floor: %d/8 | Door: 0/%d", floor, roomCount)
	healthLabel.Text = "HP: 100/100 | Stamina: 100"
	progressBarFill.Size = UDim2.new(0, 0, 1, 0)
end)

remotes:WaitForChild("GameEnd").OnClientEvent:Connect(function(reason, data)
	if reason == "Death" then
		healthLabel.Text = "HP: 0/100 | DEAD"
		healthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
	elseif reason == "Escape" then
		healthLabel.Text = "ESCAPED!"
		healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	elseif reason == "TimeUp" then
		healthLabel.Text = "TIME'S UP!"
	end
end)

remotes:WaitForChild("RoomUpdate").OnClientEvent:Connect(function(roomIndex, playerName)
	floorLabel.Text = string.format("Floor: %d/8 | Door: %d/%d", 1, roomIndex, 10)
	local progress = roomIndex / 10
	progressBarFill.Size = UDim2.new(progress, 0, 1, 0)
end)

remotes:WaitForChild("HealthUpdate").OnClientEvent:Connect(function(health, maxHealth)
	healthLabel.Text = string.format("HP: %d/%d | Stamina: 100", health, maxHealth)
	if health < 30 then
		healthLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	elseif health < 60 then
		healthLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
	else
		healthLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end)

remotes:WaitForChild("EntityDamage").OnClientEvent:Connect(function(damage)
	-- Flash screen red
	print("Took " .. damage .. " damage!")
end)

-- ============================================================================
-- Store overlay close on outside click
-- ============================================================================
storeOverlay.MouseButton1Click:Connect(function()
	storeOverlay.Visible = false
end)

-- ============================================================================
-- Initialize
-- ============================================================================
buildShardShop()
buildRobuxShop()

-- Request profile load (server sends ProfileLoaded)
local remotes2 = ReplicatedStorage:WaitForChild("ShadowRemotes")
remotes2.ClaimDaily:FireServer()

return {}
