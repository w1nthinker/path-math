--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathController = Utility.PathController

local INK = Utility.Ink
local STRONG = Utility.Strong
local MID = Utility.Mid

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local arcPath = Utility.arcPath
local makePath = Utility.makePath
local track = Utility.track

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Segmented Gauge", 16)
	local host = normalizedHost(stage, 0.76, 0.54)
	host.Position = UDim2.fromScale(0.5, 0.58)
	local path = arcPath(context.PathMath, 0.42, math.rad(145), math.rad(395))
	local segments: { PathController } = {}

	for index = 1, 12 do
		local startAngle = math.rad(150 + (index - 1) * 20)
		local endAngle = math.rad(164 + (index - 1) * 20)
		track(context, host, arcPath(context.PathMath, 0.42, startAngle, endAngle), 7)
		segments[index] = makePath(context, host, {
			Path = arcPath(context.PathMath, 0.42, startAngle, endAngle),
			Progress = 0,
			Width = 7,
			Color = if index < 5 then INK elseif index < 9 then STRONG else MID,
			Transparency = 0.75,
		})
	end

	context.AddUpdate(function(_dt: number): ()
		local scaled = ((math.sin(context.GetClock() * 1.4) + 1) / 2) * #segments
		for index = 1, #segments do
			local progress = math.clamp(scaled - (index - 1), 0, 1)
			segments[index]:Update({ Progress = progress, Transparency = if progress > 0 then 0 else 0.75 })
		end
	end)
end
