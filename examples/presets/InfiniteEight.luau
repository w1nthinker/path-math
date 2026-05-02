--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathData = Utility.PathData

local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local pathPoint = Utility.pathPoint
local circlePath = Utility.circlePath
local makePath = Utility.makePath
local track = Utility.track

local function eightPath(PathMath): PathData
	local k = 0.18
	return {
		Closed = true,
		Points = {
			pathPoint(PathMath, Vector2.new(0.50, 0.50), Vector2.new(0, -k), Vector2.new(0, k)),
			pathPoint(PathMath, Vector2.new(0.24, 0.50), Vector2.new(0, k), Vector2.new(0, -k)),
			pathPoint(PathMath, Vector2.new(0.50, 0.50), Vector2.new(0, -k), Vector2.new(0, k)),
			pathPoint(PathMath, Vector2.new(0.76, 0.50), Vector2.new(0, k), Vector2.new(0, -k)),
		},
	}
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Infinite Eight", 7)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	path = eightPath(context.PathMath)
	track(context, host, path, 7)
	local main = makePath(context, host, { Path = path, Progress = 0.24, Width = 8, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Offset = context.GetClock() * 0.24, Progress = 0.24 })
	end)
end
