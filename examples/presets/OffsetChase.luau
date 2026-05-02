--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink
local MID = Utility.Mid
local SOFT = Utility.Soft

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local circlePath = Utility.circlePath
local makePath = Utility.makePath
local track = Utility.track

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Offset Chase", 18)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	track(context, host, path, 5)
	local a = makePath(context, host, { Path = path, Progress = 0.12, Width = 6, Color = INK })
	local b = makePath(context, host, { Path = path, Progress = 0.12, Width = 6, Color = MID, Offset = 0.33 })
	local c = makePath(context, host, { Path = path, Progress = 0.12, Width = 6, Color = SOFT, Offset = 0.66 })

	context.AddUpdate(function(_dt: number): ()
		local t = context.GetClock() * 0.22
		a:Update({ Offset = t })
		b:Update({ Offset = t + 0.33 })
		c:Update({ Offset = t + 0.66 })
	end)
end
