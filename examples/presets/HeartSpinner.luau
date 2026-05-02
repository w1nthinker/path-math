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

local function heartPath(PathMath, center: Vector2?, scale: number?): PathData
	local actualCenter = center or Vector2.new(0.5, 0.52)
	local actualScale = scale or 0.022
	local points: { PathPoint } = {}

	for index = 0, 35 do
		local t = math.pi * 2 * index / 36
		local x = 16 * math.sin(t) ^ 3
		local y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
		points[#points + 1] = pathPoint(PathMath, actualCenter + Vector2.new(x, y) * actualScale)
	end

	return { Closed = true, Points = points }
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Heart Spinner", 13)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	path = heartPath(context.PathMath)
	track(context, host, path, 6)
	local main = makePath(context, host, { Path = path, Progress = 0.42, Width = 7, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({
			Offset = context.GetClock() * 0.12,
			Width = 6 + (math.sin(context.GetClock() * 4) + 1) * 2,
		})
	end)
end
