-- Shared/Controllers/SoundController.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GlobalState = require(ReplicatedStorage.Shared.producers.GlobalState)

local SoundController = {}

-- Sound pool configuration
local POOL_SIZE = 10 -- Pre-create 10 instances of each sound
local soundPools = {} -- {SoundName = {available = {Sound}, inUse = {Sound}, source = Sound}}

-- Volume state
local _sfxVolume = 0.7 -- 0..1
local _listeners: { (state: any) -> () } = {}

export type SoundOptions = {
    PlaybackSpeed: number?,
}

local function _getState()
    return {
        volume = _sfxVolume,
    }
end

local function _notify()
    local state = _getState()
    for _, fn in ipairs(_listeners) do
        fn(state)
    end
end

function SoundController.setVolume(v: number)
    _sfxVolume = math.clamp(v, 0, 1)
    _notify()
end

function SoundController.getState()
    return _getState()
end

function SoundController.subscribe(fn: (state: any) -> ()): () -> ()
    table.insert(_listeners, fn)
    fn(_getState())
    return function()
        local idx = table.find(_listeners, fn)
        if idx then
            table.remove(_listeners, idx)
        end
    end
end

-- Initialize a sound pool for a specific sound
local function initializeSoundPool(soundName: string, poolSize: number)
    local sourceSound = game.ReplicatedStorage.Shared.SFX:FindFirstChild(soundName)
    if not sourceSound then
        return
    end

    soundPools[soundName] = {
        available = {},
        inUse = {},
        source = sourceSound,
    }

    -- Pre-create and load sounds
    for i = 1, poolSize do
        local sound = sourceSound:Clone()
        sound.Parent = game.ReplicatedStorage -- Store in ReplicatedStorage until needed
        if not sound.IsLoaded then
            sound.Loaded:Wait()
        end
        table.insert(soundPools[soundName].available, sound)
    end
end

-- Get a sound from the pool (or create new if pool is empty)
local function getSound(soundName: string): Sound?
    local pool = soundPools[soundName]
    if not pool then
        initializeSoundPool(soundName, POOL_SIZE)
        pool = soundPools[soundName]

        if not pool then
            return
        end
    end

    local sound
    if #pool.available > 0 then
        -- Reuse from pool
        sound = table.remove(pool.available)
    else
        -- Pool exhausted, create new instance
        sound = pool.source:Clone()
        sound.Parent = game.ReplicatedStorage
        if not sound.IsLoaded then
            sound.Loaded:Wait()
        end
    end

    table.insert(pool.inUse, sound)
    return sound
end

-- Return a sound to the pool
local function returnSound(soundName: string, sound: Sound)
    local pool = soundPools[soundName]
    if not pool then
        sound:Destroy()
        return
    end

    -- Remove from inUse
    local index = table.find(pool.inUse, sound)
    if index then
        table.remove(pool.inUse, index)
    end

    -- Reset sound properties and return to available pool
    sound:Stop()
    sound.PlaybackSpeed = pool.source.PlaybackSpeed -- Reset to absolute original speed!
    sound.Parent = game.ReplicatedStorage
    table.insert(pool.available, sound)
end

local function applyVolume(sound: Sound, poolName: string)
    local pool = soundPools[poolName]
    local base = pool and pool.source and (pool.source.Volume ~= 0 and pool.source.Volume or 1) or 1
    sound.Volume = math.clamp(base * _sfxVolume, 0, 10)
end

function SoundController.Sound(name: string, options: SoundOptions?)
    if not game.Players.LocalPlayer then -- not in story plugin, only when played
        return
    end
    task.defer(function()
        local sound = getSound(name)
        if not sound then
            print("failed to get sound")
            return
        end
        
        local pool = soundPools[name]
        local baseSpeed = pool and pool.source and pool.source.PlaybackSpeed or 1
        local speedMultiplier = options and options.PlaybackSpeed or 1
        sound.PlaybackSpeed = baseSpeed * speedMultiplier

        applyVolume(sound, name)
        sound.Parent = game:GetService("SoundService")
        sound:Play()
        sound.Ended:Wait()

        -- Return to pool
        returnSound(name, sound)
    end)
end

function SoundController.initialize()
    task.defer(function()
        initializeSoundPool("glass_003", POOL_SIZE)
        initializeSoundPool("glass_004", POOL_SIZE)
        initializeSoundPool("glass_005", POOL_SIZE)
    end)

    local playerId = tostring(game.Players.LocalPlayer.UserId)
    GlobalState:once(function(state)
        local stats = state.Stats[playerId]
        if not stats then
            return
        end
        return stats.sfx
    end, function(SFXVolume)
        return type(SFXVolume) 
    end, function(state)
        SoundController.setVolume(state)
    end)
end

return SoundController