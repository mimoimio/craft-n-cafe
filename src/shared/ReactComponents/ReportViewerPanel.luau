local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local UIState = require(ReplicatedStorage.Shared.producers.UIState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)

local function ReportViewerPanel()
	local visible, setVisible = useState(false)
	local loading, setLoading = useState(false)
	local reports, setReports = useState({})
	local selectedReport, setSelectedReport = useState(nil)

	-- Sync with UIState
	useEffect(function()
		local unsub = UIState:subscribe(function(state)
			return state.panel == "reportViewer"
		end, setVisible)

		setVisible(UIState:getState().panel == "reportViewer")
		return unsub
	end, {})

	-- Fetch reports when opened
	useEffect(function()
		if visible then
			setLoading(true)
			task.spawn(function()
				local fetchedReports = Remotes.FetchReports:InvokeServer(20) -- Fetch latest 20
				setReports(fetchedReports or {})
				setLoading(false)
			end)
		else
			setSelectedReport(nil)
		end
	end, { visible })

	if not visible then
		return nil
	end

	-- Render list of report buttons
	local reportElements = {}
	for i, report in ipairs(reports) do
		local dateStr = os.date("%c", report.Timestamp)
		reportElements[report.ReportId] = e(SmallButton, {
			Size = UDim2.new(1, 0, 0, 40),
			AutomaticSize = Enum.AutomaticSize.None,
			LayoutOrder = i,
			BackgroundColor3 = (selectedReport == report) and Color3.new(0.3, 0.3, 0.3) or Color3.new(0.2, 0.2, 0.2),
			[React.Event.Activated] = function()
				setSelectedReport(report)
			end,
		}, {
			e(SmallText, {
				Text = `Reported: {report.ReportedId} | {dateStr}`,
				Size = UDim2.fromScale(1, 1),
				TextSize = 14,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(0, 800, 0, 500),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Active = true,
	}, {
		UICorner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}),

		Layout = e(VStack, {
			VerticalFlex = "Fill",
			Spacing = UDim.new(0, 12),
		}, {
			Header = e(HStack, {
				Size = UDim2.new(1, 0, 0, 30),
				HorizontalFlex = "SpaceBetween",
				LayoutOrder = 1,
			}, {
				Title = e(
					SmallText,
					{ Text = "Moderation Queue", TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left }
				),
				CloseBtn = e(SmallButton, {
					Text = "Close",
					Size = UDim2.new(0, 100, 1, 0),
					BackgroundColor3 = Color3.new(0.8, 0.2, 0.2),
					[React.Event.Activated] = function()
						UIState.toggle("none")
					end,
				}),
			}),

			Content = e(HStack, {
				Size = UDim2.new(1, 0, 1, -40),
				Spacing = UDim.new(0, 12),
				LayoutOrder = 2,
			}, {
				-- LEFT PANEL: Report List
				ListContainer = e("Frame", {
					Size = UDim2.new(0.4, 0, 1, 0),
					BackgroundTransparency = 1,
				}, {
					Scroll = e("ScrollingFrame", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						ScrollBarThickness = 6,
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						CanvasSize = UDim2.new(0, 0, 0, 0),
					}, {
						Layout = e(VStack, { Spacing = UDim.new(0, 6) }, reportElements),
						LoadingMsg = loading
							and e(SmallText, { Text = "Loading reports...", Size = UDim2.new(1, 0, 0, 30) }),
						EmptyMsg = (not loading and #reports == 0)
							and e(SmallText, { Text = "Queue is empty.", Size = UDim2.new(1, 0, 0, 30) }),
					}),
				}),

				Divider = e("Frame", { Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = Color3.fromRGB(60, 60, 60) }),

				-- RIGHT PANEL: Report Details
				DetailsContainer = e("Frame", {
					Size = UDim2.new(0.6, -14, 1, 0),
					BackgroundTransparency = 1,
				}, {
					NoSelection = not selectedReport
						and e(SmallText, { Text = "Select a report to view details", Size = UDim2.fromScale(1, 1) }),

					DetailsLayout = selectedReport
						and e(VStack, {
							Spacing = UDim.new(0, 12),
							HorizontalAlignment = Enum.HorizontalAlignment.Left,
						}, {
							Reporter = e(
								SmallText,
								{
									Text = `<b>Reporter ID:</b> {selectedReport.ReporterId}`,
									RichText = true,
									TextXAlignment = Enum.TextXAlignment.Left,
									LayoutOrder = 1,
								}
							),
							Reported = e(
								SmallText,
								{
									Text = `<b>Reported ID:</b> {selectedReport.ReportedId}`,
									RichText = true,
									TextXAlignment = Enum.TextXAlignment.Left,
									TextColor3 = Color3.new(1, 0.5, 0.5),
									LayoutOrder = 2,
								}
							),
							Reason = e(
								SmallText,
								{
									Text = `<b>Reason:</b> {selectedReport.Reason}`,
									RichText = true,
									TextXAlignment = Enum.TextXAlignment.Left,
									LayoutOrder = 3,
								}
							),
							Comment = e(
								SmallText,
								{
									Text = `<b>User Comment:</b> {selectedReport.Comment}`,
									RichText = true,
									TextXAlignment = Enum.TextXAlignment.Left,
									TextWrapped = true,
									Size = UDim2.new(1, 0, 0, 60),
									LayoutOrder = 4,
								}
							),

							Stats = e(SmallText, {
								Text = `<b>Placed Items in Snapshot:</b> {selectedReport.PlotSnapshot and selectedReport.PlotSnapshot.placedItems and #selectedReport.PlotSnapshot.placedItems or 0}`,
								RichText = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								LayoutOrder = 5,
							}),

							-- Placeholder for future deep inspection logic
							ViewSnapshotBtn = e(SmallButton, {
								Text = "Load Plot Snapshot in Viewer (Coming Soon)",
								Size = UDim2.new(1, 0, 0, 40),
								LayoutOrder = 6,
								BackgroundColor3 = Color3.fromRGB(80, 120, 180),
								[React.Event.Activated] = function()
									print("Snapshot Payload:", selectedReport.PlotSnapshot)
								end,
							}),
						}),
				}),
			}),
		}),
	})
end

return ReportViewerPanel
