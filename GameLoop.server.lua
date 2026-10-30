-- GameLoop.server.lua — Script (ServerScriptService)
-- Entry point for Shadow Protocol game loop.
-- Requires the GameManager ModuleScript from ReplicatedStorage and starts the game.
-- This is the ONLY script that should auto-run game logic on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load modules
local GameManager = require(ReplicatedStorage:WaitForChild("ShadowProtocolGameManager"))
local SPC = require(ReplicatedStorage:WaitForChild("ShadowProtocolConfig"))

-- Initialize game manager (sets up remotes, player lifecycle, entity AI wiring)
GameManager.Init()

-- G1.1 FIX: Auto-start game when players are present and in Lobby phase.
-- Handles initial start AND restarts after all players leave and rejoin.
-- The GameManager.EndRound() now also auto-starts after the intermission.
local function tryAutoStart()
	local gameState = GameManager.GetGameState()
	local hasPlayers = (#Players:GetPlayers() >= 1)
	if not hasPlayers then
		for _ in pairs(gameState.Players) do hasPlayers = true; break end
	end
	if hasPlayers and GameManager.GetPhase() == "Lobby" then
		task.delay(5, function()
			local gs = GameManager.GetGameState()
			local hp = (#Players:GetPlayers() >= 1)
			if not hp then
				for _ in pairs(gs.Players) do hp = true; break end
			end
			if hp and GameManager.GetPhase() == "Lobby" then
				GameManager.StartRound()
			end
		end)
	end
end

Players.PlayerAdded:Connect(function(player)
	tryAutoStart()
end)

-- Start if players already present (Studio testing)
tryAutoStart()

print("Shadow Protocol Game Loop started")