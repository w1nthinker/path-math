--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathData = Utility.PathData
type PathPoint = Utility.PathPoint

local INK = Utility.Ink

local makePanel = Utility.makePanel
local pathPoint = Utility.pathPoint
local makePath = Utility.makePath
local track = Utility.track

local function zigZagPath(PathMath, count: number?): PathData
	local pointCount = count or 9
	local points: { PathPoint } = {}

	for index = 0, pointCount - 1 do
		local t = index / (pointCount - 1)
		local y = if index % 2 == 0 then 0.28 else 0.72
		points[#points + 1] = pathPoint(PathMath, Vector2.new(t, y))
	end

	return { Closed = false, Points = points }
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Zig Zag", 23)
	local path = zigZagPath(context.PathMath, 9)
	track(context, stage, path, 5)
	local main = makePath(context, stage, { Path = path, Progress = 0.55, Width = 6, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Progress = (math.sin(context.GetClock() * 2) + 1) / 2 })
	end)
end
