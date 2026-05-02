--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathController = Utility.PathController

local INK = Utility.Ink
local MID = Utility.Mid

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local circlePath = Utility.circlePath
local makePath = Utility.makePath

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Pulse Tunnel", 34)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	local rings: { PathController } = {}

	for index = 1, 5 do
		rings[index] = makePath(context, host, {
			Path = circlePath(context.PathMath, 0.14 + index * 0.055),
			Progress = 1,
			Width = 3 + index,
			Color = if index % 2 == 0 then MID else INK,
			Transparency = index * 0.08,
		})
	end

	context.AddUpdate(function(_dt: number): ()
		for index = 1, #rings do
			rings[index]:Update({ Width = 3 + index + (math.sin(context.GetClock() * 2 + index) + 1) * 1.5 })
		end
	end)
end
