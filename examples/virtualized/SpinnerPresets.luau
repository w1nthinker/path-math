--!strict

local PathMath = require("@game/ReplicatedStorage/PathMath")

type PathMathApi = typeof(PathMath)
type PathPoint = PathMath.PathPoint
type PathData = PathMath.PathData

export type SpinnerKind = "Circle" | "Star" | "Heart" | "Eight"
export type SpinnerPresetsApi = {
	KindOrder: { SpinnerKind },
	circlePath: (PathMath: PathMathApi, radius: number?, center: Vector2?, segments: number?) -> PathData,
	eightPath: (PathMath: PathMathApi) -> PathData,
	starPath: (PathMath: PathMathApi, outerRadius: number?, innerRadius: number?, center: Vector2?) -> PathData,
	heartPath: (PathMath: PathMathApi, center: Vector2?, scale: number?) -> PathData,
	getPath: (PathMath: PathMathApi, kind: SpinnerKind) -> PathData,
}

local SpinnerPresets = {} :: SpinnerPresetsApi

local function pathPoint(PathMathApi: PathMathApi, position: Vector2, leftTangent: Vector2?, rightTangent: Vector2?): PathPoint
	return PathMathApi.point(position, leftTangent or Vector2.zero, rightTangent or Vector2.zero)
end

function SpinnerPresets.circlePath(PathMathApi: PathMathApi, radius: number?, center: Vector2?, segments: number?): PathData
	local actualRadius = radius or 0.42
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local segmentCount = segments or 4
	local angleStep = math.pi * 2 / segmentCount
	local handleLength = (4 / 3) * math.tan(angleStep / 4) * actualRadius
	local points: { PathPoint } = {}

	for index = 0, segmentCount - 1 do
		local angle = index * angleStep
		local tangentAngle = angle + math.pi / 2
		local position = actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * actualRadius
		local tangent = Vector2.new(math.cos(tangentAngle), math.sin(tangentAngle)) * handleLength
		points[#points + 1] = pathPoint(PathMathApi, position, -tangent, tangent)
	end

	return {
		Closed = true,
		Points = points,
	}
end

function SpinnerPresets.eightPath(PathMathApi: PathMathApi): PathData
	local k = 0.18
	return {
		Closed = true,
		Points = {
			pathPoint(PathMathApi, Vector2.new(0.50, 0.50), Vector2.new(0, -k), Vector2.new(0, k)),
			pathPoint(PathMathApi, Vector2.new(0.24, 0.50), Vector2.new(0, k), Vector2.new(0, -k)),
			pathPoint(PathMathApi, Vector2.new(0.50, 0.50), Vector2.new(0, -k), Vector2.new(0, k)),
			pathPoint(PathMathApi, Vector2.new(0.76, 0.50), Vector2.new(0, k), Vector2.new(0, -k)),
		},
	}
end

function SpinnerPresets.starPath(PathMathApi: PathMathApi, outerRadius: number?, innerRadius: number?, center: Vector2?): PathData
	local actualOuterRadius = outerRadius or 0.43
	local actualInnerRadius = innerRadius or actualOuterRadius * 0.46
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local points: { PathPoint } = {}

	for index = 0, 9 do
		local radius = if index % 2 == 0 then actualOuterRadius else actualInnerRadius
		local angle = -math.pi / 2 + index * math.pi / 5
		points[#points + 1] = pathPoint(PathMathApi, actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * radius)
	end

	return {
		Closed = true,
		Points = points,
	}
end

function SpinnerPresets.heartPath(PathMathApi: PathMathApi, center: Vector2?, scale: number?): PathData
	local actualCenter = center or Vector2.new(0.5, 0.52)
	local actualScale = scale or 0.022
	local points: { PathPoint } = {}

	for index = 0, 35 do
		local t = math.pi * 2 * index / 36
		local x = 16 * math.sin(t) ^ 3
		local y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
		points[#points + 1] = pathPoint(PathMathApi, actualCenter + Vector2.new(x, y) * actualScale)
	end

	return {
		Closed = true,
		Points = points,
	}
end

function SpinnerPresets.getPath(PathMathApi: PathMathApi, kind: SpinnerKind): PathData
	if kind == "Star" then
		return SpinnerPresets.starPath(PathMathApi)
	elseif kind == "Heart" then
		return SpinnerPresets.heartPath(PathMathApi)
	elseif kind == "Eight" then
		return SpinnerPresets.eightPath(PathMathApi)
	end

	return SpinnerPresets.circlePath(PathMathApi, 0.42)
end

SpinnerPresets.KindOrder = { "Star", "Heart", "Eight", "Circle" }

return SpinnerPresets