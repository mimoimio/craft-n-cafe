local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local React = require(ReplicatedStorage.Packages.React)
local useEffect = React.useEffect
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local player = Players.LocalPlayer
local playerId = tostring(player.UserId)

local MailboxListener = function(props: {})
	useEffect(function()
		-- Listen globally to ALL ProximityPrompts
		local conn = ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeredBy)
			if triggeredBy ~= player then
				return
			end

			-- Check if this prompt belongs to a Mailbox
			if prompt.Name == "TriggerPrompt" and prompt.Parent and prompt.Parent.Name == "Mailbox" then
				local base = prompt:FindFirstAncestorWhichIsA("Model") -- Assuming CafeBase is a Model

				if base and base:GetAttribute("OwnerId") then
					local ownerId = tostring(base:GetAttribute("OwnerId"))

					if ownerId == playerId then
						-- It's our own plot, open management/cafe UI
						UIState.toggle("cafe")
					else
						-- It's someone else's plot, open the report menu
						UIState.setReportTargetId(ownerId)
						UIState.toggle("reportMenu")
					end
				end
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, {})

	return nil -- This is a logical component, it renders nothing
end

return MailboxListener
