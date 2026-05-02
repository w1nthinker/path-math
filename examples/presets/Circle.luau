--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink
local SOFT = Utility.Soft

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local circlePath = Utility.circlePath
local makePath = Utility.makePath

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Circle", 1)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	local main = makePath(context, host, {
		Path = path,
		Progress = 1,
		Width = 9,
		Color = INK,
		Stroke = { Width = 2, Color = SOFT },
	})

	context.AddUpdate(function(_dt: number): ()
		main:Update({
			Width = 8 + (math.sin(context.GetClock() * 2) + 1) * 2,
		})
	end)
end
