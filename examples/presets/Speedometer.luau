--!strict

local Utility = require(script.Parent.Utility)

type ExampleContext = Utility.ExampleContext

local INK = Utility.Ink

local makePanel = Utility.makePanel
local normalizedHost = Utility.normalizedHost
local arcPath = Utility.arcPath
local makePath = Utility.makePath
local track = Utility.track

local function addNeedle(stage: Instance, color: Color3): Frame
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

local function addCenterDot(stage: Instance, color: Color3): Frame
	local dot = Instance.new("Frame")
	dot.Name = "CenterDot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(8, 8)
	dot.BackgroundColor3 = color
	dot.BorderSizePixel = 0
	dot.Parent = stage
	return dot
end

return function(context: ExampleContext): ()
	local stage = makePanel(context.Grid, "Speedometer", 5)
	local host = normalizedHost(stage, 0.76, 0.54)
	host.Position = UDim2.fromScale(0.5, 0.58)
	local path = arcPath(context.PathMath, 0.42, math.rad(145), math.rad(395))
	track(context, host, path, 7)
	local main = makePath(context, host, { Path = path, Progress = 0.45, Width = 7, Color = INK })
	local needle = addNeedle(host, INK)
	addCenterDot(host, INK)

	context.AddUpdate(function(_dt: number): ()
		local value = (math.sin(context.GetClock() * 1.25) + 1) / 2
		main:Update({ Progress = value })
		needle.Rotation = -135 + value * 270
	end)
end
