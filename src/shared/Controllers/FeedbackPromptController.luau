local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")

local FeedbackPromptConfig = require(ReplicatedStorage.Shared.Configs.FeedbackPromptConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local FeedbackPromptController = {}

local isPrompting = false

function FeedbackPromptController.isStudio(): boolean
	return RunService:IsStudio()
end

function FeedbackPromptController.canAutoPrompt(stats): boolean
	if not FeedbackPromptConfig.Enabled or not FeedbackPromptConfig.AutoPromptEnabled then
		return false
	end
	if not stats or stats.TutorialCompleted ~= true then
		return false
	end
	if (stats.Level or 1) < FeedbackPromptConfig.RequiredLevel then
		return false
	end

	local lastPromptedAt = stats.FeedbackPromptedAt or 0
	return os.time() - lastPromptedAt >= FeedbackPromptConfig.CooldownSeconds
end

function FeedbackPromptController.request(): boolean
	if not FeedbackPromptConfig.Enabled then
		return false
	end

	if not RunService:IsClient() then
		return false
	end

	local player = Players.LocalPlayer
	if not player or isPrompting then
		return false
	end

	if RunService:IsStudio() then
		print("[Feedback] Native prompt is only available in published games.")
		return false
	end

	isPrompting = true

	task.spawn(function()
		local ok, err = pcall(function()
			SocialService:PromptFeedbackSubmissionAsync()
		end)

		isPrompting = false

		if not ok then
			warn(`[Feedback] Prompt failed: {err}`)
			return
		end

		pcall(function()
			Remotes.MarkFeedbackPrompted:FireServer()
		end)
	end)

	return true
end

return FeedbackPromptController
