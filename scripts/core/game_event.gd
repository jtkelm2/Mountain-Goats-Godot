class_name GameEvent
extends RefCounted
## Represents a discrete game event, replacing the Haxe EventID enum.

enum Type {
	MOUSE_DOWN, MOUSE_UP, MOUSE_OVER, MOUSE_OUT, MOUSE_WHEEL,
	DRAGGER_DROPPED, MOUSE_CLICKED, MOVEMENTS_CONFIRMED,
	SWITCH_STATE,
	AI_CAST_WILD, AI_PLACE_DIE, AI_ADVANCE_GOAT,
}

var type: Type
var object = null        # The game object involved (Sprite2D)
var gamestate_ref = null # For SWITCH_STATE
var die_ref = null       # For AI die events
var int_value: int = 0   # Generic int (wheel delta, slot, mountain, wild value)

# ---- Static factory methods ----

static func mouse_down(obj) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.MOUSE_DOWN
	e.object = obj
	return e

static func mouse_up(obj) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.MOUSE_UP
	e.object = obj
	return e

static func mouse_over(obj) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.MOUSE_OVER
	e.object = obj
	return e

static func mouse_out(obj) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.MOUSE_OUT
	e.object = obj
	return e

static func mouse_wheel(obj, delta: int) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.MOUSE_WHEEL
	e.object = obj
	e.int_value = delta
	return e

static func mouse_clicked() -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.MOUSE_CLICKED
	return e

static func movements_confirmed() -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.MOVEMENTS_CONFIRMED
	return e

static func switch_state(gs) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.SWITCH_STATE
	e.gamestate_ref = gs
	return e

static func ai_cast_wild(die, val: int) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.AI_CAST_WILD
	e.die_ref = die
	e.int_value = val
	return e

static func ai_place_die(die, slot: int) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.AI_PLACE_DIE
	e.die_ref = die
	e.int_value = slot
	return e

static func ai_advance_goat(mountain: int) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.AI_ADVANCE_GOAT
	e.int_value = mountain
	return e

static func dragger_dropped(obj) -> GameEvent:
	var e := GameEvent.new()
	e.type = Type.DRAGGER_DROPPED
	e.object = obj
	return e
