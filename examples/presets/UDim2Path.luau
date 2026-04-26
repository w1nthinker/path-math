--!strict

local Shared = require(script.Parent.Shared)
type ExampleContext = Shared.ExampleContext

return function(context: ExampleContext): ()
	Shared.makeShowcase(context, "UDim2 Path", 36, "UDim2Path")
end