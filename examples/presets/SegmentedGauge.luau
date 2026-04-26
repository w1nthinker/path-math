--!strict

local Shared = require(script.Parent.Shared)
type ExampleContext = Shared.ExampleContext

return function(context: ExampleContext): ()
	Shared.makeShowcase(context, "Segmented Gauge", 16, "SegmentedGauge")
end