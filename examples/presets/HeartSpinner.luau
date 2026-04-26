--!strict

local Shared = require(script.Parent.Shared)
type ExampleContext = Shared.ExampleContext

return function(context: ExampleContext): ()
	Shared.makeShowcase(context, "Heart Spinner", 13, "HeartSpinner")
end