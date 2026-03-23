class_name Events
extends RefCounted
## Discrete event queue. Each queued event is handled by the current gamestate
## and the queue advances automatically after handle() returns (or awaits).

var _queue: Array = []  # Array[GameEvent]
var _current_gamestate = null  # GameState
var ps = null  # PlayState

var planning_state = null    # PlanningState
var dice_rolling_state = null  # DiceRollingState
var gameover_state = null    # GameoverState


func _init(play_state) -> void:
	ps = play_state


func init_gamestate() -> void:
	planning_state = load("res://scripts/states/planning_state.gd").new(ps)
	ps.add_child(planning_state)
	dice_rolling_state = load("res://scripts/states/dice_rolling_state.gd").new(ps)
	ps.add_child(dice_rolling_state)
	gameover_state = load("res://scripts/states/gameover_state.gd").new(ps)
	ps.add_child(gameover_state)
	_current_gamestate = dice_rolling_state.refresh()


func _wrapped_handle(event: GameEvent) -> void:
	await _current_gamestate.handle(event)
	next()


## Fire an event directly to the current gamestate (bypasses queue).
func handle(event: GameEvent) -> void:
	_current_gamestate.handle(event)


## Enqueue an event. If the queue was empty, handle it immediately.
## The queue advances automatically after the gamestate's handle() returns.
func queue(event: GameEvent) -> void:
	_queue.push_back(event)
	if _queue.size() == 1:
		_wrapped_handle(event)


## Advance to the next queued event. Called automatically by _wrapped_handle.
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
