local InstanceMT = {}
InstanceMT.__index = InstanceMT
function InstanceMT:FindFirstChild(name) return self._children[name] end
function InstanceMT:WaitForChild(name) return self._children[name] end
function InstanceMT:GetChildren()
	local t = {}
	for _, v in pairs(self._children) do table.insert(t, v) end
	return t
end
function InstanceMT:SetAttribute(name, value) self._attributes[name] = value end
function InstanceMT:GetAttribute(name) return self._attributes[name] end
Instance = {}
function Instance.new(className, parent)
	local self = setmetatable({}, InstanceMT)
	self._className = className or "Instance"
	self._children = {}
	self._props = {}
	self._attributes = {}
	self._parent = parent
	self.Name = className
	if parent then parent._children[className] = self end
	return self
end
local services = {}
game = {}
game.GetService = function(name)
	if not services[name] then
		local svc = {
			Name = name, ClassName = "Service", _children = {}, _props = {}, _attributes = {},
			FindFirstChild = function(self, n) return self._children[n] end,
			WaitForChild = function(self, n) return self._children[n] end,
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
Enum = { ProductPurchaseDecision = { NotProcessedYet = 0, PurchaseGranted = 1 } }
local Players = game:GetService("Players")
local playerObjects = {}
Players.GetPlayerByUserId = function(self, userId) return playerObjects[userId] end
Players.PlayerAdded = { Connect = function(self, fn) end }
Players.PlayerRemoving = { Connect = function(self, fn) end }
Players.LocalPlayer = nil
function Players:_createTestPlayer(userId)
	local p = { UserId = userId, Name = "TestPlayer_" .. userId, Parent = nil, Attributes = {}, Children = {},
		SetAttribute = function(self, n, v) self.Attributes[n] = v end,
		GetAttribute = function(self, n) return self.Attributes[n] end,
		FindFirstChild = function() return nil end, WaitForChild = function() return nil end }
	playerObjects[userId] = p
	return p
end
Players.GetPlayers = function() return {} end
local MarketplaceService = game:GetService("MarketplaceService")
MarketplaceService.ProcessReceipt = nil
MarketplaceService.PromptGamePassPurchaseFinished = { Connect = function(self, fn) _marketplace_connect_pass = fn end }
MarketplaceService.UserOwnsGamePassAsync = function(self, userId, passId) return false end
MarketplaceService.PromptGamePassPurchase = function(player, passId) end
MarketplaceService.PromptProductPurchase = function(player, productId) end
local PolicyService = game:GetService("PolicyService")
PolicyService.GetPolicyForUserIdAsync = function(self, userId)
	return { { Action = "EnablePaidRandomItems", Hours = 2, Value = true } }
end
local DataStoreService = game:GetService("DataStoreService")
local storage = {}
DataStoreService.GetDataStore = function(self, name)
	return { GetAsync = function(_, key) return nil end, SetAsync = function(_, key, value) storage[key] = value end }
end
local RunService = game:GetService("RunService")
local heartbeatHandlers = {}
RunService.Heartbeat = { Connect = function(self, fn) table.insert(heartbeatHandlers, fn) end }
function _fireHeartbeat(dt) for _, fn in ipairs(heartbeatHandlers) do fn(dt) end end
local ReplicatedStorage = game:GetService("ReplicatedStorage")
Color3 = { fromRGB = function(r, g, b) return {r=r, g=g, b=b, type="Color3"} end }
Vector3 = { new = function(x, y, z) return {x = x or 0, y = y or 0, z = z or 0} end }
TweenService = { Create = function(self, obj, info, props) return { Play = function() end } end }
UserInputService = {}

-- tick stub (Roblox global)
tick = function()
	return os.clock() * 1000  -- approximate, good enough for tests
end

-- os.time is already available in Lua

-- spawn stub (Roblox global)
spawn = function(fn, ...)
	if type(fn) == "function" then
		-- Run synchronously in test environment
		local ok, err = pcall(fn, ...)
		if not ok then
			-- Don't error on spawn failures in test
		end
	end
end

-- wait stub
wait = function(t)
	-- No-op in test environment
	return t or 0
end

-- task stub
task = {
	spawn = function(fn, ...) spawn(fn, ...) end,
	wait = function(t) return wait(t) end,
	defer = function(fn, ...) spawn(fn, ...) end,
	delay = function(t, fn, ...) spawn(fn, ...) end,
}

print("Stub environment loaded")


local configSource = [=[
-- ShadowProtocolConfig.lua — ModuleScript (ReplicatedStorage)
-- Shadow Protocol: horror survival game with psychology-driven engagement
-- and Robux microtransactions. All balance, odds, prices, and compliance
-- live here so tuning never touches a script.

local SPC = {}

-- ============================================================================
-- Maturity & Compliance (mirrors Creator Dashboard questionnaire)
-- ============================================================================
SPC.Maturity = {
	AgeForUpload = false,        -- No UGC uploads — no moderation surface
	FreeTextChat = false,        -- Quick chat only (fixed phrases)
	MaxImbalance = false,        -- No pay-to-win — paid = convenience + cosmetics
	ModeratedAssets = false,     -- No external assets
	ContentRating = "Moderate",  -- Mild-moderate horror, jump scares, no gore
}

-- ============================================================================
-- Robux Monetization IDs (set real IDs in Creator Dashboard; 0 = pending)
-- ============================================================================
SPC.PASS_IDS = {
	ShadowSurvivor = 0,   -- One-time: +1 life/revive per run, exclusive flashlight, VIP lobby
	SkipQueue      = 0,   -- One-time: always join instantly
	NightVision    = 0,   -- One-time: permanent night-vision toggle (QoL)
}

SPC.PRODUCT_IDS = {
	ReviveToken      = 0,   -- Repeatable: revive on death, keep progress
	EntityRepellent  = 0,   -- Repeatable: shield against one entity hit
	LuckyCharm      = 0,   -- Repeatable: boost drop rates for 1 run
	SpeedSurge      = 0,   -- Repeatable: +50% movement speed for 1 run
	BatteryPack     = 0,   -- Repeatable: refill flashlight battery
	MysteryCrate    = 0,   -- Repeatable: random cosmetic (variable ratio)
	XPBoost_Hour    = 0,   -- Repeatable: 2x XP for 1 real hour
	CoinBoost_Hour  = 0,   -- Repeatable: 2x Shards for 1 real hour
	DailyBooster    = 0,   -- Repeatable: 2x daily rewards for 7 days
}

-- ============================================================================
-- Free Currency & Economy
-- ============================================================================
SPC.FreeCurrency = {
	Name = "Shards",
	NameLower = "shards",
	StartingAmount = 0,
	SinkItems = {
		"Trail_Basic", "Color_Red", "Color_Blue", "Flashlight_Silver", "Emote_Wave",
	},
}

-- Rep (player level) unlocks — at least one real gameplay effect per tier
SPC.RepTiers = {
	{ Tier = 1, RepRequired = 0,   Gear = { "Flashlight_Basic" },   Source = "rep" },
	{ Tier = 2, RepRequired = 5,   Gear = { "SprintBoost_Free" },   Source = "rep" },
	{ Tier = 3, RepRequired = 12,  Gear = { "Trail_Basic" },        Source = "rep" },
	{ Tier = 4, RepRequired = 20,  Gear = { "Color_Red" },          Source = "rep" },
	{ Tier = 5, RepRequired = 30,  Gear = { "Color_Blue" },         Source = "rep" },
	{ Tier = 6, RepRequired = 45,  Gear = { "SprintBoost_Adv" },    Source = "rep" },
	{ Tier = 7, RepRequired = 65,  Gear = { "Flashlight_Gold" },    Source = "rep" },
	{ Tier = 8, RepRequired = 90,  Gear = { "Trail_Fire" },         Source = "rep" },
}

SPC.FreeGearRep = {
	Flashlight_Basic = { Tier = 1, Type = "flashlight", Power = 1.0, Source = "rep" },
	SprintBoost_Free = { Tier = 2, Type = "speed",      Power = 1.2, Source = "rep" },
	Trail_Basic      = { Tier = 3, Type = "trail",      Power = 0,   Source = "rep" },
	Color_Red        = { Tier = 4, Type = "color",      Power = 0,   Source = "rep" },
	Color_Blue       = { Tier = 5, Type = "color",      Power = 0,   Source = "rep" },
	SprintBoost_Adv  = { Tier = 6, Type = "speed",      Power = 1.4, Source = "rep" },
	Flashlight_Gold  = { Tier = 7, Type = "flashlight", Power = 1.3, Source = "rep" },
	Trail_Fire       = { Tier = 8, Type = "trail",      Power = 0,   Source = "rep" },
}

-- Robux-only gear: cosmetics/convenience, NEVER core progression (no pay-to-win)
SPC.RobuxOnlyGear = {
	Trail_VIP        = { Tier = 0, Type = "trail",      Power = 0, Source = "robux", Pass = "ShadowSurvivor" },
	Trail_Legend     = { Tier = 0, Type = "trail",      Power = 0, Source = "robux", Product = "MysteryCrate" },
	Flashlight_Shadow= { Tier = 0, Type = "flashlight", Power = 1.1, Source = "robux", Pass = "ShadowSurvivor" },
	Trail_Rainbow    = { Tier = 0, Type = "trail",      Power = 0, Source = "robux", Product = "MysteryCrate" },
	Trail_Shock      = { Tier = 0, Type = "trail",      Power = 0, Source = "robux", Product = "MysteryCrate" },
	Trail_Ice        = { Tier = 0, Type = "trail",      Power = 0, Source = "robux", Product = "MysteryCrate" },
}

SPC.Gear = {}
for name, entry in pairs(SPC.FreeGearRep) do SPC.Gear[name] = entry end
for name, entry in pairs(SPC.RobuxOnlyGear) do SPC.Gear[name] = entry end

-- ============================================================================
-- Shard Shop (free currency sink) — at least one item per tier
-- ============================================================================
SPC.ShardShop = {
	{ Name = "Trail_Basic",     Price = 50,  Type = "trail",      Source = "shards" },
	{ Name = "Color_Red",       Price = 30,  Type = "color",      Source = "shards" },
	{ Name = "Color_Blue",      Price = 30,  Type = "color",      Source = "shards" },
	{ Name = "Flashlight_Silver", Price = 120, Type = "flashlight", Source = "shards" },
	{ Name = "Emote_Wave",      Price = 80,  Type = "emote",      Source = "shards" },
	{ Name = "Trail_Fire",      Price = 250, Type = "trail",      Source = "shards" },
	{ Name = "Color_Green",     Price = 45,  Type = "color",      Source = "shards" },
	{ Name = "Emote_Point",     Price = 60,  Type = "emote",      Source = "shards" },
}

-- ============================================================================
-- Loot Tables (paid random — must disclose odds summing to 100)
-- ============================================================================
SPC.LOOT_TABLES = {
	MysteryCrate = {
		{ Item = "Trail_Legend",  Weight = 35, DisplayPct = 35 },
		{ Item = "Trail_Rainbow", Weight = 25, DisplayPct = 25 },
		{ Item = "Trail_Shock",   Weight = 20, DisplayPct = 20 },
		{ Item = "Trail_Ice",     Weight = 15, DisplayPct = 15 },
		{ Item = "Trail_VIP",     Weight = 5,  DisplayPct = 5  },
		DisclosedIn = { "StoreTab", "OddsPanel" },
	},
}

-- ============================================================================
-- Entity Definitions (psychology: fear, tension, learning, near-miss)
-- ============================================================================
SPC.Entities = {
	Watcher = {
		Name = "The Watcher",
		Tell = "purple glow in dark rooms",
		Action = "look away (down) to survive",
		Damage = 100,
		CanKill = true,
		SpawnChance = 0.15,
		RewardOnSurvive = { Shards = 5, XP = 1 },
	},
	Rush = {
		Name = "Rush",
		Tell = "lights flicker + rushing wind",
		Action = "hide in closet/bed immediately",
		Damage = 100,
		CanKill = true,
		SpawnChance = 0.20,
		RewardOnSurvive = { Shards = 8, XP = 2 },
	},
	Ambush = {
		Name = "Ambush",
		Tell = "high-pitched distorted scream",
		Action = "hide, wait for rebounds, then exit",
		Damage = 100,
		CanKill = true,
		SpawnChance = 0.12,
		RewardOnSurvive = { Shards = 10, XP = 2 },
	},
	Figure = {
		Name = "The Figure",
		Tell = "heartbeat minigame when close",
		Action = "crouch-walk, avoid noise",
		Damage = 100,
		CanKill = true,
		SpawnChance = 1.0,  -- scripted at specific rooms
		ScriptedRooms = { 50, 100 },
		RewardOnSurvive = { Shards = 25, XP = 5 },
	},
	Seeker = {
		Name = "The Seeker",
		Tell = "black goo on walls + chase music",
		Action = "sprint, dodge obstacles",
		Damage = 100,
		CanKill = true,
		SpawnChance = 1.0,  -- scripted chase
		ScriptedRooms = { 25, 75 },
		RewardOnSurvive = { Shards = 30, XP = 8 },
	},
	Screech = {
		Name = "Screech",
		Tell = "whisper 'psst' in dark rooms",
		Action = "turn around quickly",
		Damage = 30,
		CanKill = false,
		SpawnChance = 0.25,
		RewardOnSurvive = { Shards = 3, XP = 1 },
	},
	Void = {
		Name = "The Void",
		Tell = "darkness creeping from behind",
		Action = "stay with group, don't lag",
		Damage = 50,
		CanKill = false,
		SpawnChance = 0.10,
		RewardOnSurvive = { Shards = 5, XP = 1 },
	},
	Mimic = {
		Name = "The Mimic",
		Tell = "player name flickers slightly",
		Action = "verify player identity before approaching",
		Damage = 80,
		CanKill = true,
		SpawnChance = 0.08,
		RewardOnSurvive = { Shards = 15, XP = 3 },
	},
}

-- ============================================================================
-- Floor / Room Configuration
-- ============================================================================
SPC.Floors = {
	{ Name = "Reception",     Theme = "office",    Difficulty = 1, Rooms = 10, EntityMultiplier = 0.5 },
	{ Name = "Ward A",        Theme = "hospital",  Difficulty = 2, Rooms = 15, EntityMultiplier = 0.7 },
	{ Name = "Ward B",        Theme = "hospital",  Difficulty = 3, Rooms = 20, EntityMultiplier = 0.9 },
	{ Name = "Laboratory",     Theme = "lab",      Difficulty = 4, Rooms = 25, EntityMultiplier = 1.1 },
	{ Name = "Sub-Basement",   Theme = "concrete", Difficulty = 5, Rooms = 30, EntityMultiplier = 1.3 },
	{ Name = "The Archives",  Theme = "library",   Difficulty = 6, Rooms = 35, EntityMultiplier = 1.5 },
	{ Name = "Containment",   Theme = "bunker",    Difficulty = 7, Rooms = 40, EntityMultiplier = 1.7 },
	{ Name = "The Core",      Theme = "reactor",   Difficulty = 8, Rooms = 50, EntityMultiplier = 2.0 },
}

SPC.Round = {
	TimeLimitPerFloor = 600,       -- seconds per floor
	ShardRewardBase = 15,          -- base shards per floor cleared
	ShardRewardPerDifficulty = 8,
	XPRewardPerFloor = 2,
	NearMissThreshold = 3,         -- "you were X doors away" when within this
	StreakBonusMultiplier = 0.1,   -- +10% per consecutive day
}

-- ============================================================================
-- Psychology Hooks (engagement mechanics)
-- ============================================================================
SPC.Psychology = {
	-- Daily login rewards (commitment/consistency, Zeigarnik)
	DailyLoginRewards = {
		{ Day = 1, Reward = { Shards = 10, XP = 2 } },
		{ Day = 2, Reward = { Shards = 15, XP = 3 } },
		{ Day = 3, Reward = { Shards = 20, XP = 5 } },
		{ Day = 4, Reward = { Shards = 25, XP = 5 } },
		{ Day = 5, Reward = { Shards = 30, XP = 8 } },
		{ Day = 6, Reward = { Shards = 40, XP = 10 } },
		{ Day = 7, Reward = { Shards = 75, XP = 20, Item = "Trail_Basic" } },  -- milestone
	},
	StreakResetHours = 36,         -- lose streak if no login within 36h
	StreakMilestoneDays = { 7, 14, 30, 60, 100 },

	-- Variable ratio rewards (Skinner box, dopamine anticipation)
	VariableRewards = {
		EntityKillDrop = { Chance = 0.05, Items = { "Trail_Basic", "Color_Green", "Emote_Point" } },
		FloorClearBonus = { Chance = 0.10, Items = { "Shards", "XP" }, Amount = { 5, 10, 25, 50 } },
		DailyChallenge = { Chance = 0.30, Items = { "Shards", "XP", "Trail_Basic" } },
	},

	-- Near-miss messaging (loss aversion)
	NearMissMessages = {
		"You were only %d doors away from escaping!",
		"So close! Just %d more rooms and you'd have made it.",
		"Almost there — %d doors stood between you and freedom.",
	},

	-- FOMO: limited-time cosmetics (must be truthful per guidelines)
	LimitedTimeItems = {
		{ Name = "Trail_Halloween", AvailableUntil = "2026-11-15", Price = 150, Source = "shards" },
		{ Name = "Flashlight_Pumpkin", AvailableUntil = "2026-11-15", Price = 200, Source = "shards" },
	},

	-- Social proof counters
	SocialProof = {
		ShowEscapesToday = true,
		ShowPlayersOnline = true,
		ShowTopEscaper = true,
	},

	-- Zeigarnik: progress display
	ProgressDisplay = {
		ShowDoorCounter = true,       -- "Door 47/100"
		ShowFloorProgress = true,     -- "Floor 3/8"
		ShowCompletionPct = true,     -- "47% complete"
	},

	-- Achievement system (variable rewards, collection drive)
	Achievements = {
		{ Id = "first_escape",    Name = "First Escape",    Desc = "Complete your first floor",         Reward = { Shards = 25, XP = 5 } },
		{ Id = "survivor_10",     Name = "Survivor",       Desc = "Survive 10 entity encounters",     Reward = { Shards = 50, XP = 10 } },
		{ Id = "speed_runner",    Name = "Speed Runner",    Desc = "Clear a floor in under 3 minutes", Reward = { Shards = 40, XP = 8 } },
		{ Id = "collector_5",     Name = "Collector",      Desc = "Own 5 cosmetic items",              Reward = { Shards = 30, XP = 5 } },
		{ Id = "streak_7",        Name = "Dedicated",      Desc = "Maintain a 7-day login streak",    Reward = { Shards = 75, XP = 20 } },
		{ Id = "no_damage",       Name = "Untouchable",    Desc = "Clear a floor without taking damage", Reward = { Shards = 60, XP = 15 } },
	},
}

-- ============================================================================
-- Robux Prices (mirrored from Product IDs)
-- ============================================================================
SPC.RobuxPrices = {
	ReviveToken     = 49,
	EntityRepellent = 29,
	LuckyCharm     = 79,
	SpeedSurge     = 39,
	BatteryPack    = 19,
	MysteryCrate   = 99,
	XPBoost_Hour   = 59,
	CoinBoost_Hour = 59,
	DailyBooster   = 199,
}

SPC.PassPrices = {
	ShadowSurvivor = 299,
	SkipQueue      = 99,
	NightVision    = 149,
}

-- ============================================================================
-- Quick Chat Phrases (no free-text chat — satisfies chat guidelines)
-- ============================================================================
SPC.QuickChat = {
	"gg", "nice!", "watch out!", "i got it!",
	"need help", "go go go!", "whoops", "you can do it!",
	"behind you!", "sorry!", "thanks!", "wow!",
	"hide!", "run!", "follow me", "stay close",
}

-- ============================================================================
-- Store UI: odds disclosure text (required for paid random items)
-- ============================================================================
SPC.OddsDisclosure = {
	Title = "Mystery Crate Odds",
	Body = "Each Mystery Crate contains one random cosmetic trail. "
		.. "Odds are disclosed below and do not change. "
		.. "Trail_Legend: 35% | Trail_Rainbow: 25% | Trail_Shock: 20% | "
		.. "Trail_Ice: 15% | Trail_VIP: 5%",
	Note = "Purchasing does not guarantee any specific item. "
		.. "All items are cosmetic and do not affect gameplay.",
}

-- ============================================================================
-- Validation helpers
-- ============================================================================
function SPC.validateGearSources()
	for name, entry in pairs(SPC.Gear) do
		assert(entry.Source, "Gear entry without Source: " .. name)
	end
	for name, entry in pairs(SPC.RobuxOnlyGear) do
		assert(entry.Source == "robux", "RobuxOnlyGear not robux source: " .. name)
	end
	for name, entry in pairs(SPC.FreeGearRep) do
		assert(entry.Source == "rep", "FreeGearRep not rep source: " .. name)
	end
end

function SPC.validateLootTables()
	for tableName, table in pairs(SPC.LOOT_TABLES) do
		local weightSum = 0
		local pctSum = 0
		for _, entry in ipairs(table) do
			if entry.Weight then weightSum = weightSum + entry.Weight end
			if entry.DisplayPct then pctSum = pctSum + entry.DisplayPct end
		end
		assert(weightSum == 100, "Loot table " .. tableName .. " weights sum to " .. weightSum .. " (expected 100)")
		assert(pctSum == 100, "Loot table " .. tableName .. " display pct sums to " .. pctSum .. " (expected 100)")
	end
end

function SPC.validateMonetization()
	-- Every product must have a price
	for key, price in pairs(SPC.RobuxPrices) do
		assert(price > 0, "Product " .. key .. " has no price")
	end
	for key, price in pairs(SPC.PassPrices) do
		assert(price > 0, "Pass " .. key .. " has no price")
	end
	-- Every product must have an ID entry
	for key, _ in pairs(SPC.RobuxPrices) do
		assert(SPC.PRODUCT_IDS[key], "Product " .. key .. " has no ID entry")
	end
	for key, _ in pairs(SPC.PassPrices) do
		assert(SPC.PASS_IDS[key], "Pass " .. key .. " has no ID entry")
	end
	-- Free currency sink must exist
	assert(#SPC.ShardShop > 0, "No free currency sink items")
	-- At least one free gear per tier up to max
	local maxTier = 0
	for _, t in ipairs(SPC.RepTiers) do
		if t.Tier > maxTier then maxTier = t.Tier end
	end
	assert(maxTier >= 5, "Not enough rep tiers for free progression")
end

return SPC
]=]

require = function(obj)
	if type(obj) == "string" then
		if obj:find("ShadowProtocolConfig") then
			return load(configSource, "config", "t", _G)()
		end
	end
	if type(obj) == "table" and obj._className == "ModuleScript" then
		local src = obj.Source
		if type(src) == "string" then
			return load(src, "module", "t", _G)()
		end
	end
	return nil
end

local RS = game:GetService("ReplicatedStorage")
local configInstance = Instance.new("ModuleScript")
configInstance.Name = "ShadowProtocolConfig"
configInstance.Source = configSource
RS._children["ShadowProtocolConfig"] = configInstance
RS.WaitForChild = function(self, name)
	if name == "ShadowProtocolConfig" then return configInstance end
	if name == "ShadowRemotes" then
		if not self._children["ShadowRemotes"] then
			local rem = Instance.new("Folder")
			rem.Name = "ShadowRemotes"
			rem._children = {}
			self._children["ShadowRemotes"] = rem
		end
		return self._children["ShadowRemotes"]
	end
	return self._children[name]
end

local SPC = load(configSource, "config", "t", _G)()
local serverSource = [=[
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

	local status = receiptInfo.ProductPurchaseDecision
	if status ~= 1 then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

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
	local success, err = pcall(function()
		ProfileStore:SetAsync("User_" .. player.UserId, session.Profile)
	end)
	if not success then
		warn("Failed to save profile for " .. player.UserId .. ": " .. tostring(err))
	end
end

loadProfile = function(player, callback)
	local success, data = pcall(function()
		return ProfileStore:GetAsync("User_" .. player.UserId)
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

	-- Create remote events
	local remoteNames = {
		"FloorCleared", "EntityEncounter", "PurchaseGranted", "ProfileLoaded",
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

	-- Floor cleared intent from client
	remotes.FloorCleared.OnServerEvent:Connect(function(player, floorIndex, difficulty, timeTaken, damageTaken)
		awardFloorClear(player, floorIndex, difficulty, timeTaken, damageTaken)
	end)

	-- Entity encounter intent
	remotes.EntityEncounter.OnServerEvent:Connect(function(player, entityName, survived)
		onEntityEncounter(player, entityName, survived)
	end)

	-- Buy shard item intent
	remotes.BuyShardItem.OnServerEvent:Connect(function(player, itemName)
		local session = sessions[player]
		if not session then return end
		local profile = session.Profile

		for _, item in ipairs(SPC.ShardShop) do
			if item.Name == itemName then
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
	end)

	-- Quick chat broadcast
	remotes.QuickChat.OnServerEvent:Connect(function(player, phrase)
		-- Validate phrase is in allowed list
		for _, p in ipairs(SPC.QuickChat) do
			if p == phrase then
				-- Broadcast to all players in same server
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= player then
						remotes.QuickChat:FireClient(otherPlayer, player.Name, phrase)
					end
				end
				break
			end
		end
	end)

	-- Claim daily reward
	remotes.ClaimDaily.OnServerEvent:Connect(function(player)
		claimDailyReward(player)
	end)
end

-- Wait for ReplicatedStorage to be ready, then set up remotes
spawn(function()
	wait(1)
	setupRemotes()
end)

-- ============================================================================
-- Exports (for testing hooks)
-- ============================================================================
]=]

local testHook = [[
__SHADOW_TEST__ = {
	loadProfile = loadProfile,
	saveProfile = saveProfile,
	awardFloorClear = awardFloorClear,
	processReceipt = processReceipt,
	grantPass = grantPass,
	checkRepTier = checkRepTier,
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
]]

local chunk, err = load(serverSource .. testHook, "ShadowServer", "t", _G)
if not chunk then
	error("Failed to load server: " .. tostring(err))
end
local ok, serverObj = pcall(chunk)
if not ok then
	error("Server chunk error: " .. tostring(serverObj))
end

local SHADOW = __SHADOW_TEST__

local tests_passed = 0
local tests_failed = 0

function assertEq(actual, expected, msg)
	if actual == expected then
		tests_passed = tests_passed + 1
		print("  PASS: " .. (msg or "assertion"))
	else
		tests_failed = tests_failed + 1
		print("  FAIL: " .. (msg or "assertion") .. " — expected " .. tostring(expected) .. ", got " .. tostring(actual))
	end
end

function assertTrue(cond, msg)
	if cond then
		tests_passed = tests_passed + 1
		print("  PASS: " .. (msg or "assertion"))
	else
		tests_failed = tests_failed + 1
		print("  FAIL: " .. (msg or "assertion"))
	end
end

print("\n--- Test 1: Gear source validation ---")
local vgOk, vgErr = pcall(SHADOW.validateGearSources)
print("  validateGearSources:", vgOk, vgErr)
assertTrue(vgOk, "validateGearSources runs without error")

print("\n--- Test 2: Loot table validation ---")
local vlOk, vlErr = pcall(SHADOW.validateLootTables)
print("  validateLootTables:", vlOk, vlErr)
assertTrue(vlOk, "validateLootTables runs without error")

print("\n--- Test 3: Monetization validation ---")
local vmOk, vmErr = pcall(SHADOW.validateMonetization)
print("  validateMonetization:", vmOk, vmErr)
assertTrue(vmOk, "validateMonetization runs without error")

print("\n--- Test 4: Free loop (rep tier grants) ---")
local player = game:GetService("Players"):_createTestPlayer(10001)
SHADOW.loadProfile(player, function(p, profile)
	profile.Rep = 15
	SHADOW.checkRepTier(profile)
	assertTrue(profile.RepTier >= 3, "Rep tier advances with Rep (got " .. profile.RepTier .. ")")
	assertTrue(profile.OwnedGear["SprintBoost_Free"] == true, "SprintBoost_Free granted")
	assertTrue(profile.OwnedGear["Trail_Basic"] == true, "Trail_Basic granted")
end)

print("\n--- Test 5: ProcessReceipt Open grant ---")
SHADOW.PRODUCT_IDS.ReviveToken = 88801
player = game:GetService("Players"):_createTestPlayer(10002)
SHADOW.loadProfile(player, function(p, profile)
	local beforeRevives = profile.ActiveBoosts.ReviveToken or 0
	local receipt = { PlayerId = 10002, ProductId = 88801, PurchaseId = "test-receipt-revive-1", ProductPurchaseDecision = 1 }
	local dbgPlayer = Players:GetPlayerByUserId(10002)
	print("  DEBUG: player from GetPlayerByUserId:", dbgPlayer ~= nil)
	print("  DEBUG: sessions[player] exists:", SHADOW.sessions[dbgPlayer] ~= nil)
	print("  DEBUG: PRODUCT_IDS.ReviveToken:", SHADOW.PRODUCT_IDS.ReviveToken)
	local result = SHADOW.processReceipt(receipt)
	print("  DEBUG: processReceipt result:", result)
	assertEq(1, result, "ProcessReceipt returns PurchaseGranted on Open")
	assertTrue((profile.ActiveBoosts.ReviveToken or 0) > beforeRevives, "Revive token granted")
end)

print("\n--- Test 6: Receipt idempotency ---")
player = game:GetService("Players"):_createTestPlayer(10003)
SHADOW.loadProfile(player, function(p, profile)
	local receipt = { PlayerId = 10003, ProductId = 88801, PurchaseId = "dup-receipt-1", ProductPurchaseDecision = 1 }
	SHADOW.processReceipt(receipt)
	local afterFirst = profile.ActiveBoosts.ReviveToken or 0
	SHADOW.processReceipt(receipt)
	local afterSecond = profile.ActiveBoosts.ReviveToken or 0
	assertEq(afterFirst, afterSecond, "Duplicate receipt does NOT add more (idempotent)")
end)

print("\n--- Test 7: Non-Open status handling ---")
player = game:GetService("Players"):_createTestPlayer(10004)
SHADOW.loadProfile(player, function(p, profile)
	SHADOW.PRODUCT_IDS.MysteryCrate = 88899
	local receipt = { PlayerId = 10004, ProductId = 88899, PurchaseId = "owned-receipt-1", ProductPurchaseDecision = 2 }
	local result = SHADOW.processReceipt(receipt)
	assertEq(1, result, "AlreadyOwned acknowledges")
	assertTrue(profile.LastCrateReward == nil, "No crate reward on non-Open status")
end)

print("\n--- Test 8: Unknown product rejection ---")
player = game:GetService("Players"):_createTestPlayer(10005)
SHADOW.loadProfile(player, function(p, profile)
	profile.Shards = 500
	local receipt = { PlayerId = 10005, ProductId = 999999, PurchaseId = "unknown-receipt-1", ProductPurchaseDecision = 1 }
	local result = SHADOW.processReceipt(receipt)
	assertEq(1, result, "Unknown product acknowledges")
	assertEq(500, profile.Shards, "Unknown product grants nothing")
end)

print("\n--- Test 9: Pass multiplier boosts grants ---")
player = game:GetService("Players"):_createTestPlayer(10006)
SHADOW.loadProfile(player, function(p, profile)
	profile.ActivePasses.ShadowSurvivor = true
	profile.Shards = 0
	SHADOW.awardFloorClear(player, 3, 3, 120, 0)
	local expectedMin = 30
	assertTrue(profile.Shards >= expectedMin, "ShadowSurvivor pass boosts shard earnings (got " .. profile.Shards .. ")")
	assertTrue(profile.Rep >= 1, "Rep increases on floor clear")
end)

print("\n--- Test 10: Robux-only gear exclusion ---")
local gearIsRobuxOnly = false
for name, entry in pairs(SHADOW.SPC.Gear) do
	if entry.Source == "robux" then
		gearIsRobuxOnly = true
		if SHADOW.SPC.FreeGearRep[name] then
			assertEq(false, true, "Robux gear " .. name .. " must not be in FreeGearRep")
		end
	end
end
assertTrue(gearIsRobuxOnly, "Robux-only gear exists in config")
local allRep = true
for name, entry in pairs(SHADOW.SPC.FreeGearRep) do
	if entry.Source ~= "rep" then allRep = false end
end
assertTrue(allRep, "All FreeGearRep entries have Source='rep'")
local shopHasSink = false
for _, item in ipairs(SHADOW.SPC.ShardShop) do
	if item.Source == "shards" then shopHasSink = true end
end
assertTrue(shopHasSink, "ShardShop has spendable items (free currency sink)")

print("\n--- Test 11: Loot table weights sum to 100 ---")
for tableName, table in pairs(SHADOW.SPC.LOOT_TABLES) do
	local weightSum = 0
	local pctSum = 0
	for _, entry in ipairs(table) do
		if entry.Weight then weightSum = weightSum + entry.Weight end
		if entry.DisplayPct then pctSum = pctSum + entry.DisplayPct end
	end
	assertEq(100, weightSum, "Loot table " .. tableName .. " weights sum to 100")
	assertEq(100, pctSum, "Loot table " .. tableName .. " display pct sums to 100")
end

print("\n--- Test 12: Free gear granted on join ---")
player = game:GetService("Players"):_createTestPlayer(10007)
SHADOW.loadProfile(player, function(p, profile)
	local allGranted = true
	for name, _ in pairs(SHADOW.SPC.FreeGearRep) do
		if not profile.OwnedGear[name] then
			allGranted = false
			print("    Missing on-join gear: " .. name)
		end
	end
	assertTrue(allGranted, "All FreeGearRep items granted on join")
end)

print("\n--- Test 13: Offline player receipt deferral ---")
local receipt = { PlayerId = 10099, ProductId = 88801, PurchaseId = "offline-receipt-1", ProductPurchaseDecision = 1 }
local result = SHADOW.processReceipt(receipt)
assertEq(0, result, "Offline player receipt returns NotProcessedYet (0)")

print("\n--- Test 14: Active boost changes grant amount ---")
player = game:GetService("Players"):_createTestPlayer(10008)
SHADOW.loadProfile(player, function(p, profile)
	profile.ActiveBoosts.CoinBoost = os.time() + 3600
	local mult = SHADOW.getShardMultiplier(profile)
	assertTrue(mult >= 2.0, "Active CoinBoost doubles multiplier (got " .. mult .. ")")
end)

print("\n--- Test 15: Daily reward system ---")
player = game:GetService("Players"):_createTestPlayer(10009)
SHADOW.loadProfile(player, function(p, profile)
	profile.LastLoginDate = 0
	profile.DailyStreak = 0
	local ok, msg = SHADOW.claimDailyReward(player)
	assertTrue(ok == true, "Daily reward claimed successfully")
	assertTrue(profile.DailyStreak >= 1, "Streak incremented (got " .. profile.DailyStreak .. ")")
	assertTrue(profile.Shards > 0, "Shards granted from daily reward (got " .. profile.Shards .. ")")
	local ok2, msg2 = SHADOW.claimDailyReward(player)
	assertTrue(ok2 == false, "Second claim too soon rejected")
end)

print("\n--- Test 16: Achievement system ---")
player = game:GetService("Players"):_createTestPlayer(10010)
SHADOW.loadProfile(player, function(p, profile)
	profile.Shards = 0
	SHADOW.checkAchievements(profile, "floor_clear", 1)
	assertTrue(profile.Achievements["first_escape"] == true, "first_escape achievement unlocked")
	assertTrue(profile.Shards > 0, "Achievement reward granted (got " .. profile.Shards .. ")")
end)

print("\n--- Test 17: Entity encounter rewards ---")
player = game:GetService("Players"):_createTestPlayer(10011)
SHADOW.loadProfile(player, function(p, profile)
	profile.Shards = 0
	local beforeShards = profile.Shards
	SHADOW.onEntityEncounter(player, "Watcher", true)
	assertTrue(profile.Shards > beforeShards, "Entity survival grants shards (got " .. profile.Shards .. ")")
	assertTrue(profile.EntitiesSurvived >= 1, "EntitiesSurvived incremented")
end)

print("\n--- Test 18: Lucky charm doubles entity rewards ---")
player = game:GetService("Players"):_createTestPlayer(10012)
SHADOW.loadProfile(player, function(p, profile)
	profile.Shards = 0
	profile.ActiveBoosts.LuckyCharm = os.time() + 3600
	local before = profile.Shards
	SHADOW.onEntityEncounter(player, "Watcher", true)
	assertTrue(profile.Shards >= before + 5, "Lucky charm boosts entity rewards (got " .. profile.Shards .. ")")
end)

print("\n--- Test 19: Near-miss logic ---")
player = game:GetService("Players"):_createTestPlayer(10013)
SHADOW.loadProfile(player, function(p, profile)
	local ok = pcall(function() SHADOW.sendNearMiss(player, 2) end)
	assertTrue(ok, "sendNearMiss runs without error")
end)

print("\n--- Test 20: Mystery crate grants an item ---")
SHADOW.PRODUCT_IDS.MysteryCrate = 88899
player = game:GetService("Players"):_createTestPlayer(10014)
SHADOW.loadProfile(player, function(p, profile)
	local receipt = { PlayerId = 10014, ProductId = 88899, PurchaseId = "crate-receipt-1", ProductPurchaseDecision = 1 }
	SHADOW.processReceipt(receipt)
	assertTrue(profile.LastCrateReward ~= nil, "Mystery crate granted an item: " .. tostring(profile.LastCrateReward))
end)

print("\n--- Test 21: Streak bonus multiplier ---")
player = game:GetService("Players"):_createTestPlayer(10017)
SHADOW.loadProfile(player, function(p, profile)
	profile.DailyStreak = 5
	local mult = SHADOW.getShardMultiplier(profile)
	assertTrue(mult >= 1.5, "Streak bonus increases multiplier (got " .. mult .. ")")
end)

print("\n--- Test 22: Near-miss threshold config ---")
assertTrue(SHADOW.SPC.Round.NearMissThreshold == 3, "Near-miss threshold is 3 doors")
assertTrue(#SHADOW.SPC.Psychology.NearMissMessages > 0, "Near-miss messages exist")

print("\n--- Test 23: Quick chat phrases count ---")
assertTrue(#SHADOW.SPC.QuickChat >= 12, "At least 12 quick chat phrases (got " .. #SHADOW.SPC.QuickChat .. ")")

print("\n--- Test 24: Entity definitions complete ---")
local entityCount = 0
for _ in pairs(SHADOW.SPC.Entities) do entityCount = entityCount + 1 end
assertTrue(entityCount >= 8, "At least 8 entity types (got " .. entityCount .. ")")

print("\n--- Test 25: Floor definitions complete ---")
assertTrue(#SHADOW.SPC.Floors >= 8, "At least 8 floors (got " .. #SHADOW.SPC.Floors .. ")")

print("\n========================================")
print("Tests passed: " .. tests_passed)
print("Tests failed: " .. tests_failed)
print("========================================")
if tests_failed > 0 then
	os.exit(1)
end
