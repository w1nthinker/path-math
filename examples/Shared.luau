--!strict

local PathMathModule = require("@game/ReplicatedStorage/PathMath")

type PathContext = PathMathModule.PathContext
export type PathPoint = PathMathModule.PathPoint
export type PathData = PathMathModule.PathData
export type PathInput = PathMathModule.PathInput
export type PathConfig = PathMathModule.PathConfig
export type StrokeConfig = PathMathModule.StrokeConfig
export type ResponsiveLength = PathMathModule.ResponsiveLength

export type PathController = {
	Root: Frame,
	SetViewportSize: (PathController, Vector2) -> PathController,
	Update: (PathController, PathConfig) -> PathController,
	Render: (PathController) -> PathController,
	GetPointAt: (PathController, number) -> Vector2,
	SetProgress: (PathController, number) -> PathController,
	SetOffset: (PathController, number) -> PathController,
}

export type PathMathApi = {
	new: (GuiObject, PathConfig?) -> PathController,
	create: (GuiObject, PathConfig?) -> PathController,
	Create: (GuiObject, PathConfig?) -> PathController,
	point: (Vector2 | UDim2, (Vector2 | UDim2)?, (Vector2 | UDim2)?) -> PathPoint,
}

export type ExampleContext = {
	PathMath: PathMathApi,
	Grid: Instance,
	AddUpdate: ((number) -> ()) -> (),
	GetClock: () -> number,
	GetViewportSize: () -> Vector2,
}

export type ShowcaseMode = "Circle" | "LoadingArc" | "Spinner" | "Gauge" | "Speedometer" | "HorizontalProgress" | "InfiniteEight" | "InfinityEightSpinner" | "NegativeProgress" | "StaticStar" | "StarSpinner" | "StaticHeart" | "HeartSpinner" | "FunctionDriven" | "DualGauge" | "SegmentedGauge" | "LevelGauge" | "OffsetChase" | "NestedRings" | "ResponsiveWidth" | "ViewportWidth" | "BezierWave" | "ZigZag" | "TrianglePath" | "DiamondPath" | "SquarePath" | "PentagonPath" | "SpiralTrace" | "SmoothSpiralTrace" | "OrbitFollower" | "LayeredArcs" | "TransparencySweep" | "StrokeShowcase" | "MovingEndpoints" | "PulseTunnel" | "SawBlade" | "UDim2Path" | "VectorArrayPath" | "RobloxIcon" | "RobloxSpinner" | "Thunderstorm"

local Shared = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local PANEL = Color3.fromRGB(247, 247, 247)
local INK = Color3.fromRGB(14, 14, 14)
local STRONG = Color3.fromRGB(44, 44, 44)
local MID = Color3.fromRGB(118, 118, 118)
local SOFT = Color3.fromRGB(190, 190, 190)
local FAINT = Color3.fromRGB(224, 224, 224)

Shared.White = WHITE
Shared.Ink = INK
Shared.Strong = STRONG
Shared.Mid = MID
Shared.Soft = SOFT
Shared.Faint = FAINT

function Shared.makePanel(grid: Instance, name: string, order: number): Frame
	local panel = Instance.new("Frame")
	panel.Name = name:gsub("%s+", "")
	panel.LayoutOrder = order
	panel.BackgroundColor3 = PANEL
	panel.BorderSizePixel = 0
	panel.Parent = grid

	local stroke = Instance.new("UIStroke")
	stroke.Color = FAINT
	stroke.Thickness = 1
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(12, 8)
	title.Size = UDim2.new(1, -24, 0, 22)
	title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	title.Text = name
	title.TextColor3 = INK
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local stage = Instance.new("Frame")
	stage.Name = "Stage"
	stage.BackgroundColor3 = WHITE
	stage.BorderSizePixel = 0
	stage.Position = UDim2.fromOffset(12, 36)
	stage.Size = UDim2.new(1, -24, 1, -48)
	stage.Parent = panel

	local stageStroke = Instance.new("UIStroke")
	stageStroke.Color = Color3.fromRGB(232, 232, 232)
	stageStroke.Thickness = 1
	stageStroke.Parent = stage

	return stage
end

function Shared.normalizedHost(stage: Instance, sizeScale: number?, yScale: number?): Frame
	local host = Instance.new("Frame")
	host.Name = "Host"
	host.AnchorPoint = Vector2.new(0.5, 0.5)
	host.Position = UDim2.fromScale(0.5, yScale or 0.5)
	host.Size = UDim2.fromScale(sizeScale or 0.78, sizeScale or 0.78)
	host.BackgroundTransparency = 1
	host.Parent = stage

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = host

	return host
end

function Shared.pathPoint(PathMath: PathMathApi, position: Vector2, leftTangent: Vector2?, rightTangent: Vector2?): PathPoint
	return PathMath.point(position, leftTangent or Vector2.zero, rightTangent or Vector2.zero)
end

function Shared.circlePath(PathMath: PathMathApi, radius: number?, center: Vector2?, segments: number?): PathData
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
		points[#points + 1] = Shared.pathPoint(PathMath, position, -tangent, tangent)
	end

	return { Closed = true, Points = points }
end

function Shared.arcPath(PathMath: PathMathApi, radius: number?, startAngle: number, endAngle: number, center: Vector2?, segments: number?): PathData
	local actualRadius = radius or 0.42
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local segmentCount = segments or math.max(2, math.ceil(math.abs(endAngle - startAngle) / (math.pi / 3)))
	local angleStep = (endAngle - startAngle) / segmentCount
	local handleLength = (4 / 3) * math.tan(math.abs(angleStep) / 4) * actualRadius
	local direction = if angleStep < 0 then -1 else 1
	local points: { PathPoint } = {}

	for index = 0, segmentCount do
		local angle = startAngle + angleStep * index
		local tangentAngle = angle + math.pi / 2 * direction
		local position = actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * actualRadius
		local tangent = Vector2.new(math.cos(tangentAngle), math.sin(tangentAngle)) * handleLength
		points[#points + 1] = Shared.pathPoint(PathMath, position, -tangent, tangent)
	end

	return { Closed = false, Points = points }
end

function Shared.linePath(PathMath: PathMathApi, startPoint: Vector2, endPoint: Vector2): PathData
	return {
		Closed = false,
		Points = {
			Shared.pathPoint(PathMath, startPoint),
			Shared.pathPoint(PathMath, endPoint),
		},
	}
end

function Shared.eightPath(PathMath: PathMathApi): PathData
	local k = 0.18
	return {
		Closed = true,
		Points = {
			Shared.pathPoint(PathMath, Vector2.new(0.50, 0.50), Vector2.new(0, -k), Vector2.new(0, k)),
			Shared.pathPoint(PathMath, Vector2.new(0.24, 0.50), Vector2.new(0, k), Vector2.new(0, -k)),
			Shared.pathPoint(PathMath, Vector2.new(0.50, 0.50), Vector2.new(0, -k), Vector2.new(0, k)),
			Shared.pathPoint(PathMath, Vector2.new(0.76, 0.50), Vector2.new(0, k), Vector2.new(0, -k)),
		},
	}
end

function Shared.starPath(PathMath: PathMathApi, outerRadius: number?, innerRadius: number?, center: Vector2?): PathData
	local actualOuterRadius = outerRadius or 0.43
	local actualInnerRadius = innerRadius or actualOuterRadius * 0.46
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local points: { PathPoint } = {}

	for index = 0, 9 do
		local radius = if index % 2 == 0 then actualOuterRadius else actualInnerRadius
		local angle = -math.pi / 2 + index * math.pi / 5
		points[#points + 1] = Shared.pathPoint(PathMath, actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * radius)
	end

	return { Closed = true, Points = points }
end

function Shared.polygonPath(PathMath: PathMathApi, sides: number, radius: number?, center: Vector2?, rotation: number?): PathData
	local actualRadius = radius or 0.42
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local actualRotation = rotation or -math.pi / 2
	local points: { PathPoint } = {}

	for index = 0, sides - 1 do
		local angle = actualRotation + index * math.pi * 2 / sides
		points[#points + 1] = Shared.pathPoint(PathMath, actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * actualRadius)
	end

	return { Closed = true, Points = points }
end
function Shared.heartPath(PathMath: PathMathApi, center: Vector2?, scale: number?): PathData
	local actualCenter = center or Vector2.new(0.5, 0.52)
	local actualScale = scale or 0.022
	local points: { PathPoint } = {}

	for index = 0, 35 do
		local t = math.pi * 2 * index / 36
		local x = 16 * math.sin(t) ^ 3
		local y = -(13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t))
		points[#points + 1] = Shared.pathPoint(PathMath, actualCenter + Vector2.new(x, y) * actualScale)
	end

	return { Closed = true, Points = points }
end

function Shared.robloxIconPath(PathMath: PathMathApi, center: Vector2?, outerSize: number?): PathData
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local halfOuter = (outerSize or 0.54) * 0.5
	local rotation = math.rad(35)
	local points: { PathPoint } = {}

	for index = 0, 3 do
		local angle = rotation + index * math.pi / 2
		points[#points + 1] = Shared.pathPoint(PathMath, actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * halfOuter)
	end

	return { Closed = true, Points = points }
end

function Shared.addRobloxMark(stage: Instance, color: Color3, backgroundColor: Color3): Frame
	local mark = Instance.new("Frame")
	mark.Name = "RobloxMark"
	mark.AnchorPoint = Vector2.new(0.5, 0.5)
	mark.Position = UDim2.fromScale(0.5, 0.5)
	mark.Size = UDim2.fromScale(0.5, 0.5)
	mark.BackgroundColor3 = color
	mark.BorderSizePixel = 0
	mark.Rotation = 10
	mark.Parent = stage

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = mark

	local hole = Instance.new("Frame")
	hole.Name = "Hole"
	hole.AnchorPoint = Vector2.new(0.5, 0.5)
	hole.Position = UDim2.fromScale(0.5, 0.5)
	hole.Size = UDim2.fromScale(0.22, 0.22)
	hole.BackgroundColor3 = backgroundColor
	hole.BorderSizePixel = 0
	hole.Parent = mark

	return mark
end

function Shared.wavePath(PathMath: PathMathApi, amplitude: number?, cycles: number?): PathData
	local actualAmplitude = amplitude or 0.16
	local actualCycles = cycles or 2
	local points: { PathPoint } = {}
	for index = 0, 7 do
		local t = index / 7
		local x = t
		local y = 0.5 + math.sin(t * math.pi * 2 * actualCycles) * actualAmplitude
		points[#points + 1] = Shared.pathPoint(PathMath, Vector2.new(x, y))
	end
	return { Closed = false, Points = points }
end

function Shared.zigZagPath(PathMath: PathMathApi, count: number?): PathData
	local pointCount = count or 9
	local points: { PathPoint } = {}
	for index = 0, pointCount - 1 do
		local t = index / (pointCount - 1)
		local y = if index % 2 == 0 then 0.28 else 0.72
		points[#points + 1] = Shared.pathPoint(PathMath, Vector2.new(t, y))
	end
	return { Closed = false, Points = points }
end

function Shared.spiralPath(PathMath: PathMathApi): PathData
	local points: { PathPoint } = {}
	for index = 0, 32 do
		local t = index / 32
		local angle = t * math.pi * 5.4
		local radius = 0.04 + t * 0.4
		points[#points + 1] = Shared.pathPoint(PathMath, Vector2.new(0.5, 0.5) + Vector2.new(math.cos(angle), math.sin(angle)) * radius)
	end
	return { Closed = false, Points = points }
end

function Shared.smoothSpiralPath(PathMath: PathMathApi): PathData
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

		points[#points + 1] = Shared.pathPoint(PathMath, center + radial * radius, -handle, handle)
	end

	return { Closed = false, Points = points }
end

function Shared.sawPath(PathMath: PathMathApi): PathData
	local points: { PathPoint } = {}
	for index = 0, 15 do
		local t = index / 15
		local y = if index % 2 == 0 then 0.32 else 0.68
		points[#points + 1] = Shared.pathPoint(PathMath, Vector2.new(t, y))
	end
	return { Closed = false, Points = points }
end

function Shared.squareDot(stage: Instance, color: Color3, size: number?): Frame
	local dot = Instance.new("Frame")
	dot.Name = "SquareDot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(size or 8, size or 8)
	dot.BackgroundColor3 = color

function Shared.lightningPath(PathMath: PathMathApi, random: Random, branch: number?): PathData
	local points: { PathPoint } = {}
	local segmentCount = 8
	local startX = random:NextNumber(0.18, 0.82)
	local drift = random:NextNumber(-0.24, 0.24)
	local branchOffset = branch or 0

	for index = 0, segmentCount do
		local t = index / segmentCount
		local bend = math.sin(t * math.pi) * drift
		local jitter = if index == 0 or index == segmentCount then 0 else random:NextNumber(-0.13, 0.13)
		local x = math.clamp(startX + bend + jitter + branchOffset * t, 0.04, 0.96)
		local y = t
		points[#points + 1] = Shared.pathPoint(PathMath, Vector2.new(x, y))
	end

	return { Closed = false, Points = points }
end

--function Shared.lightningPath(PathMath: PathMathApi, random: Random, branch: number?): PathData
--	local points: { PathPoint } = {}
--	local segmentCount = 8
--	local startX = random:NextNumber(0.18, 0.82)
--	local drift = random:NextNumber(-0.24, 0.24)
--	local branchOffset = branch or 0

--	for index = 0, segmentCount do
--		local t = index / segmentCount
--		local bend = math.sin(t * math.pi) * drift
--		local jitter = if index == 0 or index == segmentCount then 0 else random:NextNumber(-0.13, 0.13)
--		local x = math.clamp(startX + bend + jitter + branchOffset * t, 0.04, 0.96)
--		local y = t
--		points[#points + 1] = Shared.pathPoint(PathMath, Vector2.new(x, y))
--	end

--	return { Closed = false, Points = points }
--end
	dot.BorderSizePixel = 0
	dot.Parent = stage
	return dot
end

function Shared.addNeedle(stage: Instance, color: Color3): Frame
	local pivot = Instance.new("Frame")
	pivot.Name = "NeedlePivot"
	pivot.AnchorPoint = Vector2.new(0.5, 0.5)
	pivot.Position = UDim2.fromScale(0.5, 0.5)
	pivot.Size = UDim2.fromScale(1, 1)
	pivot.BackgroundTransparency = 1
	pivot.Parent = stage

	local needle = Instance.new("Frame")
	needle.Name = "Needle"
	needle.AnchorPoint = Vector2.new(0.5, 1)
	needle.Position = UDim2.fromScale(0.5, 0.5)
	needle.Size = UDim2.new(0, 3, 0.38, 0)
	needle.BackgroundColor3 = color
	needle.BorderSizePixel = 0
	needle.Parent = pivot

	return pivot
end

function Shared.addCenterDot(stage: Instance, color: Color3): Frame
	return Shared.squareDot(stage, color, 8)
end

local function makePath(context: ExampleContext, parent: GuiObject, config: PathConfig): PathController
	if config.Color == nil then
		config.Color = INK
	end
	return context.PathMath.new(parent, config)
end

local function track(context: ExampleContext, parent: GuiObject, path: PathInput, width: PathMathModule.ResponsiveLength?): PathController
	return makePath(context, parent, {
		Path = path,
		Progress = 1,
		Width = width or 7,
		Color = FAINT,
	})
end

local function addFollower(stage: GuiObject, controller: PathController, color: Color3, phase: number): Frame
	local dot = Shared.squareDot(stage, color, 7)
	dot.Position = UDim2.fromScale(controller:GetPointAt(phase).X, controller:GetPointAt(phase).Y)
	return dot
end

function Shared.makeShowcase(context: ExampleContext, name: string, order: number, mode: ShowcaseMode): ()
	local stage = Shared.makePanel(context.Grid, name, order)
	local host = Shared.normalizedHost(stage, 0.76, 0.54)
	local path: PathInput = Shared.circlePath(context.PathMath, 0.4)
	local main: PathController? = nil

	if mode == "Gauge" or mode == "Speedometer" or mode == "DualGauge" or mode == "SegmentedGauge" or mode == "LayeredArcs" then
		host.Position = UDim2.fromScale(0.5, 0.58)
		path = Shared.arcPath(context.PathMath, 0.42, math.rad(145), math.rad(395))
	elseif mode == "HorizontalProgress" or mode == "BezierWave" or mode == "ZigZag" or mode == "SawBlade" or mode == "MovingEndpoints" then
		host = stage
	end

	if mode == "Circle" then
		main = makePath(context, host, { Path = path, Progress = 1, Width = 9, Color = INK, Stroke = { Width = 2, Color = SOFT } })
		context.AddUpdate(function(_dt: number): ()
			local controller = main
			if controller then controller:Update({ Width = 8 + (math.sin(context.GetClock() * 2) + 1) * 2 }) end
		end)
	elseif mode == "LoadingArc" then
		track(context, host, path, 9)
		main = makePath(context, host, { Path = path, Progress = 0.28, Width = 9, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Offset = context.GetClock() * 0.35 }) end end)
	elseif mode == "Spinner" then
		main = makePath(context, host, { Path = path, Progress = 0.17, Width = { Scale = 0.011, Min = 7, Max = 12, Basis = "ViewportMin" }, Color = INK, ViewportSize = context.GetViewportSize() })
		context.AddUpdate(function(_dt: number): ()
			if main then main:Update({ Progress = 0.12 + (math.sin(context.GetClock() * 3) + 1) * 0.11, Offset = context.GetClock() * 0.55, ViewportSize = context.GetViewportSize() }) end
		end)
	elseif mode == "Gauge" then
		track(context, host, path, 8)
		main = makePath(context, host, { Path = path, Progress = 0.62, Width = 8, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Progress = (math.sin(context.GetClock() * 1.6) + 1) / 2 }) end end)
	elseif mode == "Speedometer" then
		track(context, host, path, 7)
		main = makePath(context, host, { Path = path, Progress = 0.45, Width = 7, Color = INK })
		local needle = Shared.addNeedle(host, INK)
		Shared.addCenterDot(host, INK)
		context.AddUpdate(function(_dt: number): ()
			local value = (math.sin(context.GetClock() * 1.25) + 1) / 2
			if main then main:Update({ Progress = value }) end
			needle.Rotation = -135 + value * 270
		end)
	elseif mode == "HorizontalProgress" then
		path = Shared.linePath(context.PathMath, Vector2.new(0, 0.5), Vector2.new(1, 0.5))
		track(context, stage, path, 8)
		main = makePath(context, stage, { Path = path, Progress = 0.5, Width = 8, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Progress = (math.sin(context.GetClock() * 2.2) + 1) / 2 }) end end)
	elseif mode == "InfiniteEight" or mode == "InfinityEightSpinner" then
		path = Shared.eightPath(context.PathMath)
		track(context, host, path, 7)
		main = makePath(context, host, { Path = path, Progress = if mode == "InfiniteEight" then 0.24 else 0.14, Width = 8, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Offset = context.GetClock() * 0.24, Progress = if mode == "InfinityEightSpinner" then 0.12 + (math.sin(context.GetClock() * 3) + 1) * 0.09 else 0.24 }) end end)
	elseif mode == "NegativeProgress" then
		track(context, host, path, 9)
		main = makePath(context, host, { Path = path, Progress = -0.35, Offset = 0.75, Width = 9, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Progress = -0.18 - (math.sin(context.GetClock() * 2.6) + 1) * 0.22, Offset = 0.75 + context.GetClock() * 0.2 }) end end)
	elseif mode == "StaticStar" or mode == "StarSpinner" then
		path = Shared.starPath(context.PathMath)
		track(context, host, path, 6)
		main = makePath(context, host, { Path = path, Progress = if mode == "StaticStar" then 1 else 0.34, Width = 7, Color = INK })
		if mode ~= "StaticStar" then context.AddUpdate(function(_dt: number): () if main then main:Update({ Offset = context.GetClock() * 0.16, Progress = 0.22 + (math.sin(context.GetClock() * 2) + 1) * 0.16 }) end end) end
	elseif mode == "StaticHeart" or mode == "HeartSpinner" then
		path = Shared.heartPath(context.PathMath)
		track(context, host, path, 6)
		main = makePath(context, host, { Path = path, Progress = if mode == "StaticHeart" then 1 else 0.42, Width = 7, Color = INK })
		if mode ~= "StaticHeart" then context.AddUpdate(function(_dt: number): () if main then main:Update({ Offset = context.GetClock() * 0.12, Width = 6 + (math.sin(context.GetClock() * 4) + 1) * 2 }) end end) end
	elseif mode == "FunctionDriven" then
		main = makePath(context, host, {
			Path = function(_pathContext: PathContext): PathData
				return Shared.circlePath(context.PathMath, 0.29 + (math.sin(context.GetClock() * 2) + 1) * 0.065, Vector2.new(0.5, 0.5), 6)
			end,
			Progress = 0.84,
			Width = 8,
			Color = INK,
		})
		context.AddUpdate(function(_dt: number): () if main then main:Render() end end)
	elseif mode == "DualGauge" then
		track(context, host, path, 7)
		local primary = makePath(context, host, { Path = path, Progress = 0.45, Width = 7, Color = INK })
		local secondary = makePath(context, host, { Path = Shared.arcPath(context.PathMath, 0.31, math.rad(145), math.rad(395)), Progress = 0.7, Width = 5, Color = MID })
		context.AddUpdate(function(_dt: number): () primary:Update({ Progress = (math.sin(context.GetClock() * 1.4) + 1) / 2 }); secondary:Update({ Progress = (math.cos(context.GetClock() * 1.9) + 1) / 2 }) end)
	elseif mode == "SegmentedGauge" then
		local segments: { PathController } = {}
		for index = 1, 12 do
			local startAngle = math.rad(150 + (index - 1) * 20)
			local endAngle = math.rad(164 + (index - 1) * 20)
			track(context, host, Shared.arcPath(context.PathMath, 0.42, startAngle, endAngle), 7)
			segments[index] = makePath(context, host, { Path = Shared.arcPath(context.PathMath, 0.42, startAngle, endAngle), Progress = 0, Width = 7, Color = if index < 5 then INK elseif index < 9 then STRONG else MID, Transparency = 0.75 })
		end
		context.AddUpdate(function(_dt: number): ()
			local scaled = ((math.sin(context.GetClock() * 1.4) + 1) / 2) * #segments
			for index = 1, #segments do
				local progress = math.clamp(scaled - (index - 1), 0, 1)
				segments[index]:Update({ Progress = progress, Transparency = if progress > 0 then 0 else 0.75 })
			end
		end)
	elseif mode == "LevelGauge" then
		local levels: { PathController } = {}
		for index = 1, 5 do
			local y = 0.76 - index * 0.11
			levels[index] = makePath(context, stage, { Path = Shared.linePath(context.PathMath, Vector2.new(0, y), Vector2.new(1, y)), Progress = 0, Width = 6, Color = if index == 5 then INK else MID, Transparency = 0.72 })
		end
		context.AddUpdate(function(_dt: number): ()
			local value = ((math.sin(context.GetClock() * 1.8) + 1) / 2) * #levels
			for index = 1, #levels do local progress = math.clamp(value - (index - 1), 0, 1); levels[index]:Update({ Progress = progress, Transparency = if progress > 0 then 0 else 0.72 }) end
		end)
	elseif mode == "OffsetChase" then
		track(context, host, path, 5)
		local a = makePath(context, host, { Path = path, Progress = 0.12, Width = 6, Color = INK })
		local b = makePath(context, host, { Path = path, Progress = 0.12, Width = 6, Color = MID, Offset = 0.33 })
		local c = makePath(context, host, { Path = path, Progress = 0.12, Width = 6, Color = SOFT, Offset = 0.66 })
		context.AddUpdate(function(_dt: number): () local t = context.GetClock() * 0.22; a:Update({ Offset = t }); b:Update({ Offset = t + 0.33 }); c:Update({ Offset = t + 0.66 }) end)
	elseif mode == "NestedRings" or mode == "PulseTunnel" then
		local rings: { PathController } = {}
		for index = 1, 5 do rings[index] = makePath(context, host, { Path = Shared.circlePath(context.PathMath, 0.14 + index * 0.055), Progress = 1, Width = 3 + index, Color = if index % 2 == 0 then MID else INK, Transparency = index * 0.08 }) end
		if mode == "PulseTunnel" then context.AddUpdate(function(_dt: number): () for index = 1, #rings do rings[index]:Update({ Width = 3 + index + (math.sin(context.GetClock() * 2 + index) + 1) * 1.5 }) end end) end
	elseif mode == "ResponsiveWidth" or mode == "ViewportWidth" then
		local width: ResponsiveLength = if mode == "ResponsiveWidth" then { Scale = 0.08, Min = 4, Max = 18, Basis = "ContainerMin" } else { Scale = 0.01, Min = 4, Max = 14, Basis = "ViewportMin" }
		main = makePath(context, host, { Path = path, Progress = 0.78, Width = width, Color = INK, ViewportSize = context.GetViewportSize() })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Offset = context.GetClock() * 0.1, ViewportSize = context.GetViewportSize() }) end end)
	elseif mode == "BezierWave" then
		path = Shared.wavePath(context.PathMath, 0.16, 2)
		track(context, stage, path, 5)
		main = makePath(context, stage, { Path = path, Progress = 0.38, Width = 7, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Offset = context.GetClock() * 0.18 }) end end)
	elseif mode == "ZigZag" or mode == "SawBlade" then
		path = if mode == "ZigZag" then Shared.zigZagPath(context.PathMath, 9) else Shared.sawPath(context.PathMath)
		track(context, stage, path, 5)
		main = makePath(context, stage, { Path = path, Progress = 0.55, Width = 6, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Progress = (math.sin(context.GetClock() * 2) + 1) / 2 }) end end)
	elseif mode == "TrianglePath" or mode == "DiamondPath" or mode == "SquarePath" or mode == "PentagonPath" then
		local sides = if mode == "TrianglePath" then 3 elseif mode == "PentagonPath" then 5 else 4
		local rotation = if mode == "DiamondPath" then math.pi / 4 else -math.pi / 2
		path = Shared.polygonPath(context.PathMath, sides, 0.4, Vector2.new(0.5, 0.5), rotation)
		track(context, host, path, 5)
		main = makePath(context, host, { Path = path, Progress = 0.72, Width = 7, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Offset = context.GetClock() * 0.12 }) end end)
	elseif mode == "SpiralTrace" or mode == "SmoothSpiralTrace" then
		path = if mode == "SmoothSpiralTrace" then Shared.smoothSpiralPath(context.PathMath) else Shared.spiralPath(context.PathMath)
		track(context, host, path, 4)
		main = makePath(context, host, { Path = path, Progress = 0.6, Width = 6, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Progress = (math.sin(context.GetClock() * 1.6) + 1) / 2 }) end end)
	elseif mode == "OrbitFollower" then
		main = makePath(context, host, { Path = path, Progress = 1, Width = 5, Color = FAINT })
		local dotA = addFollower(host, main, INK, 0)
		local dotB = addFollower(host, main, MID, 0.5)
		context.AddUpdate(function(_dt: number): () if main then local t = context.GetClock() * 0.18; local p1 = main:GetPointAt(t); local p2 = main:GetPointAt(t + 0.5); dotA.Position = UDim2.fromScale(p1.X, p1.Y); dotB.Position = UDim2.fromScale(p2.X, p2.Y) end end)
	elseif mode == "LayeredArcs" then
		for index = 1, 5 do makePath(context, host, { Path = Shared.arcPath(context.PathMath, 0.18 + index * 0.045, math.rad(150), math.rad(150 + index * 38)), Progress = 1, Width = 4 + index, Color = if index % 2 == 0 then MID else INK, Transparency = index * 0.08 }) end
	elseif mode == "TransparencySweep" then
		track(context, host, path, 8)
		main = makePath(context, host, { Path = path, Progress = 0.5, Width = 8, Color = INK, Transparency = 0 })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Offset = context.GetClock() * 0.2, Transparency = (math.sin(context.GetClock() * 2.5) + 1) * 0.35 }) end end)
	elseif mode == "StrokeShowcase" then
		main = makePath(context, host, { Path = Shared.starPath(context.PathMath, 0.39, 0.2), Progress = 1, Width = 5, Color = INK, Stroke = { Width = 4, Color = SOFT } })
	elseif mode == "MovingEndpoints" then
		main = makePath(context, stage, {
			Path = function(_pathContext: PathContext): PathData
				local t = context.GetClock()
				return Shared.linePath(context.PathMath, Vector2.new(0, 0.5 + math.sin(t) * 0.22), Vector2.new(1, 0.5 + math.cos(t * 1.3) * 0.22))
			end,
			Progress = 1,
			Width = 7,
			Color = INK,
		})
		context.AddUpdate(function(_dt: number): () if main then main:Render() end end)
	elseif mode == "RobloxIcon" or mode == "RobloxSpinner" then
		Shared.addRobloxMark(host, INK, WHITE)
		path = Shared.robloxIconPath(context.PathMath)
		main = makePath(context, host, { Path = path, Progress = if mode == "RobloxIcon" then 1 else 0.24, Width = 4, Color = if mode == "RobloxIcon" then WHITE else INK })
		if mode == "RobloxSpinner" then
			context.AddUpdate(function(_dt: number): ()
				if main then
					main:Update({
						Offset = context.GetClock() * 0.18,
						Progress = 0.16 + (math.sin(context.GetClock() * 2.8) + 1) * 0.08,
					})
				end
			end)
		end
	elseif mode == "UDim2Path" then
		local udimPath: PathData = {
			Closed = false,
			Points = {
				Shared.pathPoint(context.PathMath, Vector2.new(0, 0.78)),
				Shared.pathPoint(context.PathMath, Vector2.new(0.28, 0.22)),
				Shared.pathPoint(context.PathMath, Vector2.new(0.56, 0.78)),
				Shared.pathPoint(context.PathMath, Vector2.new(1, 0.22)),
			},
		}
		track(context, stage, udimPath, 5)
		main = makePath(context, stage, { Path = udimPath, Progress = 0.7, Width = 7, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Offset = context.GetClock() * 0.12 }) end end)
	elseif mode == "VectorArrayPath" then
		local vectorPath: { Vector2 } = { Vector2.new(0.12, 0.72), Vector2.new(0.28, 0.3), Vector2.new(0.44, 0.62), Vector2.new(0.6, 0.24), Vector2.new(0.82, 0.68) }
		main = makePath(context, stage, { Path = vectorPath, Progress = 0.76, Width = 7, Color = INK })
		context.AddUpdate(function(_dt: number): () if main then main:Update({ Progress = (math.sin(context.GetClock() * 2.1) + 1) / 2 }) end end)
	elseif mode == "Thunderstorm" then
		stage.ClipsDescendants = true

		type StormStrike = {
			bolt: PathController,
			glow: PathController,
			gradient: UIGradient,
			age: number,
			duration: number,
			delay: number,
		}

		local random = Random.new(4108)
		local strikes: { StormStrike } = {}

		local function randomizeStrike(strike: StormStrike, index: number): ()
			local nextPath = Shared.lightningPath(context.PathMath, random, random:NextNumber(-0.22, 0.22))
			strike.duration = random:NextNumber(0.55, 1.05)
			strike.delay = random:NextNumber(0.05, 0.42)
			strike.age = -strike.delay
			strike.gradient.Rotation = random:NextNumber(-18, 18)
			strike.gradient.Offset = Vector2.new(0, -1)
			strike.bolt:Update({ Path = nextPath, Progress = 0, Offset = 0, Transparency = 0.05, Width = 3 + index % 3 })
			strike.glow:Update({ Path = nextPath, Progress = 0, Offset = 0, Transparency = 0.78, Width = 8 + index % 3 })
		end

		for index = 1, 7 do
			local flash = Instance.new("Frame")
			flash.Name = "LightningGradient"
			flash.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
			flash.BackgroundTransparency = 0.78
			flash.BorderSizePixel = 0
			flash.Size = UDim2.fromScale(1, 1)
			flash.Parent = stage

			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, WHITE),
				ColorSequenceKeypoint.new(0.48, Color3.fromRGB(205, 205, 205)),
				ColorSequenceKeypoint.new(0.52, INK),
				ColorSequenceKeypoint.new(1, WHITE),
			})
			gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.46, 0.88),
				NumberSequenceKeypoint.new(0.5, 0.18),
				NumberSequenceKeypoint.new(0.54, 0.88),
				NumberSequenceKeypoint.new(1, 1),
			})
			gradient.Offset = Vector2.new(0, -1)
			gradient.Parent = flash

			local initialPath = Shared.lightningPath(context.PathMath, random)
			local glow = makePath(context, stage, { Path = initialPath, Progress = 0, Width = 9, Color = SOFT, Transparency = 0.82 })
			local bolt = makePath(context, stage, { Path = initialPath, Progress = 0, Width = 3, Color = INK, Transparency = 0.1 })
			local strike: StormStrike = {
				bolt = bolt,
				glow = glow,
				gradient = gradient,
				age = -index * 0.14,
				duration = 0.8,
				delay = index * 0.08,
			}
			strikes[index] = strike
			randomizeStrike(strike, index)
		end

		context.AddUpdate(function(dt: number): ()
			for index = 1, #strikes do
				local strike = strikes[index]
				strike.age += dt
				if strike.age > strike.duration then
					randomizeStrike(strike, index)
				else
					local t = math.clamp(strike.age / strike.duration, 0, 1)
					local draw = if t < 0.48 then t / 0.48 else 1 - (t - 0.48) / 0.52
					local flash = 1 - math.abs(t * 2 - 1)
					strike.gradient.Offset = Vector2.new(0, -1 + 2 * flash)
					strike.bolt:Update({ Progress = math.clamp(draw, 0, 1), Transparency = 0.04 + t * 0.38 })
					strike.glow:Update({ Progress = math.clamp(draw, 0, 1), Transparency = 0.68 + t * 0.22 })
				end
			end
		end)
	end
end

return Shared