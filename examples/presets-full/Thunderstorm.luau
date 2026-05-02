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
local SOFT = Color3.fromRGB(190, 190, 190)
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

local function pathPoint(
	PathMath: PathMathApi,
	position: Vector2,
	leftTangent: Vector2?,
	rightTangent: Vector2?
): PathPoint
	return PathMath.point(position, leftTangent or Vector2.zero, rightTangent or Vector2.zero)
end

local function makePath(context: ExampleContext, parent: GuiObject, config: PathConfig): PathController
	if config.Color == nil then
		config.Color = INK
	end
	return context.PathMath.new(parent, config)
end

local function lightningPath(PathMath, random: Random, branch: number?): PathData
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
		points[#points + 1] = pathPoint(PathMath, Vector2.new(x, y))
	end

	return { Closed = false, Points = points }
end
return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Thunderstorm", 40)
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
		local nextPath = lightningPath(context.PathMath, random, random:NextNumber(-0.22, 0.22))
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

		local initialPath = lightningPath(context.PathMath, random)
		local glow =
			makePath(context, stage, { Path = initialPath, Progress = 0, Width = 9, Color = SOFT, Transparency = 0.82 })
		local bolt =
			makePath(context, stage, { Path = initialPath, Progress = 0, Width = 3, Color = INK, Transparency = 0.1 })
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
