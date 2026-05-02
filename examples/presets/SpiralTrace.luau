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

local function spiralPath(PathMath): PathData
	local points: { PathPoint } = {}

	for index = 0, 32 do
		local t = index / 32
		local angle = t * math.pi * 5.4
		local radius = 0.04 + t * 0.4
		points[#points + 1] =
			pathPoint(PathMath, Vector2.new(0.5, 0.5) + Vector2.new(math.cos(angle), math.sin(angle)) * radius)
	end

	return { Closed = false, Points = points }
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Spiral Trace", 28)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	path = spiralPath(context.PathMath)
	track(context, host, path, 4)
	local main = makePath(context, host, { Path = path, Progress = 0.6, Width = 6, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Progress = (math.sin(context.GetClock() * 1.6) + 1) / 2 })
	end)
end
