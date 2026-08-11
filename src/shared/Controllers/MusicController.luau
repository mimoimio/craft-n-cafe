-- MusicController.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)
local Players = game:GetService("Players")

local MusicController = {}

-- ──────────────────────────────────────────────────────────
-- Internal state
-- ──────────────────────────────────────────────────────────
local _tracks: { Sound } = {}
local _index = 1
local _volume = 0.2 -- 0..1
local _playingSound: Sound? = nil
local _endedConn: RBXScriptConnection? = nil
local _listeners: { (state: any) -> () } = {}
local _initialized = false

local function _getState()
	return {
		index = _index,
		trackName = _tracks[_index] and _tracks[_index].Name or "None",
		volume = _volume,
		playing = _playingSound ~= nil,
		trackCount = #_tracks,
	}
end

local function _notify()
	local state = _getState()
	for _, fn in ipairs(_listeners) do
		fn(state)
	end
end

local function _stopCurrent()
	if _endedConn then
		_endedConn:Disconnect()
		_endedConn = nil
	end
	if _playingSound then
		_playingSound:Destroy()
		_playingSound = nil
	end
end

local function _playIndex(index: number)
	_stopCurrent()
	if #_tracks == 0 then
		return
	end

	_index = ((index - 1) % #_tracks) + 1 -- wrap around

	local source = _tracks[_index]
	if not source then
		return
	end

	local sound = source:Clone()
	-- sound.Parent = game:GetService("SoundService")
	sound.Parent = Players.LocalPlayer
	local base = math.clamp(sound.Volume ~= 0 and sound.Volume or 1, 0, 10)
	sound.Volume = math.clamp(base * _volume, 0, 10)
	sound:Play()
	_playingSound = sound

	_endedConn = sound.Ended:Connect(function()
		_playIndex(_index + 1)
	end)

	_notify()
end

-- ──────────────────────────────────────────────────────────
-- Public API
-- ──────────────────────────────────────────────────────────

function MusicController.Start()
	-- Load all Sound instances from ReplicatedStorage.Shared.Musics
	local folder = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Musics")
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Sound") then
			table.insert(_tracks, child)
		end
	end

	-- Also watch for any dynamically added sounds
	folder.ChildAdded:Connect(function(child)
		if child:IsA("Sound") then
			table.insert(_tracks, child)
			_notify()
		end
	end)

	if #_tracks > 0 then
		_playIndex(1)
	end
end
function MusicController.initialize()
	if _initialized then
		return
	end
	_initialized = true

	MusicController.Start()
end

function MusicController.next()
	_playIndex(_index + 1)
end

function MusicController.prev()
	_playIndex(_index - 1)
end

function MusicController.setVolume(v: number)
	_volume = math.clamp(v, 0, 1)
	if _playingSound then
		local tracks = _tracks
		local source = tracks[_index]
		local base = source and (source.Volume ~= 0 and source.Volume or 1) or 1
		_playingSound.Volume = math.clamp(base * _volume, 0, 10)
	end
	_notify()
end

function MusicController.getState()
	return _getState()
end

--- Subscribe to state changes. Returns an unsubscribe function.
function MusicController.subscribe(fn: (state: any) -> ()): () -> ()
	table.insert(_listeners, fn)
	fn(_getState()) -- fire immediately with current state
	return function()
		local idx = table.find(_listeners, fn)
		if idx then
			table.remove(_listeners, idx)
		end
	end
end

return MusicController
