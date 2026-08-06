-- ParticleController.luau
-- Overrides Roblox ParticleEmitter rate by driving :Emit(1) manually.
-- Tags a ParticleEmitter (or its parent) with "customparticle" via CollectionService.
-- Intercepts native 'Rate' and 'Enabled' properties using a Folder-Proxy replacement strategy.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TAG = "customparticle"

local ParticleController = {}

-- ──────────────────────────────────────────────────────────
-- Internal state
-- ──────────────────────────────────────────────────────────

-- Map<ParticleEmitter, { renderer: ParticleEmitter, folder: Folder, accumulator: number }>
local _ancestryConns: { [Instance]: RBXScriptConnection } = {}
local _managed: {
	[ParticleEmitter]: {
		renderer: ParticleEmitter,
		folder: Folder,
		accumulator: number,
	},
} = {}
local _heartbeatConn: RBXScriptConnection? = nil
local _initialized = false

-- ──────────────────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────────────────

local MAX_RATE = 0.8

--- Resolve the ParticleEmitter from the tagged instance.
local function _resolveEmitter(instance: Instance): ParticleEmitter?
	if instance:IsA("ParticleEmitter") then
		return instance
	end
	for _, child in ipairs(instance:GetChildren()) do
		if child:IsA("ParticleEmitter") then
			return child :: ParticleEmitter
		end
	end
	return nil
end

local function _isInWorkspace(instance: Instance): boolean
	return instance:IsDescendantOf(Workspace) or instance:IsDescendantOf(ReplicatedStorage)
	-- or instance:IsDescendantOf(Players)
end

local function _untrack(instance: Instance)
	-- Allow passing either the tagged container or the emitter directly
	local original = if instance:IsA("ParticleEmitter") then instance else _resolveEmitter(instance)
	if not original then
		return
	end

	local data = _managed[original]
	if data then
		-- 1. Restore the original if it hasn't been destroyed
		if original:IsDescendantOf(game) and data.folder.Parent then
			original.Parent = data.folder.Parent
		end

		-- 2. Destroy proxy instances
		if data.renderer then
			data.renderer:Destroy()
		end
		if data.folder then
			data.folder:Destroy()
		end

		-- 3. Clear memory
		_managed[original] = nil
	end
end

local function _track(instance: Instance)
	if not _isInWorkspace(instance) then
		return
	end

	local original = _resolveEmitter(instance)
	if not original or _managed[original] then
		return
	end

	local parent = original.Parent
	if not parent then
		return
	end

	-- 1. Create isolation folder
	-- local folder = Instance.new("Folder") -- this causes it emit at origin
	local folder = Instance.new("StringValue")
	folder.Name = "_Proxy_" .. original.Name
	folder.Parent = ReplicatedStorage

	-- 2. Create the renderer (clone) replacing the original
	local renderer = original:Clone()
	CollectionService:RemoveTag(renderer, TAG) -- Prevents infinite re-entrancy!
	renderer.Enabled = false -- Disable native emission on the clone
	renderer.Name = original.Name
	renderer.Parent = parent

	-- 3. Move original to folder (stops its native emission immediately)
	original.Parent = folder

	_managed[original] = {
		renderer = renderer,
		folder = folder,
		accumulator = 0,
	}
end

local function _onTagAdded(instance: Instance)
	_ancestryConns[instance] = instance.AncestryChanged:Connect(function()
		if _isInWorkspace(instance) then
			_track(instance)
		else
			_untrack(instance)
		end
	end)

	-- 2. Try to track it immediately if it's already in a valid location
	if _isInWorkspace(instance) then
		_track(instance)
	end
end
local function _onTagRemoved(instance: Instance)
	-- 1. Clean up the ancestry listener
	if _ancestryConns[instance] then
		_ancestryConns[instance]:Disconnect()
		_ancestryConns[instance] = nil
	end

	-- 2. Clean up the proxy setup
	_untrack(instance)
end
-- ──────────────────────────────────────────────────────────
-- Heartbeat driver
-- ──────────────────────────────────────────────────────────

local function _startHeartbeat()
	if _heartbeatConn then
		return
	end

	_heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		local camera = workspace.CurrentCamera
		for original, data in pairs(_managed) do
			-- Untrack if the original was destroyed or removed from Workspace
			if not original:IsDescendantOf(game) or not _isInWorkspace(original) then
				_untrack(original)
				continue
			end

			-- Untrack if the renderer was externally destroyed
			if not data.renderer or not data.renderer:IsDescendantOf(game) then
				_untrack(original)
				continue
			end

			local rate = math.min(original.Rate, MAX_RATE)

			-- If disabled natively or rate is 0, just clear accumulator and skip emitting
			if not original.Enabled or not data.renderer:IsDescendantOf(workspace) or rate <= 0 then
				data.accumulator = 0
				continue
			end
			-- If disabled natively or rate is 0, just clear accumulator and skip emitting
			local parent = data.renderer:FindFirstAncestorWhichIsA("BasePart")
			parent = parent or data.renderer:FindFirstAncestorWhichIsA("Model") or nil

			if not (parent and camera) then
				data.accumulator = 0
				continue
			end

			local dist = (camera:GetPivot().Position - parent:GetPivot().Position).Magnitude

			if dist >= 50 then
				data.accumulator = 0
				continue
			end

			data.accumulator += dt
			local interval = 1 / rate

			while data.accumulator >= interval do
				data.accumulator -= interval
				data.renderer:Emit(1)
			end
		end
	end)
end

-- ──────────────────────────────────────────────────────────
-- Public API
-- ──────────────────────────────────────────────────────────

function ParticleController.initialize()
	if _initialized then
		return
	end
	print("PARTICLE CONTROLLER INITIALIZED")
	_initialized = true

	_startHeartbeat()
	-- Process existing tagged instances
	for _, instance in ipairs(CollectionService:GetTagged(TAG)) do
		_onTagAdded(instance)
	end

	-- Watch for new tags
	CollectionService:GetInstanceAddedSignal(TAG):Connect(_onTagAdded)

	-- Watch for tag removal
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(_onTagRemoved)
end

function ParticleController.track(instance: Instance)
	_track(instance)
end

function ParticleController.untrack(instance: Instance)
	_untrack(instance)
end

function ParticleController.getManaged(): { { instance: Instance, rate: number } }
	local list = {}
	for original in pairs(_managed) do
		table.insert(list, { instance = original, rate = original.Rate })
	end
	return list
end

return ParticleController
