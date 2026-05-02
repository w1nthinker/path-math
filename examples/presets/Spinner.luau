--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local circlePath = Utility.circlePath
local makePath = Utility.makePath

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Spinner", 3)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	local main = makePath(context, host, {
		Path = path,
		Progress = 0.17,
		Width = { Scale = 0.011, Min = 7, Max = 12, Basis = "ViewportMin" },
		Color = INK,
		ViewportSize = context.GetViewportSize(),
	})

	context.AddUpdate(function(_dt: number): ()
		main:Update({
			Progress = 0.12 + (math.sin(context.GetClock() * 3) + 1) * 0.11,
			Offset = context.GetClock() * 0.55,
			ViewportSize = context.GetViewportSize(),
		})
	end)
end
