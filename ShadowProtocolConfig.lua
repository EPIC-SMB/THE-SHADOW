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
