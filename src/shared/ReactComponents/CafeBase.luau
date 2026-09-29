-- ReplicatedStorage/Shared/ReactComponents/CafeBase.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)
local Promise = require(ReplicatedStorage.Packages.Promise)
local useEffect = React.useEffect

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)

local player = Players.LocalPlayer
local playerId = player and tostring(player.UserId) or "MockUser"

-- FIX: Increased to 30 seconds. Network replication varies heavily per player.
local TIMEOUT = 30

local CafeBase = function(props: {})
	useEffect(function()
		local promise = Promise.defer(function(resolve, reject)
			local basesModel = workspace:WaitForChild("Bases")
			local bases = basesModel:GetChildren()

			local found
			local startTime = workspace:GetServerTimeNow()
			local elapsed = 0

			repeat
				for _, base: CafeTypes.CafeBase in bases do
					local ownerId = base:GetAttribute("OwnerId")
					if ownerId == playerId then
						found = base
						return resolve(base)
					end
				end

				if not found then
					task.wait()
					elapsed = workspace:GetServerTimeNow() - startTime
					if elapsed >= TIMEOUT then
						return reject("Get base timeout")
					end
				end
			until found or elapsed >= TIMEOUT

			return reject("Get base timeout")
		end)

		promise
			:andThen(function(resolvedBase)
				-- Wait for the SERVER to replicate the dynamic Part to the Client
				local plotPart = resolvedBase:WaitForChild("Part", TIMEOUT)
				if plotPart then
					UIState.setCafeBase(resolvedBase)
				else
					warn("[CafeBase] Timeout waiting for Server to replicate the dynamic Part.", resolvedBase)
				end
			end)
			:catch(function(err)
				warn(`[CafeBase] Failed to resolve base: {err}`)
			end)

		return function()
			promise:cancel()
			UIState.setCafeBase(nil)
		end
	end, {})

	-- Since the server renders the physical Part, this client component renders nothing visually!
	return nil
end

return CafeBase
