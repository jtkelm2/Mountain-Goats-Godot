class_name Events
extends RefCounted
## Discrete event queue with AutoNext / ManualNext resolution.
## Core architecture for sequencing game actions and animations.

enum NextType { AUTO_NEXT, MANUAL_NEXT }

var _queue: Array[Dictionary] = []  # [{type: NextType, event: GameEvent}]
var _current_gamestate = null  # Current state handler (duck-typed)
var ps  # Reference to main scene (PlayState equivalent)

var planning_state = null
var dice_rolling_state = null
var gameover_state = null

## Convenience callable: pass as a callback to trigger next() when an
## animation / tween finishes.
var next_callback: Callable


func _init(play_state) -> void:
	ps = play_state
	next_callback = func(_piece): next()


func init_gamestate() -> void:
	var DiceRollingState = load("res://scripts/states/dice_rolling_state.gd")
	var PlanningState = load("res://scripts/states/planning_state.gd")
	var GameoverState = load("res://scripts/states/gameover_state.gd")
	planning_state = PlanningState.new(ps)
	dice_rolling_state = DiceRollingState.new(ps)
	gameover_state = GameoverState.new(ps)
	_current_gamestate = dice_rolling_state.refresh()


func _wrapped_handle(entry: Dictionary) -> void:
	_current_gamestate.handle(entry.event)
	if entry.type == NextType.AUTO_NEXT:
		next()


## Fire an event directly to the current gamestate (bypasses queue).
func handle(event: GameEvent) -> void:
	_current_gamestate.handle(event)


## Enqueue an event. If the queue was empty, handle it immediately.
## Set autonext=false for events whose resolution depends on an
## asynchronous callback (e.g. a tween finishing).
func queue(event: GameEvent, autonext: bool = true) -> void:
	var entry := {
		"type": NextType.AUTO_NEXT if autonext else NextType.MANUAL_NEXT,
		"event": event,
	}
	_queue.push_back(entry)
	if _queue.size() == 1:
		_wrapped_handle(entry)


## Advance to the next queued event. Call this from tween callbacks
## when using ManualNext events.
func next() -> void:
	if _queue.size() > 0:
		_queue.pop_front()
	if _queue.size() > 0:
		_wrapped_handle(_queue[0])


## Switch the active gamestate.
func switch_state(next_gs, prompt_ai: bool = false) -> void:
	_current_gamestate = next_gs.refresh()
	if prompt_ai:
		GameSystem.prompt_ai(_current_gamestate)
