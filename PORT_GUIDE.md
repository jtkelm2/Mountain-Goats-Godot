# Mountain Goats — Godot 4.x Port

Port of the HaxeFlixel Mountain Goats implementation to Godot 4.x (GDScript).

## Setup

1. Unzip this project
2. Copy your original `assets/` folder into `mountain_goats/assets/`
   - Required: `bg.png`, `die.png`, `goat.png`, `square.png`, `token.png`,
     `bonustoken.png`, `dicebox.png`, `diceroller.png`, `panel.png`,
     `rank.png`, `moveconfirm.png`
3. Open the project in Godot 4.3+
4. Run the scene

## Architecture Mapping

| HaxeFlixel | Godot | Notes |
|---|---|---|
| `System` (static class) | `GameSystem` (autoload) | Global singleton |
| `Reg` (static class) | `Reg` (autoload) | Constants, initialized at runtime |
| `EventID` (enum) | `GameEvent` (class with static factories) | Haxe ADTs → class with type enum |
| `Gamestate` (interface) | Duck-typed `RefCounted` scripts | `handle()` + `refresh()` + `gamestate_tag` |
| `Gamepiece` (interface) | `GamePiece` (extends `Sprite2D`) | Base class instead of interface |
| `Locale` (abstract class) | `Locale` (extends `RefCounted`) | Not a Node — just positioning logic |
| `GridLocale` | `GridLocale` (extends `Locale`) | Same |
| `FlxTween` | `Tween` (via `create_tween()`) | Nearly 1:1 API |
| `FlxMouseEventManager` | `Area2D` children + signals | Godot-idiomatic input |
| `FlxTimer` | `get_tree().create_timer()` | Same pattern |
| `AIRaw` (typedef) | `Callable` | `(gs_dict, moves_arr) -> move_dict` |
| `Events` queue | `Events` (RefCounted) | AutoNext/ManualNext preserved |

## Key Architectural Decisions

**Event Queue** — The `AutoNext`/`ManualNext` queue from the original is preserved
exactly. Events that depend on animation completion use `ManualNext` and call
`GameSystem.events.next()` from tween callbacks.

**Mouse Input** — Instead of HaxeFlixel's `FlxMouseEventManager`, each clickable
sprite gets an `Area2D` child with a `CollisionShape2D`. Signals route through
`MouseManager` into the event queue.

**Locales** — These remain `RefCounted` objects (not Nodes) since they're purely
positional logic. They directly set `position` on the `GamePiece` sprites they
manage.

**AI** — The `AIRaw` → `AIManager` split is preserved. `AIRaw` functions are
`Callable`s that operate on pure `Dictionary` game state. `AIManager` handles
translation between the visual game state and the data representation.

**Gamestates** — These are `RefCounted` scripts with `handle(event)` and
`refresh()` methods. They're duck-typed rather than using a formal interface,
which is idiomatic GDScript.

## What to Watch For

- **Sprite sheets**: The code uses `hframes`/`vframes` on `Sprite2D` to handle
  sprite sheets. Make sure your asset dimensions match the frame sizes in `Reg`.
- **Z-ordering**: Godot draws children in tree order. You may need to adjust
  `z_index` on some nodes for proper layering (the original noted this as a
  missing feature).
- **Input propagation**: `Area2D` input events propagate based on z-order. If
  overlapping clickables cause issues, adjust `z_index` or `input_priority`.

## Modifying the AI

To change which player is human, edit `game_system.gd` → `_init_ai()`.
Change any player's entry from `AI` to `HUMAN`:

```gdscript
players = {
    0: {"type": PlayerType.HUMAN},
    1: {"type": PlayerType.HUMAN},  # Now player 2 is also human
    2: {"type": PlayerType.AI, "ai": AIManagerScript.new(play_state, ai_func)},
    3: {"type": PlayerType.AI, "ai": AIManagerScript.new(play_state, ai_func)},
}
```

Different AI strategies are available in `ai_lab.gd`:
- `handcraft_score_ai()` — strongest (default)
- `tokenized_weighted_mover_ai()` — moderate
- `score_naive_ai()` — simple score maximizer
- `random_ai()` — random moves
