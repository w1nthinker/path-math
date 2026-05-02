--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathContext = Utility.PathContext
type PathData = Utility.PathData

local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local circlePath = Utility.circlePath
local makePath = Utility.makePath

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Function Driven", 14)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	local main = makePath(context, host, {
		Path = function(_pathContext: PathContext): PathData
			return circlePath(
				context.PathMath,
				0.29 + (math.sin(context.GetClock() * 2) + 1) * 0.065,
				Vector2.new(0.5, 0.5),
				6
			)
		end,
		Progress = 0.84,
		Width = 8,
		Color = INK,
	})

	context.AddUpdate(function(_dt: number): ()
		main:Render()
	end)
end
