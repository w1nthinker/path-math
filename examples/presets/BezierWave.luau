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

local function wavePath(PathMath, amplitude: number?, cycles: number?): PathData
	local actualAmplitude = amplitude or 0.16
	local actualCycles = cycles or 2
	local points: { PathPoint } = {}

	for index = 0, 7 do
		local t = index / 7
		local x = t
		local y = 0.5 + math.sin(t * math.pi * 2 * actualCycles) * actualAmplitude
		points[#points + 1] = pathPoint(PathMath, Vector2.new(x, y))
	end

	return { Closed = false, Points = points }
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Bezier Wave", 22)
	local path = wavePath(context.PathMath, 0.16, 2)
	track(context, stage, path, 5)
	local main = makePath(context, stage, { Path = path, Progress = 0.38, Width = 7, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Offset = context.GetClock() * 0.18 })
	end)
end
