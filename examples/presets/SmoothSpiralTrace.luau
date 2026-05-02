--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext
type PathData = Utility.PathData
type PathPoint = Utility.PathPoint

local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local pathPoint = Utility.pathPoint
local circlePath = Utility.circlePath
local makePath = Utility.makePath
local track = Utility.track

local function smoothSpiralPath(PathMath): PathData
	local points: { PathPoint } = {}
	local segmentCount = 32
	local turns = math.pi * 5.4
	local radiusStart = 0.04
	local radiusRange = 0.4
	local center = Vector2.new(0.5, 0.5)

	for index = 0, segmentCount do
		local t = index / segmentCount
		local angle = t * turns
		local radius = radiusStart + t * radiusRange
		local radial = Vector2.new(math.cos(angle), math.sin(angle))
		local tangent = Vector2.new(-math.sin(angle), math.cos(angle))
		local derivative = radial * radiusRange + tangent * radius * turns
		local handle = derivative / segmentCount / 3

		points[#points + 1] = pathPoint(PathMath, center + radial * radius, -handle, handle)
	end

	return { Closed = false, Points = points }
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Smooth Spiral Trace", 29)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	path = smoothSpiralPath(context.PathMath)
	track(context, host, path, 4)
	local main = makePath(context, host, { Path = path, Progress = 0.6, Width = 6, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Progress = (math.sin(context.GetClock() * 1.6) + 1) / 2 })
	end)
end
