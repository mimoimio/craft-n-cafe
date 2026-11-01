# UI Primitives Reference

Source folder: `src/shared/ReactComponents/ui`

Use these primitives first when building client UI. They are thin wrappers over Roblox `UIListLayout` / `UIGridLayout`; they do not compute layout themselves, so Roblox flex and `AutomaticSize` rules still apply.

## Import pattern

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local e = React.createElement

local Primitives = ReplicatedStorage.Shared.ReactComponents.ui
local VStack = require(Primitives.VStack)
local HStack = require(Primitives.HStack)
local Grid = require(Primitives.Grid)
local Panel = require(Primitives.Panel)
local SmallButton = require(Primitives.SmallButton)
local SmallText = require(Primitives.SmallText)
local SmallIcon = require(Primitives.SmallIcon)
local CloseButton = require(Primitives.CloseButton)
local RainbowWaveGradient = require(Primitives.RainbowGradient)
local rounded = require(Primitives.rounded)
```

`require(Primitives.VStack)` and the full path form (`require(game.ReplicatedStorage.Shared.ReactComponents.ui.VStack)`) are both used in the repo. Match the surrounding file.

React-Roblox accepts string names for enum props (`HorizontalFlex = "Fill"`, `HorizontalAlignment = "Left"`), but `Enum.*` is easier to search.

## Layout model (read this before choosing props)

### Axis mapping

For a vertical list (`VStack`, `FillDirection = Vertical`):

| Property | Controls |
| --- | --- |
| `HorizontalAlignment` | horizontal position of the whole child group |
| `VerticalAlignment` | vertical position of the whole child group |
| `HorizontalFlex` | child **width** distribution (`Fill`, `SpaceBetween`, ...) |
| `VerticalFlex` | child **height** distribution |

For a horizontal list (`HStack`), swap the axes: `HorizontalFlex` distributes width (main axis), `VerticalFlex` distributes height (cross axis).

`HorizontalAlignment` / `VerticalAlignment` only position the group. They have no `SpaceBetween`, `SpaceAround`, or `SpaceEvenly` values. Those are flex values.

### Defaults are not the same

| Primitive | HorizontalAlignment | VerticalAlignment | HorizontalFlex | VerticalFlex |
| --- | --- | --- | --- | --- |
| `VStack` | `Center` | `Top` | `"Fill"` | `"Fill"` |
| `HStack` | `Left` | `Center` | none (`None`) | `None` |
| `Grid` | `Center` | `Top` | n/a | n/a |

Consequences:

- Inside a `VStack`, children stretch to the full width by default, and children on a definite-height stack stretch vertically too.
- Inside an `HStack`, children keep their own sizes by default.
- For left-aligned, auto-width content in a `VStack`, pass `HorizontalAlignment = Enum.HorizontalAlignment.Left` and `HorizontalFlex = "None"`.
- For rows that should hug their content inside a full-height `VStack`, pass `VerticalFlex = "None"`.

### AutomaticSize rules

`AutomaticSize` is per axis: `None`, `X`, `Y`, or `XY`. Primitives default to `None` (except `SmallText`, `SmallButton`, `SmallIcon`, `CloseButton`, which default to `XY`).

- Full-width section: `Size = UDim2.fromScale(1, 0)` + `AutomaticSize = Enum.AutomaticSize.Y`.
- Full-height column: `Size = UDim2.fromScale(0, 1)` + `AutomaticSize = Enum.AutomaticSize.X`.
- Hug content both ways: `Size = UDim2.fromScale(0, 0)` + `AutomaticSize = Enum.AutomaticSize.XY`.
- Parent flex and child `AutomaticSize` must not own the same axis. If the parent uses `Fill` on an axis, the child's size on that axis is decided by flex; `AutomaticSize` there is ignored or causes jitter.
- `AutomaticSize` needs a definite size on the other axis to be predictable. A full-screen container cannot also hug content.
- Wrapped text needs a width. `SmallText` defaults to `XY`, so `TextWrapped = true` alone grows the label instead of wrapping. Set `Size` (or a parent-imposed width) and `AutomaticSize = Enum.AutomaticSize.Y`.

### Layout order

Always set `LayoutOrder` on direct children of `VStack` / `HStack` / `Grid`. Layouts sort by `LayoutOrder` and fall back to instance name, which makes visual order depend on React child keys.

## `VStack` (`VStack.lua`)

Vertical `UIListLayout`. Root is a `Frame`, unless `BackgroundImage` is set, in which case it is an `ImageLabel`.

Root props:

- `children`, `Size` (default `UDim2.fromScale(1, 1)`), `AutomaticSize` (default `None`)
- `BackgroundTransparency` (default `1`), `BackgroundColor3`
- `LayoutOrder`, `AnchorPoint`, `Position`, `Rotation`, `ClipsDescendants`, `Visible`, `Active`, `ZIndex`
- `OnMount` (`ref`)
- `BackgroundImage`, `BackgroundImageColor3`, `BackgroundImageTransparency`, `ScaleType`, `SliceCenter`, `TileSize`

Layout props:

- `HorizontalAlignment` (default `Center`), `VerticalAlignment` (default `Top`)
- `HorizontalFlex` (default `"Fill"`), `VerticalFlex` (default `"Fill"`), `Wraps`
- `Spacing` (`UDim`, becomes `UIListLayout.Padding`)
- `Padding` table: `{ All, Top, Bottom, Left, Right }` (`UDim`)
- `FlexMode` (`UIFlexMode` or string; adds a `UIFlexItem` to this stack)

Notes:

- `HorizontalFlex` defaults to `Fill`, so children are full-width unless overridden.
- `VerticalFlex` defaults to `Fill`, which stretches rows on a definite-height stack. Use `"None"` for stacked forms and text.
- `Wraps = true` makes the list wrap onto new lines; useful for tag rows.

## `HStack` (`HStack.lua`)

Horizontal `UIListLayout`. Root is **always** an `ImageLabel`, even when no image is supplied.

Root props:

- `children`, `Size` (default `UDim2.fromScale(1, 1)`), `AutomaticSize` (default `None`)
- `BackgroundTransparency` (default `1`), `BackgroundColor3`
- `LayoutOrder`, `AnchorPoint`, `Position`, `Rotation`, `ClipsDescendants`, `Visible`, `Active`, `ZIndex`
- `OnMount` (`ref`)
- `BackgroundImage` (fed to `Image`), `BackgroundImageColor3`, `BackgroundImageTransparency`
- `ScaleType` (default `Enum.ScaleType.Tile`), `SliceCenter`, `TileSize` (default 200x200)

Layout props:

- `HorizontalAlignment` (default `Left`), `VerticalAlignment` (default `Center`)
- `HorizontalFlex` (default none), `VerticalFlex` (default `None`), `Wraps`
- `Spacing` (`UDim`, becomes `UIListLayout.Padding`)
- `Padding` table: `{ All, Top, Bottom, Left, Right }` (`UDim`)

Notes:

- There is no `FlexMode` prop on `HStack`.
- Because the root is an `ImageLabel`, `BackgroundColor3` still works, but image props are the intended background.
- Common header patterns:
  - `HorizontalFlex = "SpaceBetween"` for title left / close right.
  - `HorizontalFlex = "Fill"` plus a transparent spacer with `Size = UDim2.fromScale(1, 0)` (the `Panel` header pattern).

## `Grid` (`Grid.lua`)

`UIGridLayout` wrapper. Root is a `Frame`.

Required/primary props:

- `children`
- `CellSize` — **required**. The implementation passes it straight through with no default; omit it and the layout becomes inconsistent.
- `CellPadding` (default `UDim2.new(0, 6, 0, 6)`)

Layout props:

- `FillDirection` (default `Horizontal`), `FillDirectionMaxCells` (default `0` = automatic)
- `HorizontalAlignment` (default `Center`), `VerticalAlignment` (default `Top`)
- `SortOrder` (default `LayoutOrder`), `StartCorner` (default `TopLeft`)
- `Padding` table: `{ All, Top, Bottom, Left, Right }` (`UDim`)
- `MinSize` (`Vector2`, default `(30, 30)`; applied through a `UISizeConstraint`)

Root props:

- `Size` (default `UDim2.fromScale(1, 1)`), `AutomaticSize` (default `None`)
- `BackgroundTransparency` (default `1`), `BackgroundColor3`, `LayoutOrder`
- `[React.Change.AbsolutePosition]`, `[React.Change.AbsoluteSize]` handlers
- `Active` is forced to `false`

Notes:

- `FillDirectionMaxCells` is the column count when `FillDirection = Horizontal`, and the row count when `Vertical`.
- Grid **ignores** `HorizontalFlex`, `VerticalFlex`, `Wraps`, and `Spacing`; those are list-layout props and are not forwarded. Use `CellPadding` and `FillDirectionMaxCells`.
- Grid does not forward `Position`, `AnchorPoint`, `Visible`, `ZIndex`, `ClipsDescendants`, or `Rotation`. Wrap it in a `Frame` for those.
- Grid cells are fixed by `CellSize`; it does not auto-fit columns to width. For responsive columns, compute `CellSize` from `useBreakpoint` or use a wrapping `HStack`.
- A grid that must show all rows should either auto-size (`Size = UDim2.fromScale(1, 0)` + `AutomaticSize = Y`) inside a `ScrollingFrame`, or be clipped/scrolled by its parent.

## `Panel` (`Panel.luau`)

Animated overlay panel: layered `ImageLabel` background + content `VStack` + built-in header (`Title` + optional close button). Uses ReactFlow `useSpring` for open/hidden positions.

Primary props:

- `Open: boolean?` (default `true`)
- `OnClose: (() -> ())?` — renders the close button and binds `Activated`
- `children` — rendered inside the body `VStack`

Content props:

- `Title`, `TitleSize` (default `18`)
- `Size` (default `UDim2.fromScale(0.45, 0.6)`), `AutomaticSize`, `ContentAutomaticSize`
- `LayoutOrder`, `AnchorPoint` (default `Vector2.new(0.5, 0.5)`)
- `Padding`, `Spacing` (default `UDim.new(0, 8)`)
- `VerticalAlignment`, `HorizontalAlignment` — applied to the body stack, positioning its children

Animation props:

- `OpenPosition` (default `UDim2.fromScale(0.5, 0.5)`), `HiddenPosition` (default `UDim2.fromScale(0.5, 1.2)`)
- `SpringSpeed` (default `18`), `SpringDamper` (default `0.85`)

Background/layering props:

- `BackgroundMode` (`"Slice"` or `"Tile"`, default `"Slice"`)
- `BackgroundImage`, `BackgroundImageColor3`, `BackgroundImageTransparency`
- `SliceCenter`, `TileSize`
- `BackgroundZIndex` (default `1`), `ContentZIndex` (default `2`)
- `BackgroundColor3`, `ClipsDescendants`, `ZIndex`

Close button style props:

- `CloseButtonBackgroundTransparency`, `CloseButtonBackgroundColor3`, `CloseButtonTextColor3`

Notes:

- Root `Visible` is always `true`; `Open` only drives the spring position.
- The root is positioned absolutely on purpose. This is the approved place for fixed positioning.
- The body `VStack` uses `HorizontalFlex = Fill`, `VerticalFlex = Fill`, and `Size = UDim2.fromScale(1, 1)`. It is built for fixed-size overlays.
- For an auto-height panel, set `Size = UDim2.fromScale(width, 0)`, `AutomaticSize = Enum.AutomaticSize.Y`, and `ContentAutomaticSize = Enum.AutomaticSize.Y`, then verify in a story; otherwise keep it fixed-size.
- `Padding` defaults to `Top/Bottom 10`, `Left/Right 12` when omitted.

## `SmallButton` (`SmallButton.lua`)

Interactive `TextButton` or `ImageButton` with hover scale and click sound.

Shared props:

- `ButtonClass` (`"TextButton"` / `"ImageButton"`; defaults to `ImageButton` when `Image` is set)
- `children`, `OnMount` (`ref`)
- `Size` (default `UDim2.new(0, 48, 0, 48)`), `AutomaticSize` (default `XY`)
- `Position`, `AnchorPoint`, `Rotation`, `Visible`, `Active`, `Selectable`, `LayoutOrder`, `ZIndex` (default `11`)
- `BackgroundColor3`, `BackgroundTransparency` (default `0.3`), `AutoButtonColor`
- `Rounded` (default `true`; `false` removes the `UICorner`), `CornerRadius` (default `UDim.new(0, 8)`)
- `Scale` (number; adds a `UIScale`), `HoverScale` (`true` enables the hover spring)
- `Padding` table (`{ All, Top, Bottom, Left, Right }`, default `4`)
- `[React.Event.Activated]`, `[React.Event.MouseButton1Down]`, `[React.Event.MouseButton1Up]`
- `[React.Change.AbsolutePosition]`, `[React.Change.AbsoluteSize]`

Text mode:

- `Text` (default `""`), `TextSize` (default `16`), `TextColor3` (default white), `Font` (default `FredokaOne`)
- `TextScaled`, `TextWrapped` (default `true`), `TextXAlignment`, `TextTruncate`, `TextTransparency`, `RichText`
- `TextStrokeTransparency` (default `1`), `TextThickness` (adds an inner `UIStroke`)
- `MaxTextSize`, `MinTextSize`

Image mode:

- `Image`, `ImageRectOffset`, `ImageRectSize`, `ImageTransparency` (default `0`)
- `ImageColor3` (defaults to `TextColor3`), `ScaleType` (default `Fit`), `SliceCenter`

Overlay / keybind:

- `OverlayText`, `OverlayTextSize` (default `20`), `OverlayTextTransparency`
- `OverlayTextStrokeTransparency`, `OverlayTextWrapped`
- `KeybindColor3`, `KeybindFont`

Notes:

- Default `AutomaticSize = XY` means the button hugs its content even though `Size` defaults to 48x48. Set `AutomaticSize = None` when you want the size to win (icon tiles, fixed tabs).
- The component mutates the `children` table it receives. Pass a fresh table per render; do not reuse a cached one.
- `Rounded = false` is the way to get a square icon button (see `RecipePanel` ingredient tiles).

## `SmallText` (`SmallText.luau`)

`TextLabel` for UI text, with an always-added `UIStroke` and `UITextSizeConstraint`.

Accepted props:

- `children`, `Text`
- `TextSize` (feeds the `UITextSizeConstraint` min/max, default `18`)
- `MinTextSize`, `MaxTextSize`
- `TextScaled`, `AutomaticSize` (default `XY`), `Size`
- `TextXAlignment` (default `Left`), `TextYAlignment` (default `Bottom`)
- `TextColor3` (default white), `TextTransparency`, `TextStrokeTransparency` (default `0`)
- `TextStrokeColor3`, `Thickness` (default `2`)
- `TextWrapped`, `TextTruncate`, `RichText`
- `BackgroundTransparency` (default `1`), `BackgroundColor3`
- `Font` (default `"FredokaOne"`), `Rotation`, `LayoutOrder`, `ZIndex`
- `OnMount` (`ref`), `Active`, `Visible`

Notes:

- `TextSize` sets the size constraint, not `TextLabel.TextSize`; the label is effectively constrained to `MinTextSize`/`MaxTextSize`.
- `AutomaticSize = XY` is the default. Override it for wrapped or fixed-width text.
- The component overwrites the `UITextSizeConstraint` and `_UIStroke` child keys.

## `CloseButton` (`CloseButton.lua`)

Standardized red `TextButton` that always displays `"X"`.

Accepted props:

- `LayoutOrder`, `Size` (default `UDim2.new(0, 48, 0, 48)`), `Position`, `Visible`, `AnchorPoint`
- `TextSize` (default `18`; constrained to exactly 18 regardless)
- `TextColor3` (default white), `ZIndex`, `AutoButtonColor`
- `[React.Event.Activated]`
- `BackgroundTransparency` (default `0.3`)
- `BackgroundColor3` (default `Color3.fromRGB(255, 60, 55)`)
- `CornerRadius` (default `UDim.new(1, 0)`; fully rounded)

Notes:

- `AutomaticSize` is always `XY`.
- Use this for dismiss actions; use `SmallButton` when you need a label.

## `SmallIcon` (`SmallIcon.luau`)

Compact `ImageLabel` for icons.

Accepted props:

- `children`, `Image`
- `Size` (default `UDim2.new(0, 32, 0, 32)`)
- `AutomaticSize` (default `XY`)
- `AnchorPoint` (default `Vector2.new(0.5, 0.5)`)
- `Position` (default `UDim2.new(0.5, 0, 0.5, 0)`)
- `LayoutOrder`

Notes:

- Always `BackgroundTransparency = 1`.
- It does **not** forward `ImageColor3`, `ScaleType`, `Visible`, or `ZIndex`; use a raw `ImageLabel` if you need those.

## `rounded` (`rounded.lua`)

Returns a `UICorner` with `CornerRadius = UDim.new(0, 8)`.

```lua
UICorner = e(rounded)
```

It is currently unused in the repo; most primitives create their own `UICorner`. Prefer `e("UICorner", { CornerRadius = ... })` when you need a different radius.

## `RainbowWaveGradient` (`RainbowGradient.luau`)

Animated `UIGradient` that returns a gradient instance only.

- `rotation` (default `0`) is forwarded.
- The `speed` prop is accepted but currently ignored; the effect uses the module-level constant `speed = 10` seconds.
- Updates via `RunService.Heartbeat`; no visual element of its own.

## Patterns

### Full-width auto-height section

```lua
e(VStack, {
	Size = UDim2.fromScale(1, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	HorizontalFlex = "None", -- children keep their width
	VerticalFlex = "None", -- children keep their height
	Spacing = UDim.new(0, 8),
	Padding = { All = UDim.new(0, 12) },
}, children)
```

### Header: title left, close right

```lua
e(HStack, {
	Size = UDim2.new(1, 0, 0, 32),
	HorizontalFlex = "SpaceBetween",
	VerticalAlignment = Enum.VerticalAlignment.Center,
}, {
	Title = e(SmallText, { Text = "Settings", TextSize = 20, LayoutOrder = 1 }),
	Close = e(CloseButton, {
		Size = UDim2.new(0, 32, 0, 32),
		LayoutOrder = 2,
		[React.Event.Activated] = props.OnClose,
	}),
})
```

`SpaceBetween` spaces items without stretching them. Do not use `HorizontalAlignment = "SpaceBetween"`; alignment does not accept it.

### Header: spacer variant (used by `Panel`)

```lua
e(HStack, {
	Size = UDim2.new(1, 0, 0, 32),
	HorizontalFlex = "Fill",
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Spacing = UDim.new(0, 8),
}, {
	Title = e(SmallText, { Text = "Settings", LayoutOrder = 1 }),
	Spacer = e("Frame", {
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
	}),
	Close = e(CloseButton, { LayoutOrder = 3, [React.Event.Activated] = props.OnClose }),
})
```

### Equal-width tab row

```lua
e(HStack, {
	Size = UDim2.fromScale(1, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	HorizontalFlex = "Fill",
	Spacing = UDim.new(0, 8),
}, {
	e(SmallButton, { Text = "Primary", Size = UDim2.new(0, 0, 0, 40), LayoutOrder = 1 }),
	e(SmallButton, { Text = "Secondary", Size = UDim2.new(0, 0, 0, 40), LayoutOrder = 2 }),
})
```

Parent flex owns the width; do not also set scale widths (`0.5`) on the children. If you need exact fractions, drop `HorizontalFlex` and use scale widths instead.

### Hug-content floating toolbar

```lua
e(VStack, {
	Size = UDim2.fromScale(0, 0),
	AutomaticSize = Enum.AutomaticSize.XY,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	Spacing = UDim.new(0, 16),
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -24), -- overlay root only
}, children)
```

### Grid of fixed cells

```lua
e(Grid, {
	Size = UDim2.fromScale(1, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	CellSize = UDim2.fromOffset(100, 130),
	CellPadding = UDim2.fromOffset(8, 8),
	FillDirectionMaxCells = 3,
	MinSize = Vector2.new(40, 40),
	Padding = { All = UDim.new(0, 8) },
}, cells)
```

`CellSize` is mandatory. For responsive columns, compute it from `useBreakpoint` or use a wrapping `HStack` instead.

### Scrollable list

```lua
e("ScrollingFrame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollingDirection = Enum.ScrollingDirection.Y,
}, {
	e(VStack, {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		VerticalFlex = "None",
		Spacing = UDim.new(0, 6),
	}, children),
})
```

### Overlay panel

```lua
e(Panel, {
	Title = "Settings",
	Size = UDim2.fromScale(0.45, 0.6),
	Spacing = UDim.new(0, 8),
	Padding = { All = UDim.new(0, 12) },
	OnClose = close,
}, children)
```

## Common pitfalls

- `HorizontalAlignment = "SpaceBetween"` — invalid; use `HorizontalFlex = "SpaceBetween"`.
- `Position` on children of `VStack` / `HStack` / `Grid` — ignored by the layout or causes overlap. Use `LayoutOrder`.
- Parent `HorizontalFlex`/`VerticalFlex = "Fill"` plus child `AutomaticSize` on the same axis — choose one owner.
- `TextWrapped = true` without a width on `SmallText` — it grows instead of wrapping.
- Omitting `Grid.CellSize` — the implementation has no default.
- Passing flex props to `Grid` — they are not forwarded.
- Reusing a `children` table across renders for `SmallButton` / `SmallText` — the components mutate it.
- Expecting `HStack` to be a `Frame` — it is always an `ImageLabel`.
- Expecting `VStack`/`HStack` defaults to match each other — they differ (`Fill`/`Fill` vs `None`/`None`).
