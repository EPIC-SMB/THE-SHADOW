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

-- Auto-start game after first player joins (MVP behavior)
local gameStarted = false
Players.PlayerAdded:Connect(function(player)
	if not gameStarted and #Players:GetPlayers() >= 1 then
		gameStarted = true
		task.delay(5, function()
			if GameManager.GetPhase() == "Lobby" then
				GameManager.StartRound()
			end
		end)
	end
end)

-- Start if players already present (Studio testing)
if #Players:GetPlayers() >= 1 then
	gameStarted = true
	task.delay(5, function()
		if GameManager.GetPhase() == "Lobby" then
			GameManager.StartRound()
		end
	end)
end

print("Shadow Protocol Game Loop started")