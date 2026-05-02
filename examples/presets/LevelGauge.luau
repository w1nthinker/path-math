--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathController = Utility.PathController

local INK = Utility.Ink
local MID = Utility.Mid

local makePanel = Utility.makePanel
local linePath = Utility.linePath
local makePath = Utility.makePath

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Level Gauge", 17)
	local levels: { PathController } = {}

	for index = 1, 5 do
		local y = 0.76 - index * 0.11
		levels[index] = makePath(context, stage, {
			Path = linePath(context.PathMath, Vector2.new(0, y), Vector2.new(1, y)),
			Progress = 0,
			Width = 6,
			Color = if index == 5 then INK else MID,
			Transparency = 0.72,
		})
	end

	context.AddUpdate(function(_dt: number): ()
		local value = ((math.sin(context.GetClock() * 1.8) + 1) / 2) * #levels
		for index = 1, #levels do
			local progress = math.clamp(value - (index - 1), 0, 1)
			levels[index]:Update({ Progress = progress, Transparency = if progress > 0 then 0 else 0.72 })
		end
	end)
end
