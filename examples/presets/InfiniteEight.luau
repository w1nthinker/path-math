--!strict

local Shared = require(script.Parent.Shared)
type ExampleContext = Shared.ExampleContext

return function(context: ExampleContext): ()
	Shared.makeShowcase(context, "Infinite Eight", 7, "InfiniteEight")
end