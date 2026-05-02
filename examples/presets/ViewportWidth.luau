--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type ResponsiveLength = Utility.ResponsiveLength

local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local circlePath = Utility.circlePath
local makePath = Utility.makePath

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Viewport Width", 21)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	local width: ResponsiveLength = { Scale = 0.01, Min = 4, Max = 14, Basis = "ViewportMin" }
	local main = makePath(context, host, {
		Path = path,
		Progress = 0.78,
		Width = width,
		Color = INK,
		ViewportSize = context.GetViewportSize(),
	})

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Offset = context.GetClock() * 0.1, ViewportSize = context.GetViewportSize() })
	end)
end
