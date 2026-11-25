local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- 1. Create Tool with Thumbnail URL & clean Hand Grip
local tool = Instance.new("Tool")
tool.Name = "Unicorn"
tool.TextureId = "rbxthumb://type=Asset&id=122618512184829&w=150&h=150"
tool.RequiresHandle = true
tool.Grip = CFrame.new(0, 0, 0.8)

-- 2. Create Handle (held in hand)
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(1, 1, 1)
handle.Transparency = 1
handle.CanCollide = false
handle.Massless = true
handle.Parent = tool

-- 3. Load Unicorn Model (2200525256) safely
local unicornModel
local success, objects = pcall(function()
	return game:GetObjects("rbxassetid://2200525256")
end)

if success and type(objects) == "table" then
	local _, firstObj = next(objects)
	if firstObj then
		unicornModel = firstObj
	end
end

if not unicornModel then
	unicornModel = Instance.new("Model")
	
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(1.8, 1.8, 3.8)
	body.Color = Color3.fromRGB(255, 255, 255)
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = unicornModel
	unicornModel.PrimaryPart = body

	local neck = Instance.new("Part")
	neck.Name = "Neck"
	neck.Size = Vector3.new(1, 1.8, 1)
	neck.Color = Color3.fromRGB(255, 255, 255)
	neck.Material = Enum.Material.SmoothPlastic
	neck.CFrame = body.CFrame * CFrame.new(0, 1.1, -1.5) * CFrame.Angles(math.rad(25), 0, 0)
	neck.Parent = unicornModel

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.1, 1, 1.6)
	head.Color = Color3.fromRGB(255, 255, 255)
	head.Material = Enum.Material.SmoothPlastic
	head.CFrame = neck.CFrame * CFrame.new(0, 0.8, -0.4) * CFrame.Angles(math.rad(-25), 0, 0)
	head.Parent = unicornModel

	local horn = Instance.new("Part")
	horn.Name = "Horn"
	horn.Size = Vector3.new(0.25, 1.4, 0.25)
	horn.Color = Color3.fromRGB(255, 215, 0)
	horn.Material = Enum.Material.Neon
	horn.CFrame = head.CFrame * CFrame.new(0, 0.9, -0.3) * CFrame.Angles(math.rad(35), 0, 0)
	horn.Parent = unicornModel
end

unicornModel.Name = "UnicornModel"
unicornModel.Parent = tool

-- Prep and weld all parts of the unicorn
local allParts = {}
for _, obj in ipairs(unicornModel:GetDescendants()) do
	if obj:IsA("BasePart") then
		obj.CanCollide = false
		obj.Anchored = false
		obj.Massless = true
		
		-- Hide gray Seat blocks or invisible root/hitbox parts on the back
		if obj:IsA("Seat") or obj:IsA("VehicleSeat") or obj.Name == "HumanoidRootPart" or obj.Name == "RootPart" or obj.Name == "Hitbox" then
			obj.Transparency = 1
		end
		
		table.insert(allParts, obj)
	end
end

local _, fallbackPrimary = next(allParts)
local primaryPart = unicornModel.PrimaryPart or fallbackPrimary
unicornModel.PrimaryPart = primaryPart

for _, part in ipairs(allParts) do
	if part ~= primaryPart then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = primaryPart
		weld.Part1 = part
		weld.Parent = primaryPart
	end
end

-- Hold position: pushed forward to -3.4 so the tail/back has a clean gap from your hand
local holdOffset = CFrame.new(0, 0.3, -3.4)
unicornModel:PivotTo(handle.CFrame * holdOffset)

local handWeld = Instance.new("WeldConstraint")
handWeld.Part0 = handle
handWeld.Part1 = primaryPart
handWeld.Parent = handle

-- 4. Create Rainbow Fire
local rainbowColors = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 165, 0)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0, 127, 255)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(139, 0, 255))
})

local rainbowFireEmitter = Instance.new("ParticleEmitter")
rainbowFireEmitter.Name = "RainbowFireEmitter"
rainbowFireEmitter.Texture = "rbxasset://textures/particles/fire_main.dds"
rainbowFireEmitter.Color = rainbowColors
rainbowFireEmitter.LightEmission = 1
rainbowFireEmitter.Size = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1.5),
	NumberSequenceKeypoint.new(0.5, 2.2),
	NumberSequenceKeypoint.new(1, 0)
})
rainbowFireEmitter.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.1),
	NumberSequenceKeypoint.new(0.7, 0.4),
	NumberSequenceKeypoint.new(1, 1)
})
rainbowFireEmitter.Lifetime = NumberRange.new(0.6, 1.1)
rainbowFireEmitter.Rate = 95
rainbowFireEmitter.Speed = NumberRange.new(3, 7)
rainbowFireEmitter.SpreadAngle = Vector2.new(45, 45)
rainbowFireEmitter.RotSpeed = NumberRange.new(-120, 120)
rainbowFireEmitter.Enabled = false
rainbowFireEmitter.Parent = primaryPart

local classicFire = Instance.new("Fire")
classicFire.Size = 6
classicFire.Heat = 8
classicFire.Enabled = false
classicFire.Parent = primaryPart

-- 5. Universal Flight (PC + Mobile) & Sitting Pose
local isRiding = false
local flySpeed = 65
local rideWeld, alignOri, sitTrack

local function playSitAnimation(humanoid)
	local anim = Instance.new("Animation")
	anim.AnimationId = humanoid.RigType == Enum.HumanoidRigType.R15 
		and "rbxassetid://2506281703" 
		or "rbxassetid://178130996"
	local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
	sitTrack = animator:LoadAnimation(anim)
	sitTrack.Priority = Enum.AnimationPriority.Action
	sitTrack.Looped = true
	sitTrack:Play()
end

local function stopRiding()
	isRiding = false
	rainbowFireEmitter.Enabled = false
	classicFire.Enabled = false
	RunService:UnbindFromRenderStep("UnicornFly")

	if sitTrack then sitTrack:Stop() sitTrack = nil end
	if alignOri then alignOri:Destroy() alignOri = nil end
	if rideWeld then rideWeld:Destroy() rideWeld = nil end

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoid then
			humanoid.AutoRotate = true
		end
		if rootPart then
			local att = rootPart:FindFirstChild("UnicornFlyAtt")
			if att then att:Destroy() end
			rootPart.AssemblyLinearVelocity = Vector3.zero
		end
	end

	-- Return unicorn cleanly in front of your hand with the gap
	handWeld.Enabled = false
	unicornModel:PivotTo(handle.CFrame * holdOffset)
	handWeld.Enabled = true
end

local function startRiding()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	isRiding = true
	handWeld.Enabled = false

	-- Place unicorn beneath player & weld
	unicornModel:PivotTo(rootPart.CFrame * CFrame.new(0, -1.6, 0))
	rideWeld = Instance.new("WeldConstraint")
	rideWeld.Part0 = rootPart
	rideWeld.Part1 = primaryPart
	rideWeld.Parent = rootPart

	-- Keep Humanoid in normal state so MoveDirection works, and play sitting animation
	humanoid.AutoRotate = false
	playSitAnimation(humanoid)

	-- Smooth orientation facing camera direction
	local rootAtt = Instance.new("Attachment")
	rootAtt.Name = "UnicornFlyAtt"
	rootAtt.Parent = rootPart

	alignOri = Instance.new("AlignOrientation")
	alignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOri.Attachment0 = rootAtt
	alignOri.MaxTorque = 1e6
	alignOri.Responsiveness = 25
	alignOri.Parent = rootPart

	RunService:BindToRenderStep("UnicornFly", Enum.RenderPriority.Character.Value + 1, function()
		if not isRiding or not rootPart then return end

		local camCF = camera.CFrame
		alignOri.CFrame = camCF

		local moveInput = humanoid.MoveDirection
		local vertical = 0

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			vertical = 1
		elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
			vertical = -1
		end

		local isMoving = moveInput.Magnitude > 0 or vertical ~= 0

		-- Toggle rainbow fire ONLY while actively flying/moving
		rainbowFireEmitter.Enabled = isMoving
		classicFire.Enabled = isMoving

		if isMoving then
			local hue = (tick() * 0.8) % 1
			local color = Color3.fromHSV(hue, 1, 1)
			classicFire.Color = color
			classicFire.SecondaryColor = Color3.fromHSV((hue + 0.15) % 1, 1, 1)
		end

		if moveInput.Magnitude > 0 then
			local flatLook = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
			local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
			if flatLook.Magnitude > 0 then flatLook = flatLook.Unit end
			if flatRight.Magnitude > 0 then flatRight = flatRight.Unit end

			local forwardAmount = moveInput:Dot(flatLook)
			local rightAmount = moveInput:Dot(flatRight)
			local flyDir = (camCF.LookVector * forwardAmount) + (camCF.RightVector * rightAmount) + Vector3.new(0, vertical, 0)
			
			if flyDir.Magnitude > 0 then
				rootPart.AssemblyLinearVelocity = flyDir.Unit * flySpeed
			end
		else
			rootPart.AssemblyLinearVelocity = Vector3.new(0, vertical * flySpeed, 0)
		end
	end)
end

tool.Equipped:Connect(function()
	if not isRiding then
		handWeld.Enabled = false
		unicornModel:PivotTo(handle.CFrame * holdOffset)
		handWeld.Enabled = true
	end
end)

tool.Activated:Connect(function()
	if isRiding then
		stopRiding()
	else
		startRiding()
	end
end)

tool.Unequipped:Connect(function()
	if isRiding then
		stopRiding()
	end
end)

tool.Parent = player:WaitForChild("Backpack")
