--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink
local MID = Utility.Mid

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local arcPath = Utility.arcPath
local makePath = Utility.makePath
local track = Utility.track

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Dual Gauge", 15)
	local host = normalizedHost(stage, 0.76, 0.54)
	host.Position = UDim2.fromScale(0.5, 0.58)
	local path = arcPath(context.PathMath, 0.42, math.rad(145), math.rad(395))
	track(context, host, path, 7)
	local primary = makePath(context, host, { Path = path, Progress = 0.45, Width = 7, Color = INK })
	local secondary = makePath(context, host, {
		Path = arcPath(context.PathMath, 0.31, math.rad(145), math.rad(395)),
		Progress = 0.7,
		Width = 5,
		Color = MID,
	})

	context.AddUpdate(function(_dt: number): ()
		primary:Update({ Progress = (math.sin(context.GetClock() * 1.4) + 1) / 2 })
		secondary:Update({ Progress = (math.cos(context.GetClock() * 1.9) + 1) / 2 })
	end)
end
