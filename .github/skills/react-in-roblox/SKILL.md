---
name: react-in-roblox
description: Use when building or editing Roblox React-Lua UI in this Rojo project (src/shared/ReactComponents, src/shared/Stories). Covers the custom primitives VStack, HStack, Grid, Panel, SmallButton, SmallText, SmallIcon, CloseButton, and the flex/alignment/AutomaticSize rules for laying them out.
---

# React-Lua UI in Roblox

This is a Rojo + React-Lua project (`Packages.React` 17, `Packages.ReactRoblox`). UI components live in `src/shared/ReactComponents`, layout primitives in `src/shared/ReactComponents/ui`, and UI Labs stories in `src/shared/Stories`.

## Rules

1. **Primitives first.** Read `references/primitives.md` before writing UI. Reuse `VStack`, `HStack`, `Grid`, `Panel`, `SmallButton`, `SmallText`, `SmallIcon`, `CloseButton`.
2. **Flex/list layout, not fixed positions.** Put children inside `VStack`/`HStack`/`Grid` and order them with `LayoutOrder`. Use raw `Frame`/`TextLabel`/`TextButton` only for behavior the primitives do not cover (`ScrollingFrame`, `ViewportFrame`, `TextBox`, custom animation, sprites).
3. **AutomaticSize is opt-in per axis.** Pick one sizing owner per axis: either the parent list flexes the child (`Fill`), or the child auto-sizes (`AutomaticSize`). Never both on the same axis.
4. **One axis at a time.** Full-width sections use `Size = UDim2.fromScale(1, 0)` + `AutomaticSize = Enum.AutomaticSize.Y`. Hug-content chips/toolbars use `Size = UDim2.fromScale(0, 0)` + `AutomaticSize = Enum.AutomaticSize.XY`.
5. **Composition over monoliths.** Build sections from small primitive-based components.
6. **Absolute `Position` is the exception,** limited to overlay roots (`Panel` already does this), world-space billboards/particles, or an explicit user request. Inside a list it fights the layout.

## Sizing & flex cheat sheet

Exact props are in `references/primitives.md`.

- `VStack` is vertical. Defaults: `HorizontalAlignment = Center`, `VerticalAlignment = Top`, `HorizontalFlex = "Fill"`, `VerticalFlex = "Fill"`. Children stretch both ways unless you override the flex.
- `HStack` is horizontal. Defaults: `HorizontalAlignment = Left`, `VerticalAlignment = Center`, `HorizontalFlex = "None"`, `VerticalFlex = "None"`. Children keep their own size unless you ask for flex.
- Flex accepts `Enum.UIFlexAlignment` or its string name (`"Fill"`, `"SpaceBetween"`, `"SpaceAround"`, `"SpaceEvenly"`, `"None"`).
- `HorizontalAlignment`/`VerticalAlignment` have **no** spacing values. `SpaceBetween` and friends are flex only.
- `HorizontalFlex = "Fill"` stretches/distributes children on that axis. Use `"None"` for auto-width content, `"SpaceBetween"` for title/close rows.
- In a full-height `VStack`, set `VerticalFlex = "None"` when every row should hug its content; use `VerticalFlex = "Fill"` only when one child (e.g. a scroll body) should absorb the remaining height.
- `SmallText` defaults to `AutomaticSize.XY`. For wrapped text, give it a width and `AutomaticSize = Enum.AutomaticSize.Y` (or `None`); `TextWrapped` without a width grows the label instead of wrapping.
- `Grid.CellSize` is **required** in this codebase. Use `UDim2.fromOffset(w, h)` and `FillDirectionMaxCells` for the column count. Grid ignores `HorizontalFlex`/`VerticalFlex`/`Wraps`/`Spacing`; those are list-layout props.
- Always set `LayoutOrder` on direct children of a list/grid; otherwise order falls back to instance name.

Reference implementations:

- `ui/Panel.luau`: header + body composition, flex and spacer row.
- `ReportViewerPanel.luau`: `SpaceBetween` header, scrollable list.
- `DefaultScrollFrame.luau`: `ScrollingFrame` + auto-size `VStack`.
- `RecipePanel.luau`: nested rows/columns with per-axis auto-sizing.
- `DailyPanel.luau`, `BuildPanel.luau`: Grid columns and wrapping rows.

## Story workflow

Stories live in `src/shared/Stories/*.story.luau` and are run with UI Labs. Each story returns a function:

```lua
local function story(frame: Frame)
	local root = ReactRoblox.createRoot(frame)
	root:render(e(Component))
	ViewportController.initialize() -- only for app/viewport stories

	return function()
		root:unmount()
		GlobalState:resetState()
		UIState:resetState()
	end
end

return story
```

Mock state with `GlobalState.startPlayerSession(playerId, { ... })` / `UIState.toggle("...")`, and always reset it in cleanup. When adding a component, add or update a story under `src/shared/Stories` so the layout can be verified standalone. `ShopPanel.story.luau` and `GeneralHud.story.luau` are good templates.

## Action plan

1. Read `references/primitives.md` and map each requested section to a primitive.
2. Decide per-axis sizing (fill vs hug) before writing the element table.
3. Compose `VStack`/`HStack`/`Grid`; set `LayoutOrder`, `Padding`, and `Spacing`.
4. Use `Panel` for modal/overlay surfaces, `SmallText`/`SmallIcon`/`SmallButton` for content.
5. Add or update a story, then check the layout at more than one viewport size if responsive.
