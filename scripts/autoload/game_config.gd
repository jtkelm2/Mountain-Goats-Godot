extends Node
## Global game configuration singleton. Autoloaded as "GameConfig".
## Holds user-configurable settings that persist across scene changes.
## Defaults match the original hardcoded values.

enum AIDifficulty { EASY, MEDIUM, HARD }

# 0 = HUMAN, 1 = AI  (matches GameSystem.PlayerType)
var player_count: int = 4
var player_types: Array = [0, 1, 1, 1]
var ai_difficulties: Array = [-1, 2, 2, 2]  # -1 = n/a (human), 0=Easy, 1=Med, 2=Hard

var tokens_per_mountain: Dictionary = {5: 12, 6: 11, 7: 10, 8: 9, 9: 8, 10: 7}
var mountains_to_end_game: int = 4
var bonus_token_values: Array = [6, 9, 12, 15]  # lowest first; pop_back() awards highest
