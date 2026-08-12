--StatsService.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local AnalyticsService = game:GetService("AnalyticsService")
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

	Remotes.CompleteTutorial.OnServerEvent:Connect(function(player)
		GlobalState.completeTutorial(tostring(player.UserId))
	end)

	local maxStep = 17 -- The total number of steps in your tutorial

	Remotes.LogTutorialStep.OnServerEvent:Connect(function(player: Player, stepLevel: number, stepName: string)
		-- Exploit Protection: Ensure the step is a valid number within your funnel range
		if type(stepLevel) ~= "number" or stepLevel < 1 or stepLevel > maxStep then
			warn(`Invalid tutorial step {stepLevel} received from client {player.Name}.`)
			return
		end

		-- Log progression using the dedicated Onboarding Funnel API
		xpcall(function()
			AnalyticsService:LogOnboardingFunnelStepEvent(player, stepLevel, stepName)
		end, function(err)
			warn(`Tutorial Funnel Error: {err}`)
		end)

		-- Optional: Print in Studio just to verify it's working
		if RunService:IsStudio() then
			print(`[Analytics] {player.Name} completed tutorial step: {stepLevel} - {stepName}`)
		end
	end)
end
return StatsService
