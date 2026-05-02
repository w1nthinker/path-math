--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local circlePath = Utility.circlePath
local makePath = Utility.makePath
local track = Utility.track

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Transparency Sweep", 31)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	track(context, host, path, 8)
	local main = makePath(context, host, { Path = path, Progress = 0.5, Width = 8, Color = INK, Transparency = 0 })

	context.AddUpdate(function(_dt: number): ()
		main:Update({
			Offset = context.GetClock() * 0.2,
			Transparency = (math.sin(context.GetClock() * 2.5) + 1) * 0.35,
		})
	end)
end
