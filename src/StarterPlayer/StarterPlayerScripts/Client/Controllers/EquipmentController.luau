--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ClubRegistry = require(ReplicatedStorage.Shared.GolfPro.Clubs.ClubRegistry)
local PresentationConfig = require(ReplicatedStorage.Shared.GolfPro.Presentation.PresentationConfig)

local EquipmentController = {}

local LOCAL_PLAYER = Players.LocalPlayer
local MODEL_NAME = "GolfProEquippedClub"
local MOTOR_NAME = "GolfProClubGripMotor"

local currentClubId = "driver"
local currentCategory = "wood"
local started = false
local equippedModel: Model? = nil
local gripMotor: Motor6D? = nil
local activeTween: Tween? = nil

local function categoryFor(club: any): string
	local category = club.category
	if PresentationConfig.CLUB_VISUALS[category] ~= nil then
		return category
	end

	return "iron"
end

local function visualForCategory(category: string): any
	return PresentationConfig.CLUB_VISUALS[category] or PresentationConfig.CLUB_VISUALS.iron
end

local function cancelTween()
	if activeTween ~= nil then
		activeTween:Cancel()
		activeTween = nil
	end
end

local function tweenMotor(transform: CFrame, seconds: number)
	local motor = gripMotor
	if motor == nil then
		return
	end

	cancelTween()
	local tween = TweenService:Create(
		motor,
		TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transform = transform }
	)
	activeTween = tween
	tween:Play()
end

local function makePart(name: string, size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Anchored = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	return part
end

local function weldToHandle(handle: Part, part: Part)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = part
	weld.Parent = part
end

local function findGripPart(character: Model): BasePart?
	local rightHand = character:FindFirstChild("RightHand")
		or character:WaitForChild("RightHand", 5)
	if rightHand and rightHand:IsA("BasePart") then
		return rightHand
	end

	local rightArm = character:FindFirstChild("Right Arm") or character:WaitForChild("Right Arm", 5)
	if rightArm and rightArm:IsA("BasePart") then
		return rightArm
	end

	return nil
end

local function destroyEquippedModel()
	cancelTween()
	gripMotor = nil
	if equippedModel ~= nil then
		equippedModel:Destroy()
		equippedModel = nil
	end
end

local function buildClub(character: Model, club: any)
	local gripPart = findGripPart(character)
	if gripPart == nil then
		return
	end

	destroyEquippedModel()

	local category = categoryFor(club)
	local visual = visualForCategory(category)
	local model = Instance.new("Model")
	model.Name = MODEL_NAME

	local handle = makePart("Handle", Vector3.new(0.22, 0.22, 0.22), visual.gripColor)
	handle.Transparency = 1
	handle.CFrame = gripPart.CFrame * visual.addressC0
	handle.Parent = model

	local shaft = makePart(
		"Shaft",
		Vector3.new(visual.shaftThickness, visual.shaftLength, visual.shaftThickness),
		visual.shaftColor
	)
	shaft.CFrame = handle.CFrame * CFrame.new(0, -visual.shaftLength * 0.5, 0)
	shaft.Parent = model
	weldToHandle(handle, shaft)

	local head = makePart("Head", visual.headSize, visual.headColor)
	head.CFrame = handle.CFrame * visual.headOffset
	head.Parent = model
	weldToHandle(handle, head)

	local grip = makePart("Grip", visual.gripSize, visual.gripColor)
	grip.CFrame = handle.CFrame * CFrame.new(0, visual.gripSize.Y * 0.2, 0)
	grip.Parent = model
	weldToHandle(handle, grip)

	local motor = Instance.new("Motor6D")
	motor.Name = MOTOR_NAME
	motor.Part0 = gripPart
	motor.Part1 = handle
	motor.C0 = visual.addressC0
	motor.C1 = CFrame.new()
	motor.Transform = CFrame.new()
	motor.Parent = handle

	model.PrimaryPart = handle
	model.Parent = character
	equippedModel = model
	gripMotor = motor
	currentCategory = category
end

local function attachCurrentClub()
	local character = LOCAL_PLAYER.Character
	local club = ClubRegistry.get(currentClubId)
	if character == nil or club == nil then
		return
	end

	task.spawn(function()
		buildClub(character, club)
	end)
end

function EquipmentController.start()
	if started then
		return
	end

	started = true
	LOCAL_PLAYER.CharacterAdded:Connect(function()
		attachCurrentClub()
	end)
	attachCurrentClub()
end

function EquipmentController.setClub(clubId: string)
	local club = ClubRegistry.get(clubId)
	if club == nil then
		return
	end

	local nextCategory = categoryFor(club)
	local changed = clubId ~= currentClubId or nextCategory ~= currentCategory
	currentClubId = clubId
	if changed or equippedModel == nil then
		attachCurrentClub()
	end
end

function EquipmentController.getCurrentClubId(): string
	return currentClubId
end

function EquipmentController.playAddress()
	tweenMotor(CFrame.new(), 0.12)
end

function EquipmentController.playBackswing(power01: number?)
	local visual = visualForCategory(currentCategory)
	local alpha = math.clamp(power01 or 1, 0, 1)
	tweenMotor(CFrame.new():Lerp(visual.topTransform, alpha), 0.18)
end

function EquipmentController.playStrike(_accuracy01: number?)
	local visual = visualForCategory(currentCategory)
	tweenMotor(visual.impactTransform, 0.08)
	task.delay(0.09, function()
		tweenMotor(CFrame.new(), 0.14)
	end)
end

function EquipmentController.getDebugState()
	return {
		currentClubId = currentClubId,
		hasCharacter = LOCAL_PLAYER.Character ~= nil,
		hasClubModel = equippedModel ~= nil,
		hasGripMotor = gripMotor ~= nil,
	}
end

return EquipmentController
