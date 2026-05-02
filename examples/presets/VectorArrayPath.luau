--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink

local makePanel = Utility.makePanel
local makePath = Utility.makePath

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Vector Array Path", 37)
	local vectorPath: { Vector2 } = {
		Vector2.new(0.12, 0.72),
		Vector2.new(0.28, 0.3),
		Vector2.new(0.44, 0.62),
		Vector2.new(0.6, 0.24),
		Vector2.new(0.82, 0.68),
	}
	local main = makePath(context, stage, { Path = vectorPath, Progress = 0.76, Width = 7, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Progress = (math.sin(context.GetClock() * 2.1) + 1) / 2 })
	end)
end
