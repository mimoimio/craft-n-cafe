-- Shared/ReactComponents/TableNode.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local SlotNode = require(script.Parent.SlotNode)
local e = React.createElement
local useEffect = React.useEffect

local function TableNode(props: {
	TableId: string,
	TableData: any,
	Instance: Instance?,
})
	if not props.Instance or not props.TableData or not props.TableData.Slots then
		-- warn(`TableNode Failed: not {props.Instance} not {props.TableData} not {props.TableData.Slots}`)
		return nil
	end
	useEffect(function()
		if not props.Instance then
			return
		end

		UIState.setTableInstance(props.Instance)

		return function()
			UIState.setTableInstance(nil)
		end
	end, { props.Instance })

	local children = {}
	local slotsFolder = props.Instance:FindFirstChild("Slots")

	-- warn("props.Instance", props.Instance)
	-- warn("slotsFolder", slotsFolder)
	-- warn("props.TableData.Slots", props.TableData.Slots)

	if slotsFolder then
		for slotName, drinkUid in pairs(props.TableData.Slots) do
			local slotInstance = slotsFolder:FindFirstChild(slotName)
			-- warn("slotInstance", slotInstance)
			if slotInstance then
				children[slotName] = e(SlotNode, {
					SlotName = slotName,
					DrinkUid = drinkUid,
					Instance = slotInstance,
					Drinks = props.Drinks,
				})
			end
		end
	end

	return e(React.Fragment, nil, children)
end

return TableNode
