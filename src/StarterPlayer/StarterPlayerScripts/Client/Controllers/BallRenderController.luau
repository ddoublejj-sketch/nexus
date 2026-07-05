--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local PresentationConfig = require(ReplicatedStorage.Shared.GolfPro.Presentation.PresentationConfig)

local LOCAL_PLAYER = Players.LocalPlayer

local BallRenderController = {}

local RUNTIME_FOLDER_NAME = "GolfProRuntime"
local BALL_NAME = "LocalGolfBall"

local started = false
local ballsFolder: Folder? = nil
local tracersFolder: Folder? = nil
local markersFolder: Folder? = nil
local ballPart: Part? = nil
local animationToken = 0
local cameraConnection: RBXScriptConnection? = nil
local previousCameraType: any = nil
local previousCameraSubject: any = nil
local cameraActive = false

local debugState = {
	lastShotId = nil :: string?,
	lastSurface = nil :: string?,
	lastPointCount = 0,
	lastTotalYards = nil :: number?,
}

local function clamp(value: number, minValue: number, maxValue: number): number
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end

	return value
end

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent

	return folder
end

local function ensureRuntime()
	local root = getOrCreateFolder(Workspace, RUNTIME_FOLDER_NAME)
	ballsFolder = getOrCreateFolder(root, "Balls")
	tracersFolder = getOrCreateFolder(root, "Tracers")
	markersFolder = getOrCreateFolder(root, "Markers")
end

local function ensureBall(): Part
	ensureRuntime()
	local existing = (ballsFolder :: Folder):FindFirstChild(BALL_NAME)
	if existing and existing:IsA("Part") then
		ballPart = existing
		return existing
	end

	local ball = Instance.new("Part")
	ball.Name = BALL_NAME
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(
		PresentationConfig.BALL_RADIUS_STUDS * 2,
		PresentationConfig.BALL_RADIUS_STUDS * 2,
		PresentationConfig.BALL_RADIUS_STUDS * 2
	)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = PresentationConfig.DEFAULT_BALL_COLOR
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanTouch = false
	ball.CanQuery = false
	ball.CastShadow = true
	ball.Parent = ballsFolder :: Folder
	ballPart = ball

	return ball
end

local function bindRemote(name: string, callback: (...any) -> ())
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("NexusRemotes", 10)
		if folder == nil then
			return
		end

		local remote = folder:WaitForChild(name, 10)
		if remote and remote:IsA("RemoteEvent") then
			remote.OnClientEvent:Connect(callback)
		end
	end)
end

local function restoreCamera()
	if cameraConnection ~= nil then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	local camera = Workspace.CurrentCamera
	if camera ~= nil and cameraActive then
		if previousCameraType ~= nil then
			camera.CameraType = previousCameraType
		end
		if previousCameraSubject ~= nil then
			camera.CameraSubject = previousCameraSubject
		else
			local character = LOCAL_PLAYER.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid ~= nil then
				camera.CameraSubject = humanoid
			end
		end
	end

	cameraActive = false
	previousCameraType = nil
	previousCameraSubject = nil
end

local function startShotCamera(ball: Part)
	if not PresentationConfig.SHOT_CAMERA_ENABLED then
		return
	end

	restoreCamera()
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end

	previousCameraType = camera.CameraType
	previousCameraSubject = camera.CameraSubject
	camera.CameraType = Enum.CameraType.Scriptable
	cameraActive = true
	cameraConnection = RunService.RenderStepped:Connect(function()
		local position = ball.Position
		local offset = Vector3.new(
			0,
			PresentationConfig.SHOT_CAMERA_HEIGHT_STUDS,
			-PresentationConfig.SHOT_CAMERA_BACK_STUDS
		)
		camera.CFrame = CFrame.lookAt(position + offset, position)
	end)
end

local function scheduleCameraRestore(token: number)
	task.delay(PresentationConfig.SHOT_CAMERA_RESTORE_DELAY_SECONDS, function()
		if token == animationToken then
			restoreCamera()
		end
	end)
end

local function pointDistance(points: { any }): number
	local total = 0
	for index = 1, #points - 1 do
		local a = BallRenderController.yardsPointToWorld(points[index])
		local b = BallRenderController.yardsPointToWorld(points[index + 1])
		total += (b - a).Magnitude
	end

	return math.max(total, 1)
end

local function shotDuration(payload: any, points: { any }): number
	local result = payload.result
	local yards = if type(result) == "table" and type(result.totalYards) == "number"
		then result.totalYards
		else pointDistance(points)

	return clamp(
		yards / 140,
		PresentationConfig.BALL_FLIGHT_MIN_SECONDS,
		PresentationConfig.BALL_FLIGHT_MAX_SECONDS
	)
end

function BallRenderController.start()
	if started then
		return
	end

	started = true
	ensureBall()

	bindRemote("RoundStateUpdated", function(snapshot: any)
		if type(snapshot) == "table" and type(snapshot.ball) == "table" then
			local ball = snapshot.ball
			if type(ball.position) == "table" then
				BallRenderController.placeBallAtYards(ball.position, ball.surface)
			end
		end
	end)
	bindRemote("HoleStarted", function(payload: any)
		if type(payload) == "table" and type(payload.tee) == "table" then
			BallRenderController.placeBallAtYards(payload.tee, "tee")
		end
	end)
	bindRemote("BallPath", function(payload: any)
		BallRenderController.renderPath(payload)
	end)
	bindRemote("BallAtRest", function(payload: any)
		BallRenderController.applyBallAtRest(payload)
	end)
end

function BallRenderController.yardsPointToWorld(point: any): Vector3
	local x = if type(point) == "table" and type(point.x) == "number" then point.x else 0
	local z = if type(point) == "table" and type(point.y) == "number" then point.y else 0
	local y = if type(point) == "table" and type(point.z) == "number"
		then point.z
		else PresentationConfig.BALL_HEIGHT_OFFSET_STUDS

	return Vector3.new(
		x * PresentationConfig.STUDS_PER_YARD,
		y + PresentationConfig.BALL_HEIGHT_OFFSET_STUDS,
		z * PresentationConfig.STUDS_PER_YARD
	)
end

function BallRenderController.placeBallAtYards(position: any, surface: string?)
	local ball = ensureBall()
	ball.Position = BallRenderController.yardsPointToWorld(position)
	ball.Transparency = 0
	debugState.lastSurface = surface
end

function BallRenderController.clearShotVisuals()
	ensureRuntime()
	for _, child in (tracersFolder :: Folder):GetChildren() do
		child:Destroy()
	end
	for _, child in (markersFolder :: Folder):GetChildren() do
		child:Destroy()
	end
end

function BallRenderController.renderPath(payload: any)
	if type(payload) ~= "table" or type(payload.points) ~= "table" or #payload.points < 2 then
		return
	end

	local points = payload.points
	BallRenderController.clearShotVisuals()
	local ball = ensureBall()
	local worldPoints = {}
	for index, point in points do
		worldPoints[index] = BallRenderController.yardsPointToWorld(point)
	end

	for index = 1, #worldPoints - 1 do
		local startPoint = worldPoints[index]
		local endPoint = worldPoints[index + 1]
		local delta = endPoint - startPoint
		local distance = math.max(delta.Magnitude, 0.05)
		local segment = Instance.new("Part")
		segment.Name = "ShotTracerSegment"
		segment.Anchored = true
		segment.CanCollide = false
		segment.CanTouch = false
		segment.CanQuery = false
		segment.Material = Enum.Material.Neon
		segment.Color = PresentationConfig.TRACER_COLOR
		segment.Size = Vector3.new(
			PresentationConfig.TRACER_THICKNESS_STUDS,
			PresentationConfig.TRACER_THICKNESS_STUDS,
			distance
		)
		segment.CFrame = CFrame.lookAt(startPoint:Lerp(endPoint, 0.5), endPoint)
		segment.Parent = tracersFolder :: Folder
		task.delay(PresentationConfig.TRACER_LIFETIME_SECONDS, function()
			if segment.Parent ~= nil then
				segment:Destroy()
			end
		end)
	end

	local finalPoint = worldPoints[#worldPoints]
	local marker = Instance.new("Part")
	marker.Name = "LandingMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Material = Enum.Material.Neon
	marker.Color = PresentationConfig.LANDING_MARKER_COLOR
	marker.Transparency = 0.35
	marker.Size = Vector3.new(
		PresentationConfig.LANDING_MARKER_RADIUS_STUDS * 2,
		0.12,
		PresentationConfig.LANDING_MARKER_RADIUS_STUDS * 2
	)
	marker.Position = Vector3.new(finalPoint.X, 0.18, finalPoint.Z)
	marker.Parent = markersFolder :: Folder

	local result = payload.result
	debugState.lastShotId = if type(payload.shotId) == "string" then payload.shotId else nil
	debugState.lastPointCount = #points
	debugState.lastTotalYards = if type(result) == "table"
			and type(result.totalYards) == "number"
		then result.totalYards
		else nil

	animationToken += 1
	local token = animationToken
	local totalDistance = pointDistance(points)
	local totalDuration = shotDuration(payload, points)
	ball.Position = worldPoints[1]
	startShotCamera(ball)
	task.spawn(function()
		for index = 1, #worldPoints - 1 do
			if token ~= animationToken then
				return
			end
			local startPoint = worldPoints[index]
			local endPoint = worldPoints[index + 1]
			local segmentDistance = (endPoint - startPoint).Magnitude
			local duration = math.max(0.05, totalDuration * (segmentDistance / totalDistance))
			local tween = TweenService:Create(
				ball,
				TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{ Position = endPoint }
			)
			tween:Play()
			tween.Completed:Wait()
		end
		ball.Position = finalPoint
		scheduleCameraRestore(token)
	end)
end

function BallRenderController.applyBallAtRest(payload: any)
	if type(payload) ~= "table" or type(payload.position) ~= "table" then
		return
	end

	BallRenderController.placeBallAtYards(payload.position, payload.surface)
	debugState.lastSurface = payload.surface
end

function BallRenderController.getDebugState()
	return {
		hasBall = ballPart ~= nil,
		lastShotId = debugState.lastShotId,
		lastSurface = debugState.lastSurface,
		lastPointCount = debugState.lastPointCount,
		lastTotalYards = debugState.lastTotalYards,
		cameraActive = cameraActive,
	}
end

return BallRenderController
