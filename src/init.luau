--!strict
--!optimize 2
--!native

export type WidthBasis = "ContainerMin" | "ContainerX" | "ContainerY" | "ViewportMin" | "ViewportX" | "ViewportY"

export type ResponsiveLength = number | UDim | {
	Scale: number?,
	Offset: number?,
	Min: number?,
	Max: number?,
	Basis: WidthBasis?,
}

export type PathPoint = {
	Position: Vector2,
	LeftTangent: Vector2,
	RightTangent: Vector2,
}

type CurvePoint = {
	Position: vector,
	LeftTangent: vector,
	RightTangent: vector,
}

export type PathData = {
	Points: { PathPoint },
	Closed: boolean?,
}

export type PathContext = {
	Config: PathConfig,
	Progress: number,
	Offset: number,
	Controller: Controller,
}

export type PathInput = PathData | { PathPoint } | { Vector2 } | { UDim2 } | (PathContext) -> PathData

export type StrokeConfig = {
	Width: ResponsiveLength,
	Color: Color3,
}

export type CornerConfig = {
	Start: UDim?,
	End: UDim?,
}

export type PathConfig = {
	Name: string?,
	Path: PathInput?,
	Points: PathInput?,
	Closed: boolean?,
	Progress: number?,
	Offset: number?,
	Samples: number?,
	SamplesPerSegment: number?,
	Width: ResponsiveLength?,
	Thickness: ResponsiveLength?,
	ViewportSize: Vector2?,
	Color: Color3?,
	Color3: Color3?,
	Transparency: number?, -- stroke only, wrap the Path2D in a CanvasGroup if you want path transparency
	Visible: boolean?,
	ZIndex: number?,
	CornerZIndex: number?,
	CapZIndex: number?,
	Position: UDim2?,
	Size: UDim2?,
	AnchorPoint: Vector2?,
	Corners: (UDim | CornerConfig | true)?,
	Stroke: (StrokeConfig | Color3 | false)?,
}

type CubicSegment = {
	P0: vector,
	P1: vector,
	P2: vector,
	P3: vector,
}

type SourcePath = {
	Points: { CurvePoint },
	Closed: boolean,
	Polyline: { vector },
	Cumulative: { number },
	Segments: { CubicSegment },
	SamplesPerSegment: number,
	Length: number,
}

type RenderTarget = {
	Root: Frame,
	MainPath: Path2D,
	StrokePath: Path2D?,
	Caps: { [string]: Instance },
	Config: PathConfig,
}

local CURVE_EPSILON: number = 1 / 100_000
local DEFAULT_SAMPLES_PER_SEGMENT: number = 24
local SOURCE_DIRTY_KEYS: { [string]: boolean } = { Path = true, Points = true, Closed = true, Samples = true, SamplesPerSegment = true }
local ROUND_CORNERS = UDim.new(1, 0)
local VECTOR2_ZERO: Vector2 = Vector2.zero

local Controller = {}
Controller.__index = Controller

export type Controller = typeof(setmetatable({} :: {
	Root: Frame,
	MainPath: Path2D,
	StrokePath: Path2D?,
	Caps: { [string]: Instance },
	Config: PathConfig,
	_source: SourcePath?,
	_sourceDirty: boolean,
}, Controller))

local function clamp01(value: number): number
	return if value < 0 then 0 elseif value > 1 then 1 else value
end

local function wrap01(value: number): number
	local wrapped = value % 1
	return if wrapped < 0 then wrapped + 1 else wrapped
end

local function vectorFromAny(value: any): Vector2
	local valueType = typeof(value)
	
	if valueType == "Vector2" then
		return value
	elseif valueType == "UDim2" then
		return Vector2.new(value.X.Scale, value.Y.Scale)
	elseif valueType == "table" then
		return Vector2.new(value.X or value.x or value[1] or 0, value.Y or value.y or value[2] or 0)
	else
		return VECTOR2_ZERO
	end
end

local function vectorToVector2(value: vector): Vector2
	return Vector2.new(value.x, value.y)
end

local function vector2ToVector(value: Vector2): vector
	return vector.create(value.X, value.Y)
end

local function pointFromAny(value: any): PathPoint
	if typeof(value) == "Vector2" or typeof(value) == "UDim2" then
		return {
			Position = vectorFromAny(value),
			LeftTangent = VECTOR2_ZERO,
			RightTangent = VECTOR2_ZERO,
		}
	else
		return {
			Position = vectorFromAny(value.Position or value.position or value.Point or value.point or value[1]),
			LeftTangent = vectorFromAny(value.LeftTangent or value.leftTangent or value.InTangent or value.inTangent or value[2]),
			RightTangent = vectorFromAny(value.RightTangent or value.rightTangent or value.OutTangent or value.outTangent or value[3]),
		}
	end
end

local function bezier(p0: vector, p1: vector, p2: vector, p3: vector, t: number): vector
	local inverse = 1 - t
	local inverse2 = inverse ^ 2
	local t2 = t ^ 2

	return p0 * (inverse2 * inverse) + p1 * (3 * inverse2 * t) + p2 * (3 * inverse * t2) + p3 * (t2 * t)
end

local function samplePath(points: { PathPoint }, closed: boolean, samplesPerSegment: number?): SourcePath
	local sampleCount = samplesPerSegment or DEFAULT_SAMPLES_PER_SEGMENT
	local curvePoints: { CurvePoint } = {}
	local polyline: { vector } = {}
	local cumulative: { number } = {}
	local segments: { CubicSegment } = {}
	local totalLength = 0
	local pointCount = #points

	for index = 1, pointCount do
		local point = points[index]
		curvePoints[index] = {
			Position = vector2ToVector(point.Position),
			LeftTangent = vector2ToVector(point.LeftTangent),
			RightTangent = vector2ToVector(point.RightTangent),
		}
	end

	polyline[1] = curvePoints[1].Position
	cumulative[1] = 0

	for segmentIndex = 1, if closed then pointCount else pointCount - 1 do
		local current = curvePoints[segmentIndex]
		local nextPoint = curvePoints[(segmentIndex % pointCount) + 1]
		local p0 = current.Position
		local p1 = current.Position + current.RightTangent
		local p2 = nextPoint.Position + nextPoint.LeftTangent
		local p3 = nextPoint.Position
		local last = p0

		segments[segmentIndex] = { P0 = p0, P1 = p1, P2 = p2, P3 = p3 }

		for sampleIndex = 1, sampleCount do
			local t = sampleIndex / sampleCount
			local position = bezier(p0, p1, p2, p3, t)
			totalLength += vector.magnitude(position - last)
			polyline[#polyline + 1] = position
			cumulative[#cumulative + 1] = totalLength
			last = position
		end
	end

	return {
		Points = curvePoints,
		Closed = closed,
		Polyline = polyline,
		Cumulative = cumulative,
		Segments = segments,
		SamplesPerSegment = sampleCount,
		Length = totalLength,
	}
end

local function findCumulativeIndex(cumulative: { number }, distance: number): number
	local low = 2
	local high = #cumulative
	local found = high

	while low <= high do
		local middle = math.floor((low + high) / 2)
		if distance <= cumulative[middle] then
			found = middle
			high = middle - 1
		else
			low = middle + 1
		end
	end

	return found
end

local function pointAtDistance(source: SourcePath, distance: number): vector
	local length = source.Length

	if length <= 0 then
		return source.Polyline[1] or vector.create(0, 0)
	end

	if source.Closed then
		distance = distance % length
	else
		distance = math.clamp(distance, 0, length)
	end

	local cumulative = source.Cumulative
	local polyline = source.Polyline
	local found = findCumulativeIndex(cumulative, distance)
	local previousDistance = cumulative[found - 1]
	local currentDistance = cumulative[found]
	local span = currentDistance - previousDistance
	local alpha = if span > 0 then (distance - previousDistance) / span else 0
	return vector.lerp(polyline[found - 1], polyline[found], alpha)
end

local function pointAtProgress(source: SourcePath, progress: number): vector
	if source.Closed then
		return pointAtDistance(source, wrap01(progress) * source.Length)
	else
		return pointAtDistance(source, clamp01(progress) * source.Length)
	end
end

local function segmentTimeAtDistance(source: SourcePath, distance: number): (number, number)
	local length = source.Length
	local segmentCount = #source.Segments

	if segmentCount <= 0 then
		return 1, 0
	elseif distance <= 0 then
		return 1, 0
	elseif distance >= length then
		return segmentCount, 1
	end

	local cumulative = source.Cumulative
	local found = findCumulativeIndex(cumulative, distance)
	local sampleCount = source.SamplesPerSegment
	local sampleOrdinal = found - 1
	local segmentIndex = math.floor((sampleOrdinal - 1) / sampleCount) + 1
	local sampleIndex = ((sampleOrdinal - 1) % sampleCount) + 1
	local previousDistance = cumulative[found - 1]
	local currentDistance = cumulative[found]
	local span = currentDistance - previousDistance
	local alpha = if span > 0 then (distance - previousDistance) / span else 0
	local previousT = (sampleIndex - 1) / sampleCount
	local currentT = sampleIndex / sampleCount
	local t = previousT + (currentT - previousT) * alpha

	if t <= CURVE_EPSILON then
		t = 0
	elseif t >= 1 - CURVE_EPSILON then
		t = 1
	end

	return segmentIndex, t
end

local function splitCubic(segment: CubicSegment, t: number): (CubicSegment, CubicSegment)
	local p0 = segment.P0
	local p1 = segment.P1
	local p2 = segment.P2
	local p3 = segment.P3
	local p01 = vector.lerp(p0, p1, t)
	local p12 = vector.lerp(p1, p2, t)
	local p23 = vector.lerp(p2, p3, t)
	local p012 = vector.lerp(p01, p12, t)
	local p123 = vector.lerp(p12, p23, t)
	local p0123 = vector.lerp(p012, p123, t)

	return { P0 = p0, P1 = p01, P2 = p012, P3 = p0123 }, { P0 = p0123, P1 = p123, P2 = p23, P3 = p3 }
end

local function sliceCubic(segment: CubicSegment, startT: number, endT: number): CubicSegment
	startT = math.clamp(startT, 0, 1)
	endT = math.clamp(endT, 0, 1)
	
	if startT <= 0 and endT >= 1 then
		return segment
	elseif endT <= startT then
		local point = bezier(segment.P0, segment.P1, segment.P2, segment.P3, startT)
		return { P0 = point, P1 = point, P2 = point, P3 = point }
	end

	local left = segment
	if endT < 1 then
		left = splitCubic(segment, endT)
	elseif startT <= 0 then
		return left
	end
	
	local _, right = splitCubic(left, startT / endT)
	return right
end

local function appendCubic(points: { CurvePoint }, segment: CubicSegment)
	if #points == 0 then
		points[1] = { Position = segment.P0, LeftTangent = vector.create(0, 0), RightTangent = segment.P1 - segment.P0 }
	else
		points[#points].RightTangent = segment.P1 - segment.P0
	end
	
	points[#points + 1] = { Position = segment.P3, LeftTangent = segment.P2 - segment.P3, RightTangent = vector.create(0, 0) }
end

local function appendCurvePoints(target: { CurvePoint }, sourcePoints: { CurvePoint })
	if #sourcePoints == 0 then
		-- vacation clause
	elseif #target == 0 then
		for index = 1, #sourcePoints do
			local sourcePoint = sourcePoints[index]
			target[index] = { Position = sourcePoint.Position, LeftTangent = sourcePoint.LeftTangent, RightTangent = sourcePoint.RightTangent }
		end
	else
		target[#target].RightTangent = sourcePoints[1].RightTangent
		for index = 2, #sourcePoints do
			local sourcePoint = sourcePoints[index]
			target[#target + 1] = { Position = sourcePoint.Position, LeftTangent = sourcePoint.LeftTangent, RightTangent = sourcePoint.RightTangent }
		end
	end
end

local function reverseCurvePoints(sourcePoints: { CurvePoint }): { CurvePoint }
	local points: { CurvePoint } = {}
	local count = #sourcePoints

	for index = 1, count do
		local sourcePoint = sourcePoints[count - index + 1]
		points[index] = {
			Position = sourcePoint.Position,
			LeftTangent = -sourcePoint.RightTangent,
			RightTangent = -sourcePoint.LeftTangent,
		}
	end

	return points
end

local function curveRange(source: SourcePath, startDistance: number, endDistance: number): { CurvePoint }
	local points: { CurvePoint } = {}
	if source.Length <= 0 then
		local point = source.Polyline[1] or vector.create(0, 0)
		return {
			{ Position = point, LeftTangent = vector.create(0, 0), RightTangent = vector.create(0, 0) },
			{ Position = point, LeftTangent = vector.create(0, 0), RightTangent = vector.create(0, 0) },
		}
	end

	startDistance = math.clamp(startDistance, 0, source.Length)
	endDistance = math.clamp(endDistance, 0, source.Length)
	if endDistance < startDistance then
		startDistance, endDistance = endDistance, startDistance
	end

	local startSegment, startT = segmentTimeAtDistance(source, startDistance)
	local endSegment, endT = segmentTimeAtDistance(source, endDistance)
	for segmentIndex = startSegment, endSegment do
		local segment = source.Segments[segmentIndex]
		local fromT = if segmentIndex == startSegment then startT else 0
		local toT = if segmentIndex == endSegment then endT else 1
		if toT - fromT > CURVE_EPSILON then
			appendCubic(points, sliceCubic(segment, fromT, toT))
		end
	end

	if #points < 2 then
		local point = pointAtDistance(source, startDistance)
		points = {
			{ Position = point, LeftTangent = vector.create(0, 0), RightTangent = vector.create(0, 0) },
			{ Position = point, LeftTangent = vector.create(0, 0), RightTangent = vector.create(0, 0) },
		}
	end
	
	return points
end

local function visibleCurve(source: SourcePath, progress: number, offset: number): ({ CurvePoint }?, boolean)
	local amount = math.abs(progress)
	if amount <= 0 or source.Length <= 0 then
		local point = pointAtProgress(source, offset)
		return {
			{ Position = point, LeftTangent = vector.create(0, 0), RightTangent = vector.create(0, 0) },
			{ Position = point, LeftTangent = vector.create(0, 0), RightTangent = vector.create(0, 0) },
		}, false
	end

	local reverse = progress < 0
	if source.Closed and amount >= 1 and wrap01(offset) == 0 then
		return if reverse then reverseCurvePoints(source.Points) else source.Points, true
	end

	if source.Closed then
		local startDistance = wrap01(offset) * source.Length
		local signedLength = clamp01(amount) * source.Length
		if reverse then
			local endDistance = startDistance - signedLength
			if endDistance >= 0 then
				return reverseCurvePoints(curveRange(source, endDistance, startDistance)), false
			end
			local wrapped: { CurvePoint } = {}
			appendCurvePoints(wrapped, reverseCurvePoints(curveRange(source, 0, startDistance)))
			appendCurvePoints(wrapped, reverseCurvePoints(curveRange(source, source.Length + endDistance, source.Length)))
			return wrapped, false
		end

		local endDistance = startDistance + signedLength
		if endDistance <= source.Length then
			return curveRange(source, startDistance, endDistance), false
		end
		
		local wrapped: { CurvePoint } = {}
		appendCurvePoints(wrapped, curveRange(source, startDistance, source.Length))
		appendCurvePoints(wrapped, curveRange(source, 0, endDistance % source.Length))
		return wrapped, false
	end

	local startDistance = clamp01(offset) * source.Length
	local endDistance = clamp01(offset + if reverse then progress else amount) * source.Length
	if reverse then
		if endDistance <= 0 and startDistance >= source.Length then
			return reverseCurvePoints(source.Points), false
		end
		return reverseCurvePoints(curveRange(source, endDistance, startDistance)), false
	end

	if startDistance <= 0 and endDistance >= source.Length then
		return source.Points, false
	end
	return curveRange(source, startDistance, endDistance), false
end

local function visiblePolyline(source: SourcePath, progress: number, offset: number): ({ vector }, boolean)
	local amount = math.abs(progress)
	local direction = if progress < 0 then -1 else 1
	local sourceCount = math.max(#source.Polyline, 2)
	local pointCount = math.max(2, math.ceil(sourceCount * clamp01(amount)))
	local positions: { vector } = {}

	if amount <= 0 or source.Length <= 0 then
		local point = pointAtProgress(source, offset)
		return { point, point }, false
	end

	local renderClosed = source.Closed and amount >= 1 and wrap01(offset) == 0
	if renderClosed then
		for index = 1, #source.Polyline do
			positions[index] = source.Polyline[index]
		end
		return positions, true
	end

	amount = clamp01(amount)
	for index = 1, pointCount do
		local alpha = if pointCount > 1 then (index - 1) / (pointCount - 1) else 0
		positions[index] = pointAtProgress(source, offset + amount * alpha * direction)
	end

	return positions, false
end

local function downsample(positions: { vector }, maxPoints: number): { vector }
	local sourceCount = #positions
	if sourceCount <= maxPoints then
		return positions
	end

	local sampled: { vector } = {}
	for index = 1, maxPoints do
		local alpha = (index - 1) / (maxPoints - 1)
		local sourceIndex = math.floor(alpha * (sourceCount - 1)) + 1
		sampled[index] = positions[sourceIndex]
	end
	return sampled
end

local function makeLinearControlPoint(position: vector): Path2DControlPoint
	return Path2DControlPoint.new(
		UDim2.fromScale(position.x, position.y),
		UDim2.fromScale(0, 0),
		UDim2.fromScale(0, 0)
	)
end

local function makeBezierControlPoint(point: CurvePoint): Path2DControlPoint
	return Path2DControlPoint.new(
		UDim2.fromScale(point.Position.x, point.Position.y),
		UDim2.fromScale(point.LeftTangent.x, point.LeftTangent.y),
		UDim2.fromScale(point.RightTangent.x, point.RightTangent.y)
	)
end

local function basisPixels(root: GuiObject, config: PathConfig, basis: string?): number
	local actualBasis = basis or "ContainerMin"

	if actualBasis == "ViewportMin" or actualBasis == "ViewportX" or actualBasis == "ViewportY" then
		local size = config.ViewportSize or root.AbsoluteSize
		if actualBasis == "ViewportX" then
			return size.X
		elseif actualBasis == "ViewportY" then
			return size.Y
		else
			return math.min(size.X, size.Y)
		end
	end

	local size = root.AbsoluteSize
	if actualBasis == "ContainerX" then
		return size.X
	elseif actualBasis == "ContainerY" then
		return size.Y
	else
		return math.min(size.X, size.Y)
	end
end

local function resolveLength(root: GuiObject, config: PathConfig, value: ResponsiveLength?, fallback: number): number
	if value == nil then
		return fallback
	end

	local valueType = typeof(value)
	if valueType == "number" then
		return value :: number
	elseif valueType == "UDim" then
		local udim = value :: UDim
		return basisPixels(root, config, "ContainerMin") * udim.Scale + udim.Offset
	end

	local data = value :: any
	local pixels = basisPixels(root, config, data.Basis or data.basis) * (data.Scale or data.scale or 0) + (data.Offset or data.offset or 0)
	local minimum = data.Min or data.min
	local maximum = data.Max or data.max

	if minimum ~= nil then
		pixels = math.max(minimum, pixels)
	end
	if maximum ~= nil then
		pixels = math.min(maximum, pixels)
	end

	return pixels
end

local function applyPathVisual(path: Path2D, width: number, color: Color3, zIndex: number, visible: boolean)
	path.Thickness = width
	path.Color3 = color
	path.ZIndex = zIndex
	path.Visible = visible
end

local function setPathPoints(path: Path2D, positions: { vector }, closed: boolean)
	local sampled = downsample(positions, path:GetMaxControlPoints())
	local controlPoints: { Path2DControlPoint } = {}
	
	for index = 1, #sampled do
		controlPoints[index] = makeLinearControlPoint(sampled[index])
	end
	
	path.Closed = closed
	path:SetControlPoints(controlPoints)
end

local function setPathCurvePoints(path: Path2D, points: { CurvePoint }, closed: boolean)
	if #points > path:GetMaxControlPoints() then
		local positions: { vector } = {}
		for index = 1, #points do
			positions[index] = points[index].Position
		end
		setPathPoints(path, positions, closed)
		return
	end

	local controlPoints: { Path2DControlPoint } = {}
	for index = 1, #points do
		controlPoints[index] = makeBezierControlPoint(points[index])
	end
	
	path.Closed = closed
	path:SetControlPoints(controlPoints)
end

local function getOrCreateStrokePath(target: RenderTarget): Path2D
	local strokePath = target.StrokePath
	if strokePath then
		return strokePath
	end

	strokePath = Instance.new("Path2D")
	strokePath.Name = "Stroke"
	strokePath.Parent = target.Root
	target.StrokePath = strokePath
	return strokePath
end

local function destroyStrokePath(target: RenderTarget)
	local strokePath = target.StrokePath
	if strokePath then
		strokePath:Destroy()
		target.StrokePath = nil
	end
end

local function getOrCreateCap(target: RenderTarget, key: string, name: string): Frame
	local cap = target.Caps[key]
	if cap and cap:IsA("Frame") then
		return cap
	elseif cap then
		cap:Destroy()
	end

	cap = Instance.new("Frame")
	cap.Name = name
	cap.AnchorPoint = Vector2.new(0.5, 0.5)
	cap.BorderSizePixel = 0
	cap.BackgroundTransparency = 0
	cap.Parent = target.Root
	target.Caps[key] = cap

	local corner = Instance.new("UICorner")
	corner.Name = "Corner"
	corner.Parent = cap

	return cap
end

local function setCap(target: RenderTarget, name: string, radius: UDim?, position: vector, width: number, color: Color3, stroke: StrokeConfig?, strokeWidth: number)
	local cap = target.Caps[name]

	if radius == nil then
		if cap then
			cap:Destroy()
			target.Caps[name] = nil
		end
		return
	end

	cap = getOrCreateCap(target, name, name .. "Corner")
	local corner = cap:FindFirstChild("Corner")
	if corner and corner:IsA("UICorner") then
		corner.CornerRadius = radius
	end

	local zIndex = target.Config.ZIndex or 1
	local cornerZIndex = target.Config.CornerZIndex or target.Config.CapZIndex or (zIndex - 1)

	cap.Visible = true
	cap.BackgroundColor3 = color
	cap.Position = UDim2.fromScale(position.x, position.y)
	cap.Size = UDim2.fromOffset(width, width)
	cap.ZIndex = cornerZIndex

	local capStroke = cap:FindFirstChild("Stroke")
	if stroke == nil then
		if capStroke then
			capStroke:Destroy()
		end
		return
	end

	if not capStroke then
		capStroke = Instance.new("UIStroke")
		capStroke.Name = "Stroke"
		capStroke.Parent = cap
	end

	if (capStroke :: Instance):IsA("UIStroke") then
		capStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		capStroke.Color = stroke.Color
		capStroke.Thickness = strokeWidth
		capStroke.Transparency = target.Config.Transparency or 0
		capStroke.Enabled = true
	end
end

local function destroyCap(target: RenderTarget, name: string)
	local cap = target.Caps[name]
	if cap then
		cap:Destroy()
		target.Caps[name] = nil
	end
end

local function offsetByPixels(root: GuiObject, position: vector, tangent: vector, pixels: number): vector
	local size = root.AbsoluteSize
	if vector.magnitude(tangent) <= 0 or size.X <= 0 or size.Y <= 0 then
		return position
	end

	local pixelTangent = Vector2.new(tangent.x * size.X, tangent.y * size.Y)
	if pixelTangent.Magnitude <= 0 then
		return position
	end

	local direction = pixelTangent.Unit
	return position + vector.create(direction.X * pixels / size.X, direction.Y * pixels / size.Y)
end

local function getStartTangent(data: any, isCurve: boolean): vector
	if isCurve then
		local first = data[1]
		local tangent = first.RightTangent
		if vector.magnitude(tangent) > 0 then
			return tangent
		end
		return data[2].Position - first.Position
	end
	return data[2] - data[1]
end

local function getEndTangent(data: any, isCurve: boolean): vector
	local count = #data
	if isCurve then
		local last = data[count]
		local tangent = -last.LeftTangent
		if vector.magnitude(tangent) > 0 then
			return tangent
		end
		return last.Position - data[count - 1].Position
	end
	return data[count] - data[count - 1]
end

local function copyCurvePoint(point: CurvePoint): CurvePoint
	return {
		Position = point.Position,
		LeftTangent = point.LeftTangent,
		RightTangent = point.RightTangent,
	}
end

local function strokePolylineData(root: GuiObject, data: { vector }, extendStart: boolean, extendEnd: boolean, strokeWidth: number): { vector }
	local points = table.clone(data)
	if extendStart then
		points[1] = offsetByPixels(root, points[1], getStartTangent(data, false), -strokeWidth)
	end
	if extendEnd then
		points[#points] = offsetByPixels(root, points[#points], getEndTangent(data, false), strokeWidth)
	end
	return points
end

local function strokeCurveData(root: GuiObject, data: { CurvePoint }, extendStart: boolean, extendEnd: boolean, strokeWidth: number): { CurvePoint }
	local points: { CurvePoint } = {}
	for index = 1, #data do
		points[index] = copyCurvePoint(data[index])
	end

	if extendStart then
		local first = points[1]
		first.LeftTangent = vector.create(0, 0)
		table.insert(points, 1, {
			Position = offsetByPixels(root, first.Position, getStartTangent(data, true), -strokeWidth),
			LeftTangent = vector.create(0, 0),
			RightTangent = vector.create(0, 0),
		})
	end
	if extendEnd then
		local last = points[#points]
		last.RightTangent = vector.create(0, 0)
		points[#points + 1] = {
			Position = offsetByPixels(root, last.Position, getEndTangent(data, true), strokeWidth),
			LeftTangent = vector.create(0, 0),
			RightTangent = vector.create(0, 0),
		}
	end

	return points
end

local function render(target: RenderTarget, data: any, renderClosed: boolean, corners: CornerConfig, stroke: StrokeConfig?, isCurve: boolean)
	local config = target.Config
	local width = resolveLength(target.Root, config, config.Width or config.Thickness, 4)
	local color = config.Color or config.Color3 or Color3.new(1, 1, 1)
	local transparency = config.Transparency or 0
	local zIndex = config.ZIndex or 1
	local visible = config.Visible ~= false

	target.Root.ZIndex = zIndex
	applyPathVisual(target.MainPath, width, color, zIndex, visible)
	if isCurve then
		setPathCurvePoints(target.MainPath, data, renderClosed)
	else
		setPathPoints(target.MainPath, data, renderClosed)
	end

	local strokeWidth = 0
	if stroke then
		local strokePath = getOrCreateStrokePath(target)
		strokeWidth = resolveLength(target.Root, config, stroke.Width, 1)
		local outerWidth = width + strokeWidth * 2
		local extendStart = not renderClosed and visible and corners.Start == nil
		local extendEnd = not renderClosed and visible and corners.End == nil
		applyPathVisual(strokePath, outerWidth, stroke.Color, zIndex - 2, visible)
		if isCurve then
			setPathCurvePoints(strokePath, strokeCurveData(target.Root, data, extendStart, extendEnd, strokeWidth), renderClosed)
		else
			setPathPoints(strokePath, strokePolylineData(target.Root, data, extendStart, extendEnd, strokeWidth), renderClosed)
		end
	else
		destroyStrokePath(target)
	end

	local showCaps = not renderClosed and visible
	local startPosition = if isCurve then data[1].Position else data[1]
	local endPosition = if isCurve then data[#data].Position else data[#data]

	setCap(target, "Start", if showCaps then corners.Start else nil, startPosition, width, color, stroke, strokeWidth)
	setCap(target, "End", if showCaps then corners.End else nil, endPosition, width, color, stroke, strokeWidth)
	destroyCap(target, "StartFlatStrokeCap")
	destroyCap(target, "EndFlatStrokeCap")
end

local function fallbackPoints(): { PathPoint }
	return {
		pointFromAny(Vector2.new(0, 0.5)),
		pointFromAny(Vector2.new(1, 0.5)),
	}
end

local function resolvePathInput(self: Controller): ({ PathPoint }, boolean)
	local pathInput = self.Config.Path or self.Config.Points
	if typeof(pathInput) == "function" then
		pathInput = pathInput({
			Config = self.Config,
			Progress = self.Config.Progress or 1,
			Offset = self.Config.Offset or 0,
			Controller = self,
		})
	end

	if pathInput == nil then
		return fallbackPoints(), self.Config.Closed == true
	end

	local rawPoints = pathInput :: any
	local closed = self.Config.Closed

	if typeof(pathInput) == "table" and (pathInput :: any).Points ~= nil then
		rawPoints = (pathInput :: any).Points
		if closed == nil then
			closed = (pathInput :: any).Closed
		end
	end

	local points: { PathPoint } = {}
	for index = 1, #rawPoints do
		points[index] = pointFromAny(rawPoints[index])
	end

	if #points < 2 then
		points = fallbackPoints()
	end

	return points, closed == true
end

local function getSourcePath(self: Controller): SourcePath
	local pathInput = self.Config.Path or self.Config.Points
	local isDynamicPath = typeof(pathInput) == "function"
	if not isDynamicPath and not self._sourceDirty and self._source ~= nil then
		return self._source
	end
	local points, closed = resolvePathInput(self)
	local source = samplePath(points, closed, self.Config.SamplesPerSegment or self.Config.Samples)
	self._source = source
	self._sourceDirty = false
	return source
end

local function renderController(self: Controller)
	local source = getSourcePath(self)
	
	local cornersConfig = self.Config.Corners
	local corners: CornerConfig = {
		Start = if typeof(cornersConfig) == "UDim" then cornersConfig elseif cornersConfig == true then ROUND_CORNERS elseif cornersConfig then cornersConfig.Start else nil,
		End = if typeof(cornersConfig) == "UDim" then cornersConfig elseif cornersConfig == true then ROUND_CORNERS elseif cornersConfig then cornersConfig.End else nil,
	}

	local strokeConfig = self.Config.Stroke
	local stroke: StrokeConfig? = if strokeConfig then {
		Width = if typeof(strokeConfig) == "Color3" then 1 else strokeConfig.Width,
		Color = if typeof(strokeConfig) == "Color3" then strokeConfig else strokeConfig.Color
	} else nil

	local curvePoints, renderClosed = visibleCurve(source, self.Config.Progress or 1, self.Config.Offset or 0)
	if curvePoints then
		render(self, curvePoints, renderClosed, corners, stroke, true)
		return
	end
	
	local positions, polylineClosed = visiblePolyline(source, self.Config.Progress or 1, self.Config.Offset or 0)
	render(self, positions, polylineClosed, corners, stroke, false)
end

function Controller:Render(): Controller
	renderController(self)
	return self
end

local function assignAndRender(self: Controller, key: string, value: any, sourceDirty: boolean?): Controller
	(self.Config :: any)[key] = value
	if sourceDirty then
		self._sourceDirty = true
	end
	renderController(self)
	return self
end

function Controller:Update(patch: PathConfig): Controller
	for key in patch :: any do
		if SOURCE_DIRTY_KEYS[key] then
			self._sourceDirty = true
			break
		end
	end
	
	for key, value in patch :: any do
		self.Config[key] = value
	end

	renderController(self)
	return self
end

function Controller:SetPath(pathInput: PathInput): Controller return assignAndRender(self, "Path", pathInput, true) end
function Controller:SetProgress(progress: number): Controller return assignAndRender(self, "Progress", progress) end
function Controller:SetOffset(offset: number): Controller return assignAndRender(self, "Offset", offset) end
function Controller:SetWidth(width: ResponsiveLength): Controller return assignAndRender(self, "Width", width) end
function Controller:SetViewportSize(viewportSize: Vector2): Controller return assignAndRender(self, "ViewportSize", viewportSize) end
function Controller:SetColor(color: Color3): Controller return assignAndRender(self, "Color", color) end
function Controller:SetCorners(corners: (UDim | CornerConfig | true)?): Controller return assignAndRender(self, "Corners", corners) end
function Controller:SetStroke(stroke: (StrokeConfig | Color3 | false)?): Controller return assignAndRender(self, "Stroke", stroke) end
function Controller:SetVisible(visible: boolean): Controller return assignAndRender(self, "Visible", visible) end

function Controller:SetZIndex(zIndex: number): Controller
	self.Root.ZIndex = zIndex
	return assignAndRender(self, "ZIndex", zIndex)
end

function Controller:GetProgress(): number
	return self.Config.Progress or 1
end

function Controller:GetOffset(): number
	return self.Config.Offset or 0
end

function Controller:GetLength(): number
	return getSourcePath(self).Length
end

function Controller:GetPointAt(progress: number): Vector2
	return vectorToVector2(pointAtProgress(getSourcePath(self), progress))
end

function Controller:GetTangentAt(progress: number): Vector2
	local source = getSourcePath(self)
	local step = 1 / math.max(#source.Polyline * 2, 100)
	local before = pointAtProgress(source, progress - step)
	local after = pointAtProgress(source, progress + step)
	local delta = after - before
	
	return vectorToVector2(if vector.magnitude(delta) <= 0 then vector.create(1, 0) else vector.normalize(delta))
end

function Controller:GetStartPoint(): Vector2
	local positions = visiblePolyline(getSourcePath(self), self.Config.Progress or 1, self.Config.Offset or 0)
	return vectorToVector2(positions[1])
end

function Controller:GetEndPoint(): Vector2
	local positions = visiblePolyline(getSourcePath(self), self.Config.Progress or 1, self.Config.Offset or 0)
	return vectorToVector2(positions[#positions])
end

function Controller:GetConfig(): PathConfig
	return table.clone(self.Config)
end

function Controller:Destroy()
	self.Root:Destroy()
end

local function new(parent: GuiObject, config: PathConfig?): Controller
	local initialConfig = table.clone(config or {}) :: PathConfig

	local root = Instance.new("Frame")
	root.Name = initialConfig.Name or script.Name
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ClipsDescendants = false
	root.Position = initialConfig.Position or UDim2.fromScale(0, 0)
	root.Size = initialConfig.Size or UDim2.fromScale(1, 1)
	root.AnchorPoint = initialConfig.AnchorPoint or VECTOR2_ZERO
	root.ZIndex = initialConfig.ZIndex or 1
	root.Parent = parent

	local mainPath = Instance.new("Path2D")
	mainPath.Name = "Inner"
	mainPath.Parent = root

	initialConfig.Name = nil
	initialConfig.Position = nil
	initialConfig.Size = nil
	initialConfig.AnchorPoint = nil

	local controllerData = {
		Root = root,
		MainPath = mainPath,
		StrokePath = nil,
		Caps = {},
		Config = initialConfig,
		_source = nil,
		_sourceDirty = true,
	}
	local self = setmetatable(controllerData, Controller)

	renderController(self :: Controller)
	return self :: Controller
end

local function point(position: Vector2 | UDim2, leftTangent: (Vector2 | UDim2)?, rightTangent: (Vector2 | UDim2)?): PathPoint
	return {
		Position = vectorFromAny(position),
		LeftTangent = if leftTangent ~= nil then vectorFromAny(leftTangent) else VECTOR2_ZERO,
		RightTangent = if rightTangent ~= nil then vectorFromAny(rightTangent) else VECTOR2_ZERO,
	}
end

return {
	new = new,
	point = point
}