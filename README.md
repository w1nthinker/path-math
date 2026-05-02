# PathMath
do more with Path2D's

## Installation

[install with wally](https://wally.run/package/w1nthinker/path-math)

[get from creator store](https://create.roblox.com/store/asset/79483342482432/PathMath)

[edit showcase game](https://www.roblox.com/games/85879577952024/PathMath-Showcase)

## Examples
get both example [guis](/examples/prefabs)

[play showcase game](https://www.roblox.com/games/85879577952024/PathMath-Showcase)

[virtualized](/examples/virtualized) grid with different random presets using [virtualized-ui](https://github.com/w1nthinker/virtualized-ui)

https://github.com/user-attachments/assets/a4f2ee69-2dac-4f6e-8987-d5539fbd33aa

different examples from [presets](/examples/presets)

https://github.com/user-attachments/assets/9b9ed90d-3146-47c7-9ed5-98432c574e28

both in parallel

https://github.com/user-attachments/assets/5e4f6ad1-1d51-4b3e-ab86-7fac63e8c52a

- `src/init.luau`  
  The library module. This is the file you use in your Roblox project.

- `examples/ExamplesClient.local.luau`  
  Demo runner for the standard showcase UI.

- `examples/presets/`  
  Individual showcase entries for circles, gauges, spinners, arcs, stars, hearts, spirals, polygons, responsive widths, strokes, dynamic endpoints, and more. Each preset keeps its own example logic and uses `Utility.luau` only for small shared helpers.

- `examples/presets-full/`  
  Standalone versions of the same presets. Each file fully implements that example without shared preset helper modules.

- `examples/virtualized/`  
  A stress/demo grid that renders many randomized animated spinners using `virtualized-ui`.

- `examples/prefabs/`  
  Roblox model files for trying the demos in Studio.

## Getting Started

PathMath is distributed as a Wally package and as a plain Luau module.

To use it in a Roblox project:

1. Install the package with Wally or copy `src/init.luau` into your game.
2. Place it somewhere your UI code can require it, such as `ReplicatedStorage`.
3. Create a parent GUI object for the path.
4. Create a PathMath controller with a path configuration.
5. Update the controller over time when you want animation.

The examples assume the module is available from `ReplicatedStorage` as `PathMath`.

## Performance Notes

PathMath is designed around updating existing instances.

For best results:

- Reuse controllers instead of recreating them during animation.
- Use `Update` for grouped changes.
- Use dynamic path functions only when the path shape itself needs to change.
- Prefer changing `Progress` and `Offset` for common animations.
- Keep sample counts reasonable unless a curve needs more precision.
- Pass current viewport size when using viewport-based responsive widths.

For very large lists of animated paths, use virtualization so only visible UI items are actively rendered.

## Requirements

PathMath targets Roblox Luau and Roblox UI code that can use `Path2D`.

The module can be installed through Wally or copied directly into a Roblox project.

The virtualized demo also expects [`virtualized-ui`](https://github.com/w1nthinker/virtualized-ui) to be available.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
