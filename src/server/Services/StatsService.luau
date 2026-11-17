--StatsService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local StatsService = {}
function StatsService.initialize()
	Remotes.ToggleCafeOpen.OnServerEvent:Connect(function(player)
		GlobalState.toggleCafeOpen(tostring(player.UserId))
	end)
	Remotes.ToggleSfx.OnServerEvent:Connect(function(player)
		GlobalState.toggleSfx(tostring(player.UserId))
	end)
	Remotes.ToggleMusic.OnServerEvent:Connect(function(player)
		GlobalState.toggleMusic(tostring(player.UserId))
	end)
	Remotes.ToggleParticle.OnServerEvent:Connect(function(player)
		GlobalState.toggleParticle(tostring(player.UserId))
	end)
	Remotes.CompleteTutorial.OnServerEvent:Connect(function(player)
		GlobalState.completeTutorial(tostring(player.UserId))
	end)
	Remotes.SetSfxVolume.OnServerEvent:Connect(function(player, volume: number)
		if not volume then
			return
		end
		GlobalState.setSfxVolume(tostring(player.UserId), volume)
	end)
	Remotes.SetMusicVolume.OnServerEvent:Connect(function(player, volume: number)
		if not volume then
			return
		end
		GlobalState.setMusicVolume(tostring(player.UserId), volume)
	end)
	Remotes.Play.OnServerEvent:Connect(function(player)
		GlobalState.setPlayerPhase(tostring(player.UserId), "playing")
	end)
	Remotes.MarkFeedbackPrompted.OnServerEvent:Connect(function(player)
		GlobalState.markFeedbackPrompted(tostring(player.UserId), os.time())
	end)
end
return StatsService
