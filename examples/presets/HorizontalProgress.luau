--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink

local makePanel = Utility.makePanel
local linePath = Utility.linePath
local makePath = Utility.makePath
local track = Utility.track

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Horizontal Progress", 6)
	local path = linePath(context.PathMath, Vector2.new(0, 0.5), Vector2.new(1, 0.5))
	track(context, stage, path, 8)
	local main = makePath(context, stage, { Path = path, Progress = 0.5, Width = 8, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Progress = (math.sin(context.GetClock() * 2.2) + 1) / 2 })
	end)
end
