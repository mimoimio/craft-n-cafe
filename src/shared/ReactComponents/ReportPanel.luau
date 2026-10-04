local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local ReportPanel = function(props)
	local panel, setPanel = useState("none")
	local targetId, setTargetId = useState(nil)
	local submitting, setSubmitting = useState(false)

	useEffect(function()
		local unsub = UIState:subscribe(function(state)
			setPanel(state.panel)
			setTargetId(state.reportTargetId)
		end)
		setPanel(UIState:getState().panel)
		setTargetId(UIState:getState().reportTargetId)
		return unsub
	end, {})

	if panel ~= "reportMenu" or not targetId then
		return nil
	end

	local submitReport = function()
		if submitting then
			return
		end
		setSubmitting(true)

		-- Fire remote to server (We will build the server side next)
		Remotes.SubmitReport:FireServer(targetId, "Inappropriate Build", "Submitted via Mailbox")

		task.wait(1) -- Fake loading for UX
		setSubmitting(false)
		UIState.setReportTargetId(nil)
		UIState.toggle("none")
	end

	return e("Frame", {
		Size = UDim2.new(0, 300, 0, 200),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, {
		Layout = e(VStack, {
			Padding = { All = UDim.new(0, 16) },
			Spacing = UDim.new(0, 12),
			AutomaticSize = Enum.AutomaticSize.Y,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalFlex = "Fill",
		}, {
			Title = e(SmallText, {
				Text = "Report Plot",
				LayoutOrder = 1,
				TextSize = 24,
				TextColor3 = Color3.new(1, 0.2, 0.2),
			}),
			Desc = e(SmallText, {
				Text = "Does this plot contain inappropriate content? ",
				LayoutOrder = 2,
				TextWrapped = true,
				Size = UDim2.new(1, 0, 0, 60),
			}),
			SubmitBtn = e(SmallButton, {
				Text = submitting and "Sending..." or "Submit Report",
				LayoutOrder = 3,
				BackgroundColor3 = Color3.new(0.8, 0.2, 0.2),
				[React.Event.Activated] = submitReport,
			}),
			CancelBtn = e(SmallButton, {
				Text = "Cancel",
				LayoutOrder = 4,
				BackgroundColor3 = Color3.new(0.5, 0.5, 0.5),
				[React.Event.Activated] = function()
					UIState.setReportTargetId(nil)
					UIState.toggle("none")
				end,
			}),
		}),
	})
end

return ReportPanel
