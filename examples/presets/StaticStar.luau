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

local function starPath(PathMath, outerRadius: number?, innerRadius: number?, center: Vector2?): PathData
	local actualOuterRadius = outerRadius or 0.43
	local actualInnerRadius = innerRadius or actualOuterRadius * 0.46
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local points: { PathPoint } = {}

	for index = 0, 9 do
		local radius = if index % 2 == 0 then actualOuterRadius else actualInnerRadius
		local angle = -math.pi / 2 + index * math.pi / 5
		points[#points + 1] = pathPoint(PathMath, actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * radius)
	end

	return { Closed = true, Points = points }
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Static Star", 10)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	path = starPath(context.PathMath)
	track(context, host, path, 6)
	local main = makePath(context, host, { Path = path, Progress = 1, Width = 7, Color = INK })
end
