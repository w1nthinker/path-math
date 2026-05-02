--!strict

local PathMathModule = require("@game/ReplicatedStorage/PathMath")

type PathContext = PathMathModule.PathContext
type PathPoint = PathMathModule.PathPoint
type PathData = PathMathModule.PathData
type PathInput = PathMathModule.PathInput
type PathConfig = PathMathModule.PathConfig
type StrokeConfig = PathMathModule.StrokeConfig
type ResponsiveLength = PathMathModule.ResponsiveLength

type PathController = {
	Root: Frame,
	SetViewportSize: (PathController, Vector2) -> PathController,
	Update: (PathController, PathConfig) -> PathController,
	Render: (PathController) -> PathController,
	GetPointAt: (PathController, number) -> Vector2,
	SetProgress: (PathController, number) -> PathController,
	SetOffset: (PathController, number) -> PathController,
}

type PathMathApi = {
	new: (GuiObject, PathConfig?) -> PathController,
	create: (GuiObject, PathConfig?) -> PathController,
	Create: (GuiObject, PathConfig?) -> PathController,
	point: (Vector2 | UDim2, (Vector2 | UDim2)?, (Vector2 | UDim2)?) -> PathPoint,
}

type ExampleContext = {
	PathMath: PathMathApi,
	Grid: Instance,
	AddUpdate: ((number) -> ()) -> (),
	GetClock: () -> number,
	GetViewportSize: () -> Vector2,
}

local WHITE = Color3.fromRGB(255, 255, 255)
local PANEL = Color3.fromRGB(247, 247, 247)
local INK = Color3.fromRGB(14, 14, 14)
local FAINT = Color3.fromRGB(224, 224, 224)

local function makePanel(grid: Instance, name: string, order: number): Frame
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
	title.FontFace =
		Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
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

local function normalizedHost(stage: Instance, sizeScale: number?, yScale: number?): Frame
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

local function pathPoint(
	PathMath: PathMathApi,
	position: Vector2,
	leftTangent: Vector2?,
	rightTangent: Vector2?
): PathPoint
	return PathMath.point(position, leftTangent or Vector2.zero, rightTangent or Vector2.zero)
end

local function circlePath(PathMath: PathMathApi, radius: number?, center: Vector2?, segments: number?): PathData
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
		points[#points + 1] = pathPoint(PathMath, position, -tangent, tangent)
	end

	return { Closed = true, Points = points }
end

local function makePath(context: ExampleContext, parent: GuiObject, config: PathConfig): PathController
	if config.Color == nil then
		config.Color = INK
	end
	return context.PathMath.new(parent, config)
end

local function track(
	context: ExampleContext,
	parent: GuiObject,
	path: PathInput,
	width: ResponsiveLength?
): PathController
	return makePath(context, parent, {
		Path = path,
		Progress = 1,
		Width = width or 7,
		Color = FAINT,
	})
end

local function polygonPath(PathMath, sides: number, radius: number?, center: Vector2?, rotation: number?): PathData
	local actualRadius = radius or 0.42
	local actualCenter = center or Vector2.new(0.5, 0.5)
	local actualRotation = rotation or -math.pi / 2
	local points: { PathPoint } = {}

	for index = 0, sides - 1 do
		local angle = actualRotation + index * math.pi * 2 / sides
		points[#points + 1] =
			pathPoint(PathMath, actualCenter + Vector2.new(math.cos(angle), math.sin(angle)) * actualRadius)
	end

	return { Closed = true, Points = points }
end
return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Square Path", 26)
	local host = normalizedHost(stage, 0.76, 0.54)
	local path = circlePath(context.PathMath, 0.4)
	path = polygonPath(context.PathMath, 4, 0.4, Vector2.new(0.5, 0.5), -math.pi / 2)
	track(context, host, path, 5)
	local main = makePath(context, host, { Path = path, Progress = 0.72, Width = 7, Color = INK })

	context.AddUpdate(function(_dt: number): ()
		main:Update({ Offset = context.GetClock() * 0.12 })
	end)
end
