local ServerStorage = game:GetService("ServerStorage")
local PlotConfig = {}
local PlotTemplate = ServerStorage:FindFirstChild("PlotTemplate")

local firstPlot
if PlotTemplate then
	firstPlot = require(PlotTemplate)
end

if not PlotTemplate then
	PlotTemplate = Instance.new("ModuleScript")
	PlotTemplate.Name = "PlotTemplate"
	PlotTemplate.Source = [[return {
	["grid"] = {},
	["nextId"] = 1,
	["placedItems"] = {},
	["spatialItems"] = {},
}]]
	PlotTemplate.Parent = ServerStorage
end
local plot = require(PlotTemplate:Clone())
if not (plot and plot.grid) then
	plot = nil
end

PlotConfig.FirstPlot = plot and plot.grid and plot.nextId and plot.placedItems and plot.spatialItems and plot
	or {
		["grid"] = {},
		["nextId"] = 1,
		["placedItems"] = {},
		["spatialItems"] = {},
	}
warn("plot", plot)
warn("PlotConfig.FirstPlot", PlotConfig.FirstPlot)
return PlotConfig
