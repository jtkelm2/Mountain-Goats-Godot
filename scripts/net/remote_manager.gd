extends RefCounted
## Player controller for the remote opponent.
## Parallel to AIManager: on_prompt() is a no-op because NetworkReplicator
## injects the appropriate GameEvents into the queue when network messages arrive.
## Game states call GameSystem.prompt_player() without knowing the player type.

func on_prompt(_gamestate) -> void:
	pass
