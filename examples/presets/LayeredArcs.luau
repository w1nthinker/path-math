--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink
local MID = Utility.Mid

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local arcPath = Utility.arcPath
local makePath = Utility.makePath

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Layered Arcs", 30)
	local host = normalizedHost(stage, 0.76, 0.54)
	host.Position = UDim2.fromScale(0.5, 0.58)
	local path = arcPath(context.PathMath, 0.42, math.rad(145), math.rad(395))
	for index = 1, 5 do
		makePath(context, host, {
			Path = arcPath(context.PathMath, 0.18 + index * 0.045, math.rad(150), math.rad(150 + index * 38)),
			Progress = 1,
			Width = 4 + index,
			Color = if index % 2 == 0 then MID else INK,
			Transparency = index * 0.08,
		})
	end
end
