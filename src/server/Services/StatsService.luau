local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local CupService = {}
function CupService.initialize()
	Remotes.ToggleCafeOpen.OnServerEvent:Connect(function(player)
		GlobalState.toggleCafeOpen(tostring(player.UserId))
	end)
	Remotes.CompleteTutorial.OnServerEvent:Connect(function(player)
		GlobalState.completeTutorial(tostring(player.UserId))
	end)
end
return CupService
