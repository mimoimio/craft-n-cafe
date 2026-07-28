-- ParticleController.luau
-- Overrides Roblox ParticleEmitter rate by driving :Emit(1) manually.
-- Tags a ParticleEmitter (or its parent) with "customparticle" via CollectionService.
-- The emitter must have a numeric "Rate" attribute (particles per second).
-- Only emitters that are descendants of Workspace are managed.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TAG = "customparticle"

local ParticleController = {}

-- ──────────────────────────────────────────────────────────
-- Internal state
-- ──────────────────────────────────────────────────────────

-- Map<Instance, { emitter: ParticleEmitter, accumulator: number, rateConn: RBXScriptConnection? }>
local _managed: { [Instance]: { emitter: ParticleEmitter, accumulator: number, rateConn: RBXScriptConnection? } } = {}
local _heartbeatConn: RBXScriptConnection? = nil
local _initialized = false

-- ──────────────────────────────────────────────────────────
-- Helpers
-- ──────────────────────────────────────────────────────────

local MAX_RATE = 10

local function _getRate(instance: Instance): number
	local raw = instance:GetAttribute("Rate")
	if type(raw) == "number" and raw > 0 then
		return math.min(raw, MAX_RATE)
	end
	return 0
end

--- Resolve the ParticleEmitter from the tagged instance.
--- The tag may be placed on the ParticleEmitter itself or on a BasePart that
--- contains exactly one ParticleEmitter child.
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
	return instance:IsDescendantOf(Workspace) or instance:IsDescendantOf(Players)
end

local function _untrack(instance: Instance)
	local data = _managed[instance]
	if data then
		if data.rateConn then
			data.rateConn:Disconnect()
		end
		-- Re-enable the native emitter so it behaves normally if un-tagged
		if data.emitter and data.emitter.Parent then
			data.emitter.Enabled = true
		end
		_managed[instance] = nil
	end
end

local function _track(instance: Instance)
	if _managed[instance] then
		return -- already tracked
	end
	if not _isInWorkspace(instance) then
		return
	end

	local emitter = _resolveEmitter(instance)
	if not emitter then
		return
	end

	-- Disable the native rate so Roblox doesn't emit on its own
	emitter.Enabled = false

	local data = {
		emitter = emitter,
		accumulator = 0,
		rateConn = nil,
	}

	-- React to Rate attribute changes at runtime
	data.rateConn = instance.AttributeChanged:Connect(function(attr)
		if attr == "Rate" then
			-- reset accumulator so a rate of 0 stops immediately
			data.accumulator = 0
		end
	end)

	_managed[instance] = data
end

-- ──────────────────────────────────────────────────────────
-- Heartbeat driver
-- ──────────────────────────────────────────────────────────

local function _startHeartbeat()
	if _heartbeatConn then
		return
	end
	_heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		for instance, data in pairs(_managed) do
			-- Drop if emitter or instance is no longer valid / in workspace
			if not data.emitter or not data.emitter.Parent or not _isInWorkspace(instance) then
				_untrack(instance)
				continue
			end

			local customEnabled = instance:GetAttribute("CustomEnabled")
			if not customEnabled then
				continue
			end

			local rate = instance.Rate
			if rate <= 0 then
				continue
			end

			data.accumulator += dt
			local interval = 1 / rate

			while data.accumulator >= interval do
				data.accumulator -= interval
				if not data.emitter:IsDescendantOf(Workspace) then
					continue
				end
				data.emitter:Emit(1)
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

	-- Track all already-tagged instances
	for _, instance in ipairs(CollectionService:GetTagged(TAG)) do
		_track(instance)
	end

	-- Watch for new tags
	CollectionService:GetInstanceAddedSignal(TAG):Connect(function(instance)
		_track(instance)
	end)

	-- Watch for tag removal
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(instance)
		_untrack(instance)
	end)
end

--- Manually add an instance to the controller without CollectionService.
function ParticleController.track(instance: Instance)
	_track(instance)
end

--- Manually remove an instance from the controller.
function ParticleController.untrack(instance: Instance)
	_untrack(instance)
end

--- Returns a snapshot of currently managed instances and their rates.
function ParticleController.getManaged(): { { instance: Instance, rate: number } }
	local list = {}
	for instance in pairs(_managed) do
		table.insert(list, { instance = instance, rate = instance.Rate })
	end
	return list
end

return ParticleController
