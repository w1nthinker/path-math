--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local arcPath = Utility.arcPath
local makePath = Utility.makePath
local track = Utility.track

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Gauge", 4)
	local host = normalizedHost(stage, 0.76, 0.54)
	host.Position = UDim2.fromScale(0.5, 0.58)
	local path = arcPath(context.PathMath, 0.42, math.rad(145), math.rad(395))
	track(context, host, path, 8)
	local main = makePath(context, host, { Path = path, Progress = 0.62, Width = 8, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Progress = (math.sin(context.GetClock() * 1.6) + 1) / 2 })
	end)
end
