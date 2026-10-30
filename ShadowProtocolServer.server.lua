-- ShadowProtocolServer.server.lua — Script (ServerScriptService)
-- Shadow Protocol server: game loop, entities, economy, ProcessReceipt,
-- pass grants, daily rewards, achievements, psychology hooks.
-- Server-authoritative — clients only send intents.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SPC = require(ReplicatedStorage:WaitForChild("ShadowProtocolConfig"))

-- ============================================================================
-- Rate Limiting (security)
-- ============================================================================
local rateLimits = {}
local RATE_LIMIT_WINDOW = 1
local RATE_LIMIT_MAX = 10

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

-- Forward declarations
local saveProfile
local loadProfile

-- ============================================================================
-- DataStore (persistence)
-- ============================================================================
local ProfileStore = DataStoreService:GetDataStore("ShadowProtocol_Profile")

local sessions = {}  -- [player] = { Profile = {...}, Receipts = {}, ActiveBoosts = {} }

local function defaultProfile(player)
	return {
		UserId = player.UserId,
		Shards = 0,
		Rep = 0,
		RepTier = 1,
		XP = 0,
		FloorReached = 0,
		CurrentFloor = 1,
		DoorsOpened = 0,
		EntitiesSurvived = 0,
		Receipts = {},
		ActivePasses = {},
		OwnedGear = {},
		OwnedTrails = {},
		OwnedColors = {},
		OwnedEmotes = {},
		ActiveBoosts = {},
		DailyStreak = 0,
		LastLoginDate = 0,
		Achievements = {},
		Stats = {
			TotalEscapes = 0,
			TotalDeaths = 0,
			TotalPlayTime = 0,
			FastestFloor = 0,
			NoDamageFloors = 0,
		},
	}
end

-- ============================================================================
-- Receipt / Product mappings
-- ============================================================================
local PASS_IDS = SPC.PASS_IDS
local PRODUCT_IDS = SPC.PRODUCT_IDS

local function findProductKey(productId)
	if productId and productId ~= 0 then
		for k, id in pairs(PRODUCT_IDS) do
			if id == productId then return k end
		end
	end
	return nil
end

local function findPassKey(passId)
	if passId and passId ~= 0 then
		for k, id in pairs(PASS_IDS) do
			if id == passId then return k end
		end
	end
	return nil
end

-- ============================================================================
-- Grant product (repeatable developer product)
-- ============================================================================
local function grantProduct(profile, productKey)
	if not profile then return false end

	if productKey == "ReviveToken" then
		profile.ActiveBoosts.ReviveToken = (profile.ActiveBoosts.ReviveToken or 0) + 1
	elseif productKey == "EntityRepellent" then
		profile.ActiveBoosts.EntityRepellent = (profile.ActiveBoosts.EntityRepellent or 0) + 1
	elseif productKey == "LuckyCharm" then
		profile.ActiveBoosts.LuckyCharm = tick() + 3600  -- 1 run (~1h session)
	elseif productKey == "SpeedSurge" then
		profile.ActiveBoosts.SpeedSurge = tick() + 1800  -- 30 min
	elseif productKey == "BatteryPack" then
		profile.ActiveBoosts.BatteryPack = (profile.ActiveBoosts.BatteryPack or 0) + 1
	elseif productKey == "MysteryCrate" then
		-- Variable ratio reward: roll the loot table
		local table = SPC.LOOT_TABLES.MysteryCrate
		local roll = math.random(1, 100)
		local cumulative = 0
		for _, entry in ipairs(table) do
			if entry.Weight then
				cumulative = cumulative + entry.Weight
				if roll <= cumulative then
					-- Grant the item
					if entry.Item:find("Trail_") then
						profile.OwnedTrails[entry.Item] = true
					elseif entry.Item:find("Color_") then
						profile.OwnedColors[entry.Item] = true
					elseif entry.Item:find("Flashlight_") then
						profile.OwnedGear[entry.Item] = true
					end
					profile.LastCrateReward = entry.Item
					return true
				end
			end
		end
	elseif productKey == "XPBoost_Hour" then
		profile.ActiveBoosts.XPBoost = tick() + 3600
	elseif productKey == "CoinBoost_Hour" then
		profile.ActiveBoosts.CoinBoost = tick() + 3600
	elseif productKey == "DailyBooster" then
		profile.ActiveBoosts.DailyBooster = tick() + (7 * 24 * 3600)  -- 7 days
	else
		return false
	end
	return true
end

-- ============================================================================
-- ProcessReceipt — required for developer products
-- ============================================================================
local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local session = sessions[player]
	if not session then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = session.Profile

	-- idempotency: never grant the same receipt twice
	local receiptId = receiptInfo.PurchaseId
	if profile.Receipts[receiptId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local productKey = findProductKey(receiptInfo.ProductId)
	if not productKey then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Grant the product (idempotency already checked above)
	if grantProduct(profile, productKey) then
		profile.Receipts[receiptId] = true
		spawn(function() saveProfile(player) end)
		-- Notify client
		local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
		if remotes and remotes:FindFirstChild("PurchaseGranted") then
			remotes.PurchaseGranted:FireClient(player, productKey, profile.LastCrateReward)
		end
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end
MarketplaceService.ProcessReceipt = processReceipt

-- ============================================================================
-- Pass grants (one-time permanent privileges)
-- ============================================================================
local function grantPass(player, passKey)
	if not passKey then return end

	local profile = sessions[player] and sessions[player].Profile
	if not profile then return end

	if passKey == "ShadowSurvivor" then
		profile.ActivePasses.ShadowSurvivor = true
		-- Grant exclusive gear
		profile.OwnedTrails["Trail_VIP"] = true
		profile.OwnedGear["Flashlight_Shadow"] = true
	elseif passKey == "SkipQueue" then
		profile.ActivePasses.SkipQueue = true
	elseif passKey == "NightVision" then
		profile.ActivePasses.NightVision = true
	end
	saveProfile(player)
end

local function onPassPurchaseFinished(player, purchasedPassId, purchaseSuccess)
	local passKey = findPassKey(purchasedPassId)
	if purchaseSuccess and passKey then
		grantPass(player, passKey)
	end
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPassPurchaseFinished)

local function checkPasses(player)
	for passKey, passId in pairs(PASS_IDS) do
		if passId and passId ~= 0 then
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			if success and owns then
				grantPass(player, passKey)
			end
		end
	end
end

-- ============================================================================
-- PolicyService compliance (age / region filtering)
-- ============================================================================
local function policyCheck(player)
	local ok, policies = pcall(function()
		return PolicyService:GetPolicyForUserIdAsync(player.UserId)
	end)
	if not ok or not policies then return true end

	for _, policy in ipairs(policies) do
		if policy.Action == "EnablePaidRandomItems" then
			if policy.Value == false then
				return false
			end
		end
	end
	return true
end

-- Forward declaration for checkAchievements (defined later)
local checkAchievements

-- ============================================================================
-- Free Loop: rep tier grants + gear
-- ============================================================================
local function checkRepTier(profile)
	local tier = 1
	for i = #SPC.RepTiers, 1, -1 do
		if profile.Rep >= SPC.RepTiers[i].RepRequired then
			tier = SPC.RepTiers[i].Tier
			break
		end
	end

	if tier > profile.RepTier then
		profile.RepTier = tier
		for _, entry in ipairs(SPC.RepTiers) do
			if entry.Tier <= tier then
				for _, gearName in ipairs(entry.Gear) do
					if not profile.OwnedGear[gearName] then
						profile.OwnedGear[gearName] = true
					end
					local gearDef = SPC.Gear[gearName]
					if gearDef then
						if gearDef.Type == "trail" then
							profile.OwnedTrails[gearName] = true
						elseif gearDef.Type == "color" then
							profile.OwnedColors[gearName] = true
						elseif gearDef.Type == "flashlight" then
							profile.OwnedGear[gearName] = true
						end
					end
				end
			end
		end
		-- Check achievements
		checkAchievements(profile, "rep_tier", tier)
	end
end

-- ============================================================================
-- Multipliers
-- ============================================================================
local function getShardMultiplier(profile)
	local mult = 1.0
	if profile.ActivePasses.ShadowSurvivor then mult = mult * 1.25 end
	if profile.ActiveBoosts and profile.ActiveBoosts.CoinBoost and profile.ActiveBoosts.CoinBoost > tick() then
		mult = mult * 2.0
	end
	-- Daily streak bonus (Zeigarnik/commitment)
	if profile.DailyStreak and profile.DailyStreak > 0 then
		mult = mult * (1.0 + (profile.DailyStreak * SPC.Round.StreakBonusMultiplier))
	end
	-- Cap at 3x to prevent runaway
	mult = math.min(mult, 3.0)
	return mult
end

local function getXPBoostActive(profile)
	if profile.ActiveBoosts and profile.ActiveBoosts.XPBoost and profile.ActiveBoosts.XPBoost > tick() then
		return true
	end
	return false
end

local function getLuckyCharmActive(profile)
	if profile.ActiveBoosts and profile.ActiveBoosts.LuckyCharm and profile.ActiveBoosts.LuckyCharm > tick() then
		return true
	end
	return false
end

-- ============================================================================
-- Award floor clear (with psychology hooks)
-- ============================================================================
local function awardFloorClear(player, floorIndex, difficulty, timeTaken, damageTaken)
	local session = sessions[player]
	if not session then return end
	local profile = session.Profile

	-- XP
	local xp = SPC.Round.XPRewardPerFloor
	if getXPBoostActive(profile) then xp = xp * 2 end
	profile.XP = profile.XP + xp
	profile.Rep = profile.Rep + 1

	-- Shards
	local shards = SPC.Round.ShardRewardBase + (difficulty - 1) * SPC.Round.ShardRewardPerDifficulty
	shards = math.floor(shards * getShardMultiplier(profile))
	profile.Shards = profile.Shards + shards

	-- Track progress
	if floorIndex > profile.FloorReached then
		profile.FloorReached = floorIndex
	end
	profile.DoorsOpened = profile.DoorsOpened + (floorIndex * 10)  -- approx

	-- Stats
	profile.Stats.TotalEscapes = profile.Stats.TotalEscapes + 1
	if timeTaken and profile.Stats.FastestFloor == 0 or (timeTaken and timeTaken < profile.Stats.FastestFloor) then
		profile.Stats.FastestFloor = timeTaken or 0
	end
	if damageTaken == 0 then
		profile.Stats.NoDamageFloors = profile.Stats.NoDamageFloors + 1
		checkAchievements(profile, "no_damage", profile.Stats.NoDamageFloors)
	end

	checkRepTier(profile)

	-- Variable ratio reward (Skinner box — dopamine anticipation)
	if math.random() < SPC.Psychology.VariableRewards.FloorClearBonus.Chance then
		local bonusShards = SPC.Psychology.VariableRewards.FloorClearBonus.Amount[math.random(#SPC.Psychology.VariableRewards.FloorClearBonus.Amount)]
		profile.Shards = profile.Shards + bonusShards
		local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
		if remotes and remotes:FindFirstChild("BonusReward") then
			remotes.BonusReward:FireClient(player, "Floor Clear Bonus!", bonusShards .. " Shards")
		end
	end

	-- Achievement checks
	checkAchievements(profile, "floor_clear", floorIndex)
	checkAchievements(profile, "escape", profile.Stats.TotalEscapes)

	saveProfile(player)

	-- Notify client
	local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
	if remotes and remotes:FindFirstChild("FloorCleared") then
		remotes.FloorCleared:FireClient(player, floorIndex, shards, xp)
	end
end

-- ============================================================================
-- Entity encounter handling
-- ============================================================================
local function onEntityEncounter(player, entityName, survived)
	local session = sessions[player]
	if not session then return end
	local profile = session.Profile

	local entity = SPC.Entities[entityName]
	if not entity then return end

	if survived then
		profile.EntitiesSurvived = profile.EntitiesSurvived + 1
		-- Grant rewards
		if entity.RewardOnSurvive then
			if entity.RewardOnSurvive.Shards then
				local shards = entity.RewardOnSurvive.Shards
				if getLuckyCharmActive(profile) then shards = shards * 2 end
				profile.Shards = profile.Shards + shards
			end
			if entity.RewardOnSurvive.XP then
				profile.XP = profile.XP + entity.RewardOnSurvive.XP
			end
		end
		-- Variable ratio drop (Skinner box)
		if math.random() < SPC.Psychology.VariableRewards.EntityKillDrop.Chance then
			local items = SPC.Psychology.VariableRewards.EntityKillDrop.Items
			local item = items[math.random(#items)]
			if item == "Shards" then
				profile.Shards = profile.Shards + math.random(5, 25)
			elseif item == "Trail_Basic" then
				profile.OwnedTrails["Trail_Basic"] = true
			elseif item == "Color_Green" then
				profile.OwnedColors["Color_Green"] = true
			end
			local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
			if remotes and remotes:FindFirstChild("BonusReward") then
				remotes.BonusReward:FireClient(player, "Entity Drop!", item)
			end
		end
		checkAchievements(profile, "entity_survive", profile.EntitiesSurvived)
	else
		profile.Stats.TotalDeaths = profile.Stats.TotalDeaths + 1
	end

	saveProfile(player)
end

-- ============================================================================
-- Near-miss messaging (loss aversion)
-- ============================================================================
local function sendNearMiss(player, doorsAway)
	if doorsAway and doorsAway <= SPC.Round.NearMissThreshold then
		local msgTemplate = SPC.Psychology.NearMissMessages[math.random(#SPC.Psychology.NearMissMessages)]
		local msg = string.format(msgTemplate, doorsAway)
		local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
		if remotes and remotes:FindFirstChild("NearMiss") then
			remotes.NearMiss:FireClient(player, msg)
		end
	end
end

-- ============================================================================
-- Daily rewards (commitment/consistency, Zeigarnik)
-- ============================================================================
local function claimDailyReward(player)
	local session = sessions[player]
	if not session then return end
	local profile = session.Profile

	local now = os.time()
	local lastLogin = profile.LastLoginDate or 0
	local hoursSince = (now - lastLogin) / 3600

	if hoursSince < 20 then
		-- Too soon, already claimed today
		return false, "Already claimed today"
	end

	-- Streak logic
	if hoursSince <= SPC.Psychology.StreakResetHours then
		profile.DailyStreak = (profile.DailyStreak or 0) + 1
	else
		-- Streak broken
		profile.DailyStreak = 1
	end
	profile.LastLoginDate = now

	-- Determine reward (cycle through 7 days)
	local dayIndex = ((profile.DailyStreak - 1) % 7) + 1
	local reward = SPC.Psychology.DailyLoginRewards[dayIndex]
	if not reward then reward = SPC.Psychology.DailyLoginRewards[1] end

	-- Apply reward
	local shardMult = 1.0
	if profile.ActiveBoosts and profile.ActiveBoosts.DailyBooster and profile.ActiveBoosts.DailyBooster > tick() then
		shardMult = 2.0
	end

	if reward.Reward.Shards then
		profile.Shards = profile.Shards + math.floor(reward.Reward.Shards * shardMult)
	end
	if reward.Reward.XP then
		profile.XP = profile.XP + reward.Reward.XP
	end
	if reward.Reward.Item then
		if reward.Reward.Item:find("Trail_") then
			profile.OwnedTrails[reward.Reward.Item] = true
		elseif reward.Reward.Item:find("Color_") then
			profile.OwnedColors[reward.Reward.Item] = true
		end
	end

	-- Milestone check
	for _, milestone in ipairs(SPC.Psychology.StreakMilestoneDays) do
		if profile.DailyStreak == milestone then
			profile.Shards = profile.Shards + (milestone * 5)
			checkAchievements(profile, "streak", profile.DailyStreak)
		end
	end

	saveProfile(player)

	local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
	if remotes and remotes:FindFirstChild("DailyReward") then
		remotes.DailyReward:FireClient(player, dayIndex, reward.Reward, profile.DailyStreak)
	end

	return true, "Claimed day " .. dayIndex
end

-- ============================================================================
-- Achievements
-- ============================================================================
checkAchievements = function(profile, triggerType, value)
	if not profile.Achievements then profile.Achievements = {} end

	for _, ach in ipairs(SPC.Psychology.Achievements) do
		if not profile.Achievements[ach.Id] then
			local unlocked = false
			if triggerType == "floor_clear" and ach.Id == "first_escape" and value >= 1 then
				unlocked = true
			elseif triggerType == "entity_survive" and ach.Id == "survivor_10" and value >= 10 then
				unlocked = true
			elseif triggerType == "no_damage" and ach.Id == "no_damage" and value >= 1 then
				unlocked = true
			elseif triggerType == "streak" and ach.Id == "streak_7" and value >= 7 then
				unlocked = true
			elseif triggerType == "escape" and ach.Id == "speed_runner" then
				-- Handled separately with time check
			end

			-- Collection achievement
			if ach.Id == "collector_5" then
				local totalCosmetics = 0
				for _ in pairs(profile.OwnedTrails or {}) do totalCosmetics = totalCosmetics + 1 end
				for _ in pairs(profile.OwnedColors or {}) do totalCosmetics = totalCosmetics + 1 end
				for _ in pairs(profile.OwnedEmotes or {}) do totalCosmetics = totalCosmetics + 1 end
				if totalCosmetics >= 5 then unlocked = true end
			end

			if unlocked then
				profile.Achievements[ach.Id] = true
				if ach.Reward then
					if ach.Reward.Shards then profile.Shards = profile.Shards + ach.Reward.Shards end
					if ach.Reward.XP then profile.XP = profile.XP + ach.Reward.XP end
				end
				local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
				if remotes and remotes:FindFirstChild("AchievementUnlocked") then
					-- Find player from profile
					for p, s in pairs(sessions) do
						if s.Profile == profile then
							remotes.AchievementUnlocked:FireClient(p, ach.Id, ach.Name, ach.Reward)
							break
						end
					end
				end
			end
		end
	end
end

-- ============================================================================
-- Save / Load
-- ============================================================================
saveProfile = function(player)
	local session = sessions[player]
	if not session then return end
	-- Retry up to 3 times with exponential backoff
	local maxRetries = 3
	for attempt = 1, maxRetries do
		local success, err = pcall(function()
			ProfileStore:SetAsync("User_" .. player.UserId, session.Profile)
		end)
		if success then return end
		warn("Save attempt " .. attempt .. " failed for " .. player.UserId .. ": " .. tostring(err))
		if attempt < maxRetries then
			wait(2 ^ attempt)
		end
	end
	warn("All save attempts failed for " .. player.UserId)
end

-- Session locking: prevent concurrent loads
local sessionLocks = {}

loadProfile = function(player, callback)
	-- Wait for any existing lock
	local lockKey = "User_" .. player.UserId
	while sessionLocks[lockKey] do
		wait(0.1)
	end
	sessionLocks[lockKey] = true

	local success, data = pcall(function()
		return ProfileStore:GetAsync(lockKey)
	end)

	local profile
	if success and data then
		profile = data
		-- forward-fill new fields
		profile.Receipts = profile.Receipts or {}
		profile.ActivePasses = profile.ActivePasses or {}
		profile.OwnedGear = profile.OwnedGear or {}
		profile.OwnedTrails = profile.OwnedTrails or {}
		profile.OwnedColors = profile.OwnedColors or {}
		profile.OwnedEmotes = profile.OwnedEmotes or {}
		profile.ActiveBoosts = profile.ActiveBoosts or {}
		profile.Achievements = profile.Achievements or {}
		profile.Stats = profile.Stats or { TotalEscapes = 0, TotalDeaths = 0, TotalPlayTime = 0, FastestFloor = 0, NoDamageFloors = 0 }
		profile.DailyStreak = profile.DailyStreak or 0
		profile.LastLoginDate = profile.LastLoginDate or 0
		profile.DoorsOpened = profile.DoorsOpened or 0
		profile.EntitiesSurvived = profile.EntitiesSurvived or 0
	else
		profile = defaultProfile(player)
	end

	-- grant free gear on join
	for name, entry in pairs(SPC.FreeGearRep) do
		if not profile.OwnedGear[name] then
			profile.OwnedGear[name] = true
		end
	end

	sessions[player] = { Profile = profile, Receipts = {}, ActiveBoosts = profile.ActiveBoosts }
	checkRepTier(profile)

	-- Release lock
	sessionLocks[lockKey] = nil

	callback(player, profile)
end

-- ============================================================================
-- Player lifecycle
-- ============================================================================
local function onPlayerAdded(player)
	-- compliance check
	local allowed = policyCheck(player)
	if not allowed then
		player:SetAttribute("PaidRandomAllowed", false)
	else
		player:SetAttribute("PaidRandomAllowed", true)
	end

	loadProfile(player, function(plr, profile)
		checkPasses(plr)
		-- give starting gear
		for name, _ in pairs(SPC.FreeGearRep) do
			plr:SetAttribute("HasGear_" .. name, true)
		end
		-- Auto-claim daily reward
		claimDailyReward(plr)
		-- Notify client of profile load
		local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
		if remotes and remotes:FindFirstChild("ProfileLoaded") then
			remotes.ProfileLoaded:FireClient(plr, profile)
		end
	end)
end

local function onPlayerRemoving(player)
	if sessions[player] then
		saveProfile(player)
		sessions[player] = nil
	end
	rateLimits[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ============================================================================
-- Round loop / floor progression
-- ============================================================================
-- Track active floor timers
local floorTimers = {}  -- [player] = { startTime, floorIndex }

RunService.Heartbeat:Connect(function(dt)
	for _, session in pairs(sessions) do
		local boosts = session.ActiveBoosts
		if boosts then
			if boosts.CoilBoost and boosts.CoilBoost < tick() then boosts.CoilBoost = nil end
			if boosts.XPBoost and boosts.XPBoost < tick() then boosts.XPBoost = nil end
			if boosts.LuckyCharm and boosts.LuckyCharm < tick() then boosts.LuckyCharm = nil end
			if boosts.SpeedSurge and boosts.SpeedSurge < tick() then boosts.SpeedSurge = nil end
			if boosts.DailyBooster and boosts.DailyBooster < tick() then boosts.DailyBooster = nil end
		end
	end
end)

-- ============================================================================
-- Remote event handlers (client intents)
-- ============================================================================
-- These are set up after ReplicatedStorage remotes are created
local function setupRemotes()
	local remotes = ReplicatedStorage:FindFirstChild("ShadowRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "ShadowRemotes"
		remotes.Parent = ReplicatedStorage
	end

	-- Create remote events (SECURITY: FloorCleared and EntityEncounter are NOT
	-- client-triggerable — rewards are granted server-side only via BindableEvents)
	local remoteNames = {
		"PurchaseGranted", "ProfileLoaded",
		"DailyReward", "AchievementUnlocked", "NearMiss", "BonusReward",
		"StatsUpdate", "QuickChat", "BuyShardItem", "ClaimDaily",
	}
	for _, name in ipairs(remoteNames) do
		if not remotes:FindFirstChild(name) then
			local re = Instance.new("RemoteEvent")
			re.Name = name
			re.Parent = remotes
		end
	end

	-- SECURITY: FloorCleared and EntityEncounter are NOT client-triggerable.
	-- Rewards are granted server-side only via BindableEvents from GameManager.
	-- The GameManager fires floorClearedBindable when a player actually escapes.
	-- Entity encounters are tracked server-side by the EntityAI damage system.

	-- Buy shard item intent (with rate limiting and validation)
	remotes.BuyShardItem.OnServerEvent:Connect(function(player, itemName)
		if not checkRateLimit(player, "BuyShardItem") then return end
		if type(itemName) ~= "string" then return end

		local session = sessions[player]
		if not session then return end
		local profile = session.Profile

		-- Validate item exists in shop
		local found = false
		for _, item in ipairs(SPC.ShardShop) do
			if item.Name == itemName then
				found = true
				if profile.Shards >= item.Price then
					profile.Shards = profile.Shards - item.Price
					if item.Type == "trail" then
						profile.OwnedTrails[itemName] = true
					elseif item.Type == "color" then
						profile.OwnedColors[itemName] = true
					elseif item.Type == "flashlight" then
						profile.OwnedGear[itemName] = true
					elseif item.Type == "emote" then
						profile.OwnedEmotes[itemName] = true
					end
					checkAchievements(profile, "collect", nil)
					saveProfile(player)
					remotes.StatsUpdate:FireClient(player, {
						Shards = profile.Shards, Rep = profile.Rep, XP = profile.XP,
						FloorReached = profile.FloorReached,
					})
				end
				break
			end
		end
		if not found then
			warn("Player " .. player.Name .. " tried to buy unknown item: " .. itemName)
		end
	end)

	-- Quick chat broadcast (validated phrase only)
	remotes.QuickChat.OnServerEvent:Connect(function(player, phrase)
		if not checkRateLimit(player, "QuickChat") then return end
		if type(phrase) ~= "string" then return end

		-- Validate phrase is in allowed list
		local valid = false
		for _, p in ipairs(SPC.QuickChat) do
			if p == phrase then
				valid = true
				break
			end
		end
		if not valid then return end

		-- Broadcast to all players in same server
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player then
				remotes.QuickChat:FireClient(otherPlayer, player.Name, phrase)
			end
		end
	end)

	-- Claim daily reward
	remotes.ClaimDaily.OnServerEvent:Connect(function(player)
		if not checkRateLimit(player, "ClaimDaily") then return end
		claimDailyReward(player)
	end)
end

-- Wait for ReplicatedStorage to be ready, then set up remotes
spawn(function()
	wait(1)
	setupRemotes()
end)

-- ============================================================================
-- BindableEvent listeners (from GameManager)
-- ============================================================================
local ServerStorage = game:GetService("ServerStorage")

-- Floor cleared → award economy rewards
local floorClearedBindable = ServerStorage:WaitForChild("FloorClearedServer", 10)
if floorClearedBindable then
	floorClearedBindable.Event:Connect(function(player, floorIndex, difficulty, timeTaken, damageTaken)
		awardFloorClear(player, floorIndex, difficulty, timeTaken, damageTaken)
	end)
end

-- Entity encounter → grant rewards
local entityEncounterBindable = ServerStorage:WaitForChild("EntityEncounterServer", 10)
if entityEncounterBindable then
	entityEncounterBindable.Event:Connect(function(player, entityName, survived)
		onEntityEncounter(player, entityName, survived)
	end)
end

-- ============================================================================
-- Exports (for testing hooks)
-- ============================================================================
return {
	loadProfile = loadProfile,
	saveProfile = saveProfile,
	awardFloorClear = awardFloorClear,
	processReceipt = processReceipt,
	grantPass = grantPass,
	checkRepTier = checkRepTier,
	validateGearSources = SPC.validateGearSources,
	validateLootTables = SPC.validateLootTables,
	validateMonetization = SPC.validateMonetization,
	onEntityEncounter = onEntityEncounter,
	sendNearMiss = sendNearMiss,
	claimDailyReward = claimDailyReward,
	checkAchievements = checkAchievements,
	getShardMultiplier = getShardMultiplier,
	getXPBoostActive = getXPBoostActive,
	getLuckyCharmActive = getLuckyCharmActive,
	grantProduct = grantProduct,
	findProductKey = findProductKey,
	findPassKey = findPassKey,
	validateGearSources = SPC.validateGearSources,
	validateLootTables = SPC.validateLootTables,
	validateMonetization = SPC.validateMonetization,
	sessions = sessions,
	PASS_IDS = PASS_IDS,
	PRODUCT_IDS = PRODUCT_IDS,
	SPC = SPC,
}
