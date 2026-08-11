-- Controllers/ViewportController.client.luau
--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIProducer = require(ReplicatedStorage.Shared.producers.UIState)

local currentConnection: RBXScriptConnection? = nil

local function bindCamera(camera: Camera)
	if currentConnection then
		currentConnection:Disconnect()
		currentConnection = nil
	end

	local function update()
		UIProducer.setViewportSize(camera.ViewportSize)
	end

	update()
	currentConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
end

if Workspace.CurrentCamera then
	bindCamera(Workspace.CurrentCamera)
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	if Workspace.CurrentCamera then
		bindCamera(Workspace.CurrentCamera)
	end
end)
