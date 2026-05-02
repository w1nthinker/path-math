--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathContext = Utility.PathContext
type PathData = Utility.PathData

local INK = Utility.Ink

local makePanel = Utility.makePanel
local linePath = Utility.linePath
local makePath = Utility.makePath

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Moving Endpoints", 33)
	local main = makePath(context, stage, {
		Path = function(_pathContext: PathContext): PathData
			local t = context.GetClock()
			return linePath(
				context.PathMath,
				Vector2.new(0, 0.5 + math.sin(t) * 0.22),
				Vector2.new(1, 0.5 + math.cos(t * 1.3) * 0.22)
			)
		end,
		Progress = 1,
		Width = 7,
		Color = INK,
	})

	context.AddUpdate(function(_dt: number): ()
		main:Render()
	end)
end
