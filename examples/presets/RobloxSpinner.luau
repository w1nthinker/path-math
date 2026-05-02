--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathData = Utility.PathData
type PathPoint = Utility.PathPoint

local WHITE = Utility.White
local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local pathPoint = Utility.pathPoint
local circlePath = Utility.circlePath
local makePath = Utility.makePath

local function addRobloxMark(stage: Instance, color: Color3, backgroundColor: Color3): Frame
	local mark = Instance.new("Frame")
	mark.Name = "RobloxMark"
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Size = UDim2.fromScale(0.5, 0.5)
	mark.BackgroundColor3 = color
	mark.BorderSizePixel = 0
	mark.Rotation = 10
	mark.Parent = stage

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = mark

	local hole = Instance.new("Frame")
	hole.Name = "Hole"
	hole.AnchorPoint = Vector2.new(0.5, 0.5)
	hole.Position = UDim2.fromScale(0.5, 0.5)
	hole.Size = UDim2.fromScale(0.22, 0.22)
	hole.BackgroundColor3 = backgroundColor
	hole.BorderSizePixel = 0
	hole.Parent = mark

	return mark
end

local function robloxIconPath(PathMath, center: Vector2?, outerSize: number?): PathData
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local halfOuter = (outerSize or 0.54) * 0.5
	local rotation = math.rad(35)
	local points: { PathPoint } = {}

	for index = 0, 3 do
		local angle = rotation + index * math.pi / 2
		points[#points + 1] =
			pathPoint(PathMath, actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * halfOuter)
	end

	return { Closed = true, Points = points }
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Roblox Spinner", 39)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	addRobloxMark(host, INK, WHITE)
	path = robloxIconPath(context.PathMath)
	local main = makePath(context, host, {
		Path = path,
		Progress = 0.24,
		Width = 4,
		Color = INK,
	})

	context.AddUpdate(function(_dt: number): ()
		main:Update({
			Offset = context.GetClock() * 0.18,
			Progress = 0.16 + (math.sin(context.GetClock() * 2.8) + 1) * 0.08,
		})
	end)
end
