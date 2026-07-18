local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect
local useRef = React.useRef
local useBinding = React.useBinding
local UIState = require(ReplicatedStorage.Shared.producers.UIState)

local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)

local player = game.Players.LocalPlayer
local playerId = player and player.UserId or ""

local Mailbox = function(props: {})
	local prompt, setPrompt = useState(nil)
	-- useEffect(function()
	-- 	warn("prompt", prompt)
	-- end, { prompt })
	useEffect(function()
		local promise = Promise.defer(function(resolve, reject)
			local basesModel = workspace:WaitForChild("Bases")
			local bases = basesModel:GetChildren()

			local found
			local startTime = workspace:GetServerTimeNow()
			local elapsed = 0
			repeat
				for i, base: CafeTypes.CafeBase in bases do
					local ownerId = base:GetAttribute("OwnerId")
					warn(`base ({base}), ownerId({ownerId})`)
					if not ownerId then
						continue
					end
					if not ownerId == playerId then
						continue
					end
					found = base
					local Mailbox = base:WaitForChild("Mailbox")
					local mailboxPart = Mailbox:WaitForChild("Mailbox")
					local TriggerPrompt = mailboxPart:WaitForChild("TriggerPrompt")

					return resolve({
						TriggerPrompt = TriggerPrompt,
					})
				end

				if not found then
					task.wait()
					elapsed = workspace:GetServerTimeNow() - startTime
					if elapsed >= 10 then
						return reject("Get base timeout")
					end
				end
			until found or elapsed >= 10
			return reject("Get base timeout")
		end)

		promise
			:andThen(function(resolved)
				setPrompt(resolved.TriggerPrompt)
			end)
			:catch(function(err)
				warn(`[Mailbox] Failed to resolve descendants for {props.SlotName}: {err}`)
			end)

		return function()
			-- If the component unmounts before WaitForChild finishes, cancel the Promise
			-- so it stops executing and doesn't attempt to update unmounted state.
			promise:cancel()
		end
	end, {})
	useEffect(function()
		if not prompt then
			return
		end
		local conn = prompt.Triggered:Connect(function(player)
			-- warn("Triggered")
			if player == Players.LocalPlayer then
				UIState.toggle("cafe")
			end
		end)
		return function()
			if conn then
				conn:Disconnect()
			end
		end
	end, { prompt })
end

return Mailbox
