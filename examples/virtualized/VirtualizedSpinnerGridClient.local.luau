--!strict

local RunService = game:GetService("RunService")

local PathMath = require("@game/ReplicatedStorage/PathMath")
local VirtualizedUI = require("@game/ReplicatedStorage/VirtualizedUI")
local presets = require("./SpinnerPresets")

type PathConfig = PathMath.PathConfig
type PathInput = PathMath.PathInput
type CornerConfig = PathMath.CornerConfig
type StrokeConfig = PathMath.StrokeConfig
type LayoutConfig = VirtualizedUI.LayoutConfig
type LayoutPatch = VirtualizedUI.LayoutPatch
type VirtualizedOptions<T> = VirtualizedUI.Options<T>
type SpinnerKind = presets.SpinnerKind

type PathController = {
	Root: Frame,
	SetViewportSize: (PathController, Vector2) -> PathController,
	Update: (PathController, PathConfig) -> PathController,
}

type SpinnerItem = {
	kind: SpinnerKind,
	path: PathInput,
	color: Color3,
	backgroundColor: Color3,
	tileColor: Color3,
	stroke: StrokeConfig | false,
	corners: UDim | CornerConfig?,
	phase: number,
	pulsePhase: number,
	speed: number,
	pulseSpeed: number,
	progressBase: number,
	progressSwing: number,
}

type TileState = {
	background: PathController,
	spinner: PathController,
	item: SpinnerItem?,
	index: number?,
}

type SpinnerGrid = VirtualizedUI.VirtualizedUI<SpinnerItem>
type ScrollAnimationContext = VirtualizedUI.ScrollAnimationContext<SpinnerItem>

local DEFAULT_VIEWPORT_SIZE = Vector2.new(1920, 1080)
local BLACK = Color3.new(0, 0, 0)
local WHITE = Color3.new(1, 1, 1)

local gui = script.Parent :: ScreenGui
local canvas = gui:WaitForChild("Canvas") :: Frame
local grid = canvas:WaitForChild("Grid") :: ScrollingFrame
local template = canvas:WaitForChild("TileTemplate") :: Frame

local ITEM_COUNT = 10000
local ITEMS_PER_ROW = 10
local GAP = 10
local PADDING = 16

local rng = Random.new(os.clock() * 1000000)
local data: { SpinnerItem } = {}
local pathsByKind: { [SpinnerKind]: PathInput } = {}
local activeStates: { [number]: TileState } = {}
local stateByFrame: { [GuiObject]: TileState } = {}
local viewportControllers: { PathController } = {}
local viewportConnection: RBXScriptConnection? = nil
local clock = 0
local virtualizedUI: SpinnerGrid? = nil

local function brightColor(): Color3
	return Color3.fromHSV(rng:NextNumber(), rng:NextNumber(0.58, 0.9), rng:NextNumber(0.82, 1))
end

local function softTileColor(color: Color3): Color3
	return color:Lerp(WHITE, 0.84)
end

local function embeddedPathColor(tileColor: Color3): Color3
	return tileColor:Lerp(BLACK, 0.8)
end

local function strokeColor(color: Color3): Color3
	return Color3.new(color.R * 0.6, color.G * 0.6, color.B * 0.6)
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

local function createPathController(parent: GuiObject, config: PathConfig?): PathController
	local nextConfig: PathConfig = if config then table.clone(config) else {}
	nextConfig.ViewportSize = nextConfig.ViewportSize or DEFAULT_VIEWPORT_SIZE
	local controller = PathMath.new(parent, nextConfig) :: PathController
	return registerViewportController(controller)
end

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

local function randomCorners(): UDim | CornerConfig?
	local roll = rng:NextInteger(1, 4)
	if roll == 1 then
		return UDim.new(1, 0)
	elseif roll == 2 then
		return { Start = UDim.new(1, 0) }
	elseif roll == 3 then
		return { End = UDim.new(1, 0) }
	end
	return nil
end

local function resolvePath(kind: SpinnerKind): PathInput
	local path = pathsByKind[kind]
	if path == nil then
		path = presets.getPath(PathMath, kind)
		pathsByKind[kind] = path
	end
	return path
end

for index = 1, ITEM_COUNT do
	local kind: SpinnerKind = presets.KindOrder[rng:NextInteger(1, #presets.KindOrder)] or "Circle"
	local color = brightColor()
	local tileColor = softTileColor(color)
	local hasStroke = rng:NextNumber() < 0.5
	data[index] = {
		kind = kind,
		path = resolvePath(kind),
		color = color,
		backgroundColor = embeddedPathColor(tileColor),
		tileColor = tileColor,
		stroke = if hasStroke then { Width = rng:NextInteger(2, 5), Color = strokeColor(color) } else false,
		corners = randomCorners(),
		phase = rng:NextNumber(0, 1),
		pulsePhase = rng:NextNumber(0, math.pi * 2),
		speed = rng:NextNumber(0.2, 0.72),
		pulseSpeed = rng:NextNumber(2.2, 4.2),
		progressBase = rng:NextNumber(0.11, 0.18),
		progressSwing = rng:NextNumber(0.035, 0.08),
	}
end

local function makeLayer(parent: Instance, name: string): GuiObject
	local layer = Instance.new("Frame")
	layer.Name = name
	layer.AnchorPoint = Vector2.new(0.5, 0.5)
	layer.BackgroundTransparency = 1
	layer.BorderSizePixel = 0
	layer.Position = UDim2.fromScale(0.5, 0.5)
	layer.Size = UDim2.fromScale(0.74, 0.74)
	layer.Parent = parent

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = layer

	return layer
end

local function setupFrame(frame: GuiObject, _virtualizedUI: SpinnerGrid): ()
	frame.BackgroundColor3 = WHITE
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = false

	local backgroundLayer = makeLayer(frame, "StaticShape")
	local spinnerLayer = makeLayer(frame, "Spinner")

	local background = createPathController(backgroundLayer, {
		Name = "StaticPath",
		Path = resolvePath("Circle"),
		Progress = 1,
		Width = { Scale = 0.075, Min = 5, Max = 11, Basis = "ContainerMin" },
		Color = Color3.fromRGB(40, 40, 40),
		Corners = UDim.new(1, 0),
		ZIndex = 1,
	})

	local spinner = createPathController(spinnerLayer, {
		Name = "SpinnerPath",
		Path = resolvePath("Circle"),
		Progress = 0.16,
		Offset = 0,
		Width = { Scale = 0.08, Min = 5, Max = 12, Basis = "ContainerMin" },
		Color = Color3.fromRGB(117, 167, 255),
		Corners = { Start = UDim.new(1, 0) },
		ZIndex = 4,
		CornerZIndex = 3,
	})

	stateByFrame[frame] = {
		background = background,
		spinner = spinner,
		item = nil,
		index = nil,
	}
end

local function applyData(frame: GuiObject, item: SpinnerItem, index: number): ()
	local state = stateByFrame[frame]
	if state == nil then
		return
	end

	local previousIndex = state.index
	if previousIndex ~= nil and previousIndex ~= index then
		activeStates[previousIndex] = nil
	end

	if state.item ~= item then
		frame.BackgroundColor3 = item.tileColor

		local backgroundPatch: PathConfig = {
			Path = item.path,
			Progress = 1,
			Offset = item.phase,
			Color = item.backgroundColor,
			Corners = UDim.new(1, 0),
			Stroke = false,
		}
		state.background:Update(backgroundPatch)

		local spinnerPatch: PathConfig = {
			Path = item.path,
			Progress = item.progressBase,
			Offset = item.phase + clock * item.speed,
			Color = item.color,
			Corners = item.corners,
			Stroke = item.stroke,
		}
		state.spinner:Update(spinnerPatch)
	end

	state.index = index
	state.item = item
	activeStates[index] = state
end

local function hideItem(index: number, frame: GuiObject): ()
	activeStates[index] = nil
	local state = stateByFrame[frame]
	if state ~= nil then
		state.index = nil
		state.item = nil
	end
end

local function emptyAnimator(context: ScrollAnimationContext, onComplete: () -> ()): (() -> ())?
	context.scrollingFrame.CanvasPosition = context.toPosition
	onComplete()
	return nil
end

local function computeItemSize(): number
	local viewportWidth = grid.AbsoluteSize.X
	local innerWidth = math.max(0, viewportWidth - PADDING * 2)
	return math.max(24, math.floor((innerWidth - GAP * (ITEMS_PER_ROW - 1)) / ITEMS_PER_ROW))
end

local function applyLayout(): ()
	local ui = virtualizedUI
	if ui == nil then
		return
	end

	local itemSize = computeItemSize()
	local layoutPatch: LayoutPatch = {
		itemSize = UDim2.fromOffset(itemSize, itemSize),
		itemPadding = UDim2.fromOffset(GAP, GAP),
		maxItemsPerRow = ITEMS_PER_ROW,
		contentPadding = {
			left = PADDING,
			right = PADDING,
			top = PADDING,
			bottom = PADDING,
		},
	}
	ui:SetLayout(layoutPatch)
end

grid.ScrollBarThickness = 8
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.BackgroundColor3 = WHITE
grid.BorderSizePixel = 0
template.Parent = grid

local initialItemSize = computeItemSize()
local initialLayout: LayoutConfig = {
	type = "Grid",
	itemSize = UDim2.fromOffset(initialItemSize, initialItemSize),
	itemPadding = UDim2.fromOffset(GAP, GAP),
	maxItemsPerRow = ITEMS_PER_ROW,
	autoFit = false,
	horizontalAlignment = Enum.HorizontalAlignment.Left,
	verticalAlignment = Enum.VerticalAlignment.Top,
	contentPadding = {
		left = PADDING,
		right = PADDING,
		top = PADDING,
		bottom = PADDING,
	},
}

local virtualizedOptions: VirtualizedOptions<SpinnerItem> = {
	scrollingFrame = grid,
	itemTemplate = template,
	layout = initialLayout,
	bufferRows = 1,
	maxPoolSize = 140,
	scrollAnimationDuration = 0.25,
	scrollAnimator = emptyAnimator,
	data = data,
	onItemSetup = setupFrame,
	onApplyData = applyData,
	onItemHidden = hideItem,
	scrollBarThickness = 8,
}

virtualizedUI = VirtualizedUI.new(virtualizedOptions)

grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout)

RunService.RenderStepped:Connect(function(dt: number): ()
	clock += dt

	for index, state in activeStates do
		local item = state.item
		if item == nil then
			activeStates[index] = nil
			continue
		end

		local progress = item.progressBase + (math.sin(clock * item.pulseSpeed + item.pulsePhase) + 1) * item.progressSwing
		local spinnerPatch: PathConfig = {
			Progress = progress,
			Offset = item.phase + clock * item.speed,
		}
		state.spinner:Update(spinnerPatch)
	end
end)