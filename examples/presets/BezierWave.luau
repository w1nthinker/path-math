--!strict

local Shared = require(script.Parent.Shared)
type ExampleContext = Shared.ExampleContext

return function(context: ExampleContext): ()
	Shared.makeShowcase(context, "Bezier Wave", 22, "BezierWave")
end