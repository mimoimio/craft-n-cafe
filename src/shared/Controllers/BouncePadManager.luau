local CollectionService = game:GetService("CollectionService")

local BouncePadManager = {}
local BOUNCE_PAD_TAG = "BouncePad"
local DEFAULT_BOUNCE_IMPULSE = 300

local function setupBouncePad(bouncePad: Instance)
	if not bouncePad:IsA("BasePart") then
		return
	end

	local impulse = bouncePad:GetAttribute("BounceImpulse") or DEFAULT_BOUNCE_IMPULSE
	bouncePad.Anchored = true
	bouncePad.AssemblyLinearVelocity = bouncePad.CFrame:VectorToWorldSpace(Vector3.yAxis * impulse)

	local bounceIndicator = bouncePad:FindFirstChildWhichIsA("SurfaceGui")
	if bounceIndicator then
		bounceIndicator.Enabled = false
	end
end

function BouncePadManager.initialize()
	for _, bouncePad in CollectionService:GetTagged(BOUNCE_PAD_TAG) do
		setupBouncePad(bouncePad)
	end
	CollectionService:GetInstanceAddedSignal(BOUNCE_PAD_TAG):Connect(setupBouncePad)
end

function BouncePadManager.start()
	-- Bounce pads operate via AssemblyLinearVelocity, no loop needed.
end

return BouncePadManager
