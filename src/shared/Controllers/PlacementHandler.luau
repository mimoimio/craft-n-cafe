local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
export type Stud = number
export type Degree = number

-- Settings

-- Bools
local interpolation: boolean = true
local moveByGrid: boolean = true
local buildModePlacement: boolean = true

-- Ints
local rotationStep: Degree = 90
local maxHeight: Stud = 90

-- Numbers/ Floats
local lerpLevel = 0.7

-- Others
local gridTexture = "rbxassetid://2600521419"
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()

-- Constructor Variables
local GRID_SIZE
local ITEM_LOCATION
local ROTATE_KEY
local TERMINATE_KEY

-- Activation Variables
local object: PVInstance?
local placedObjects
local plot: Part
local stackable
local primary

local posX
local posY
local posZ
local speed
local rotation = 0
local rotationVal = false

local collided = nil

local function renderGrid()
	local texture = Instance.new("Texture")
	texture.StudsPerTileU = GRID_SIZE
	texture.StudsPerTileV = GRID_SIZE
	texture.Texture = gridTexture
	texture.Face = Enum.NormalId.Top
	-- texture.OffsetStudsU = GRID_SIZE / 2
	-- texture.OffsetStudsV = GRID_SIZE / 2
	texture.Parent = plot
end

local function changeHitboxColor()
	if primary then
		if collided then
			primary.Color = Color3.new(1, 0, 0)
		else
			primary.Color = Color3.new(0, 1, 0)
		end
	end
end

local function handleCollisions()
	if object then
		collided = false
		local collisionPoint = primary.Touched:Connect(function(otherPart) end)
		local collisionPoints = primary:GetTouchingParts()

		for i, cp in collisionPoints do
			if not cp:IsDescendantOf(object) then
				collided = true
				break
			end
		end

		collisionPoint:Disconnect()
	end
end

-- Calculates the initial y position above an object
local function calculateYPosition(toP, toS, oS)
	return (toP + toS * 0.5) + oS * 0.5
end

local function snap(c)
	local newX = math.round(c.X / GRID_SIZE) * GRID_SIZE
	local newZ = math.round(c.Z / GRID_SIZE) * GRID_SIZE

	return CFrame.new(newX, 0, newZ)
end

local function rotate(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		rotation += rotationStep
		rotationVal = not rotationVal
	end
end

-- Calculates the models position based on grid
local function calculateItemPosition()
	local finalCFrame = CFrame.new(0, 0, 0)
	local x, z
	local offsetX, offsetZ

	if rotationVal then
		offsetX, offsetZ = primary.Size.X * 0.5, primary.Size.Z * 0.5
		x, z = mouse.Hit.X - offsetX, mouse.Hit.Z - offsetZ
	else
		offsetX, offsetZ = primary.Size.Z * 0.5, primary.Size.X * 0.5
		x, z = mouse.Hit.X - offsetX, mouse.Hit.Z - offsetZ
	end

	if stackable then
		posY = calculateYPosition(mouse.Target.Position.Y, mouse.Target.Size.Y, primary.Size.Y)
	else
		posY = calculateYPosition(plot.Position.Y, plot.Size.Y, primary.Size.Y)
	end

	if moveByGrid then
		local pltCFrame = CFrame.new(plot.CFrame.X, plot.CFrame.Y, plot.CFrame.Z)
		local pos = CFrame.new(x, 0, z)
		pos = snap(pos * pltCFrame:Inverse())
		finalCFrame = pos * pltCFrame * CFrame.new(offsetX, 0, offsetZ)
	else
		finalCFrame = CFrame.new(mouse.Hit.X, posY, mouse.Hit.Z)
	end

	finalCFrame = CFrame.new(finalCFrame.X, posY, finalCFrame.Z)

	return finalCFrame * CFrame.Angles(0, math.rad(rotation), 0)
end

local function unBindInputs()
	ContextActionService:UnbindAction("Rotate")
	return
end

local function bindInputs()
	ContextActionService:BindAction("Rotate", rotate, true, ROTATE_KEY)
	return
end

local function translateObj()
	if object and object.Parent and object.Parent == placedObjects then
		handleCollisions()
		changeHitboxColor()
		object:PivotTo(
			-- object:GetPivot():Lerp(CFrame.new(posX, posY, posZ) * CFrame.Angles(0, math.rad(rotation), 0), speed)
			object:GetPivot():Lerp(calculateItemPosition(), speed)
		)
	end
end

local function verifyPlane()
	return plot.Size.X % GRID_SIZE == 0 and plot.Size.Z % GRID_SIZE == 0
end

local function approvePlacement()
	if not verifyPlane() then
		warn("plane % grid size ~= 0")
		return false
	end
	if GRID_SIZE > math.min(plot.Size.X, plot.Size.Z) then
		error("Grid size > plot")
		return false
	end
	return true
end

-- Controller
local placement = {}
placement.__index = placement

--[[```markdown
Constructor function
g:      grid size
objs:   the place
r:      rotate key
t:      terminate key
```]]
function placement.new(g, objs, r, t)
	local data = {}
	local metaData = setmetatable(data, placement)

	GRID_SIZE = 4
	ITEM_LOCATION = objs
	ROTATE_KEY = r
	TERMINATE_KEY = t

	data.grid = GRID_SIZE
	data.itemlocation = ITEM_LOCATION
	data.rotatekey = ROTATE_KEY
	data.terminatekey = TERMINATE_KEY

	return data
end

--[[```
id:     name
pobjs:  placed objects
plt:    plot
stk:    stackable
```]]
function placement:activate(id, pobjs, plt, stk)
	object = ITEM_LOCATION:FindFirstChild(id):Clone()
	primary = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
	placedObjects = pobjs
	plot = plt
	stackable = stk
	rotation = 0

	if not approvePlacement() then
		warn("Placement could not activate")
		return
	end

	if stackable then
		mouse.TargetFilter = object
	else
		mouse.TargetFilter = placedObjects
	end

	local preSpeed = 1

	if interpolation then
		preSpeed = math.clamp(math.abs(tonumber(1 - lerpLevel)), 0, 0.9)
		speed = 1
	end
	object.Parent = placedObjects
	renderGrid()
	bindInputs()
	task.wait()
	speed = preSpeed
end

function placement.initialize()
	RunService:BindToRenderStep("Input", Enum.RenderPriority.Input.Value, translateObj)
	local p = placement.new(2, game.ReplicatedStorage.Shared.Models, Enum.KeyCode.R, Enum.KeyCode.X)
	p:activate("crate", workspace:WaitForChild("PlaceFolder"), workspace:WaitForChild("Baseplate"), false)
end

return placement
