-- Shared/ReactComponents/SlotNode.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local SoundController = require(ReplicatedStorage.Shared.Controllers.SoundController)
local CafeTypes = require(ReplicatedStorage.Shared.CafeTypes)

local e = React.createElement
local useEffect = React.useEffect
local useRef = React.useRef

local function CustomerNode(props: {
	CustomerUid: string,
	CustomerData: {
		id: string,
		customerId: string,
		drinkEntities: {
			drinkId: string,
			variationId: string?,
		},
	},
	Instance: CafeTypes.CustomerRig,
})
	local playerId = tostring(Players.LocalPlayer.UserId)
	-- 3. Render BillboardGui
	useEffect(function()
		if not (props.CustomerData and props.CustomerData.customerAction) then
			return
		end

		local action = props.CustomerData.customerAction
		if action == "paid" then
			SoundController.Sound("glass_005")
		end
	end, { props.CustomerData and props.CustomerData.customerAction })
	useEffect(function()
		if not (props.CustomerData and props.CustomerData.id) then
			return
		end
		SoundController.Sound("phaserUp6")
	end, { props.CustomerData and props.CustomerData.id })

	return nil
end

return CustomerNode
