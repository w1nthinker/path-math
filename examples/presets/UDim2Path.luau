--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathData = Utility.PathData

local INK = Utility.Ink

local makePanel = Utility.makePanel
local pathPoint = Utility.pathPoint
local makePath = Utility.makePath
local track = Utility.track

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "UDim2 Path", 36)
	local udimPath: PathData = {
		Closed = false,
		Points = {
			pathPoint(context.PathMath, Vector2.new(0, 0.78)),
			pathPoint(context.PathMath, Vector2.new(0.28, 0.22)),
			pathPoint(context.PathMath, Vector2.new(0.56, 0.78)),
			pathPoint(context.PathMath, Vector2.new(1, 0.22)),
		},
	}
	track(context, stage, udimPath, 5)
	local main = makePath(context, stage, { Path = udimPath, Progress = 0.7, Width = 7, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Offset = context.GetClock() * 0.12 })
	end)
end
