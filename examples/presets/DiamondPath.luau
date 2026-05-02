--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathData = Utility.PathData
type PathPoint = Utility.PathPoint

local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local pathPoint = Utility.pathPoint
local circlePath = Utility.circlePath
local makePath = Utility.makePath
local track = Utility.track

local function polygonPath(PathMath, sides: number, radius: number?, center: Vector2?, rotation: number?): PathData
	local actualRadius = radius or 0.42
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local actualRotation = rotation or -math.pi / 2
	local points: { PathPoint } = {}

	for index = 0, sides - 1 do
		local angle = actualRotation + index * math.pi * 2 / sides
		points[#points + 1] =
			pathPoint(PathMath, actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * actualRadius)
	end

	return { Closed = true, Points = points }
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Diamond Path", 25)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	path = polygonPath(context.PathMath, 4, 0.4, Vector2.new(0.5, 0.5), math.pi / 4)
	track(context, host, path, 5)
	local main = makePath(context, host, { Path = path, Progress = 0.72, Width = 7, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Offset = context.GetClock() * 0.12 })
	end)
end
