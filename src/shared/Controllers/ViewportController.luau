-- Controllers/ViewportController.client.luau
--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIProducer = require(ReplicatedStorage.Shared.producers.UIState)

local ViewportController = {}
local workspaceCurrentCameraChangeConn: RBXScriptConnection? = nil
local cameraViewportSizeChangeConn: RBXScriptConnection? = nil

-- this causes repeated stuffs in UILab stories.
local function bindCamera(camera: Camera)
	if cameraViewportSizeChangeConn then
		cameraViewportSizeChangeConn:Disconnect()
		cameraViewportSizeChangeConn = nil
	end

	local function update()
		UIProducer.setViewportSize(camera.ViewportSize)
	end

	update()
	cameraViewportSizeChangeConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
end

if Workspace.CurrentCamera then
	bindCamera(Workspace.CurrentCamera)
end
function ViewportController.initialize()
	print("initailized")
	workspaceCurrentCameraChangeConn = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if Workspace.CurrentCamera then
			bindCamera(Workspace.CurrentCamera)
		end
	end)
end
function ViewportController.cleanup()
	print("cleanedup")
	if workspaceCurrentCameraChangeConn then
		workspaceCurrentCameraChangeConn:Disconnect()
		workspaceCurrentCameraChangeConn = nil
	end
	if cameraViewportSizeChangeConn then
		cameraViewportSizeChangeConn:Disconnect()
		cameraViewportSizeChangeConn = nil
	end
end

return ViewportController
