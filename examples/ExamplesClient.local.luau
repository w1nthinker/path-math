--!strict

local RunService = game:GetService("RunService")

local PathMathModule = require("@game/ReplicatedStorage/PathMath")
local Utility = require("./Examples/Utility")

type PathConfig = Utility.PathConfig
type PathController = Utility.PathController
type PathMathApi = Utility.PathMathApi
type ExampleContext = Utility.ExampleContext

local DEFAULT_VIEWPORT_SIZE = Vector2.new(1920, 1080)

local gui = script.Parent :: ScreenGui
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local canvas = gui:WaitForChild("Canvas") :: Frame
local grid = canvas:WaitForChild("Grid") :: ScrollingFrame
local layout = grid:WaitForChild("Layout") :: UIGridLayout
local examplesFolder = gui:WaitForChild("Examples") :: Folder

canvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
canvas.BorderSizePixel = 0
grid.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
grid.BorderSizePixel = 0
grid.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90)
grid.ScrollBarThickness = 6
layout.CellSize = UDim2.new(0.25, -12, 0.5, -12)
layout.FillDirectionMaxCells = 4

local gridChildren = grid:GetChildren()
for index = 1, #gridChildren do
	local child = gridChildren[index]
	if child ~= layout then
		child:Destroy()
	end
end

local updates: { (number) -> () } = {}
local viewportControllers: { PathController } = {}
local viewportConnection: RBXScriptConnection? = nil
local clock = 0

local function addUpdate(callback: (number) -> ()): ()
	updates[#updates + 1] = callback
end

local function getClock(): number
	return clock
end

local function getViewportSize(): Vector2
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return DEFAULT_VIEWPORT_SIZE
end

local function updateControllerViewportSize(controller: PathController, viewportSize: Vector2): ()
	controller:SetViewportSize(viewportSize)
end

local function registerViewportController(controller: PathController): PathController
	viewportControllers[#viewportControllers + 1] = controller
	updateControllerViewportSize(controller, getViewportSize())
	return controller
end

local function newPath(parent: GuiObject, config: PathConfig?): PathController
	local nextConfig: PathConfig = if config then table.clone(config) else {}
	nextConfig.ViewportSize = nextConfig.ViewportSize or DEFAULT_VIEWPORT_SIZE
	local controller = PathMathModule.new(parent, nextConfig) :: PathController
	return registerViewportController(controller)
end

local PathMath: PathMathApi = {
	new = newPath,
	create = newPath,
	Create = newPath,
	point = PathMathModule.point,
}

local function updateViewportSizes(): ()
	local viewportSize = getViewportSize()
	for index = #viewportControllers, 1, -1 do
		local controller = viewportControllers[index]
		if controller.Root.Parent ~= nil then
			updateControllerViewportSize(controller, viewportSize)
		else
			table.remove(viewportControllers, index)
		end
	end
end

local function connectViewportSizeListener(): ()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end

	local camera = workspace.CurrentCamera
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateViewportSizes)
	end
	updateViewportSizes()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectViewportSizeListener)
connectViewportSizeListener()

local context: ExampleContext = {
	PathMath = PathMath,
	Grid = grid,
	AddUpdate = addUpdate,
	GetClock = getClock,
	GetViewportSize = getViewportSize,
}

local exampleModules: { ModuleScript } = {
	examplesFolder:WaitForChild("Circle") :: ModuleScript,
	examplesFolder:WaitForChild("LoadingArc") :: ModuleScript,
	examplesFolder:WaitForChild("Spinner") :: ModuleScript,
	examplesFolder:WaitForChild("Gauge") :: ModuleScript,
	examplesFolder:WaitForChild("Speedometer") :: ModuleScript,
	examplesFolder:WaitForChild("HorizontalProgress") :: ModuleScript,
	examplesFolder:WaitForChild("InfiniteEight") :: ModuleScript,
	examplesFolder:WaitForChild("InfinityEightSpinner") :: ModuleScript,
	examplesFolder:WaitForChild("StaticStar") :: ModuleScript,
	examplesFolder:WaitForChild("StarSpinner") :: ModuleScript,
	examplesFolder:WaitForChild("StaticHeart") :: ModuleScript,
	examplesFolder:WaitForChild("HeartSpinner") :: ModuleScript,
	examplesFolder:WaitForChild("FunctionDriven") :: ModuleScript,
	examplesFolder:WaitForChild("DualGauge") :: ModuleScript,
	examplesFolder:WaitForChild("SegmentedGauge") :: ModuleScript,
	examplesFolder:WaitForChild("LevelGauge") :: ModuleScript,
	examplesFolder:WaitForChild("OffsetChase") :: ModuleScript,
	examplesFolder:WaitForChild("NestedRings") :: ModuleScript,
	examplesFolder:WaitForChild("ResponsiveWidth") :: ModuleScript,
	examplesFolder:WaitForChild("ViewportWidth") :: ModuleScript,
	examplesFolder:WaitForChild("BezierWave") :: ModuleScript,
	examplesFolder:WaitForChild("ZigZag") :: ModuleScript,
	examplesFolder:WaitForChild("TrianglePath") :: ModuleScript,
	examplesFolder:WaitForChild("DiamondPath") :: ModuleScript,
	examplesFolder:WaitForChild("SquarePath") :: ModuleScript,
	examplesFolder:WaitForChild("PentagonPath") :: ModuleScript,
	examplesFolder:WaitForChild("SpiralTrace") :: ModuleScript,
	examplesFolder:WaitForChild("SmoothSpiralTrace") :: ModuleScript,
	examplesFolder:WaitForChild("OrbitFollower") :: ModuleScript,
	examplesFolder:WaitForChild("LayeredArcs") :: ModuleScript,
	examplesFolder:WaitForChild("TransparencySweep") :: ModuleScript,
	examplesFolder:WaitForChild("StrokeShowcase") :: ModuleScript,
	examplesFolder:WaitForChild("MovingEndpoints") :: ModuleScript,
	examplesFolder:WaitForChild("PulseTunnel") :: ModuleScript,
	examplesFolder:WaitForChild("SawBlade") :: ModuleScript,
	examplesFolder:WaitForChild("UDim2Path") :: ModuleScript,
	examplesFolder:WaitForChild("VectorArrayPath") :: ModuleScript,
	examplesFolder:WaitForChild("RobloxIcon") :: ModuleScript,
	examplesFolder:WaitForChild("RobloxSpinner") :: ModuleScript,
	examplesFolder:WaitForChild("Thunderstorm") :: ModuleScript,
}

for index = 1, #exampleModules do
	local setup = require(exampleModules[index]) :: (ExampleContext) -> ()
	setup(context)
end

RunService.RenderStepped:Connect(function(dt: number): ()
	clock += dt
	for index = 1, #updates do
		updates[index](dt)
	end
end)
