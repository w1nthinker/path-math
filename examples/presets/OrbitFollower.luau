--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathController = Utility.PathController

local INK = Utility.Ink
local MID = Utility.Mid
local FAINT = Utility.Faint

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local circlePath = Utility.circlePath
local makePath = Utility.makePath

local function squareDot(stage: Instance, color: Color3, size: number?): Frame
	local dot = Instance.new("Frame")
	dot.Name = "SquareDot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(size or 8, size or 8)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	dot.Parent = stage
	return dot
end

local function addFollower(stage: GuiObject, controller: PathController, color: Color3, phase: number): Frame
	local dot = squareDot(stage, color, 7)
	dot.Position = UDim2.fromScale(controller:GetPointAt(phase).X, controller:GetPointAt(phase).Y)
	return dot
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Orbit Follower", 29)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	local main = makePath(context, host, { Path = path, Progress = 1, Width = 5, Color = FAINT })
	local dotA = addFollower(host, main, INK, 0)
	local dotB = addFollower(host, main, MID, 0.5)

	context.AddUpdate(function(_dt: number): ()
		local t = context.GetClock() * 0.18
		local p1 = main:GetPointAt(t)
		local p2 = main:GetPointAt(t + 0.5)
		dotA.Position = UDim2.fromScale(p1.X, p1.Y)
		dotB.Position = UDim2.fromScale(p2.X, p2.Y)
	end)
end
