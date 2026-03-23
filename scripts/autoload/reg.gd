extends Node
## Global constants and layout values. Autoloaded as "Reg".

# Z-index layers — explicit draw order for all visual objects.
# Objects with the same layer sort by scene-tree order (earlier = below).
const Z_BG        := 0  # background image
const Z_SCOREBOARD := 1  # panel, rank sprite, score label (and awarded tokens via z_as_relative)
const Z_SQUARE    := 2  # board squares and their GridLocale children
const Z_TOKEN     := 3  # mountain tokens (stacked above mountaintops) and bonus tokens
const Z_GOAT      := 4  # player goat pieces
const Z_DICE_BOX  := 5  # dice box sprite + dice roller tray
const Z_DIE       := 6  # dice (in box, rolling, or dragged to slot)
const Z_UI        := 7  # move confirm button
const Z_DRAGGED   := 8  # any piece currently being dragged, or token in flight to scoreboard

# Tags for mouse management
const TAG_GOAT := "goat"
const TAG_DIE := "die"
const TAG_SQUARE := "square"
const TAG_DICE_BOX := "dice_box"
const TAG_TOKEN := "token"
const TAG_MOVE_CONFIRM := "move_confirm"

# Gamestate tags
const GS_DICE_ROLLING := "dice_rolling"
const GS_PLANNING := "planning"
const GS_GAMEOVER := "gameover"

# Square types
enum SquareType { MOUNTAINTOP, MOUNTAIN, MOUNTAIN_FOOT }

# Token types
enum TokenKind { MOUNTAIN, BONUS }

var SPACING: int
var GOAT_SIZE: int
var SQUARE_SIZE: int
var TOKEN_SIZE: int
var RANK_SIZE: int
var PANEL_HEIGHT: int
var PANEL_WIDTH: int
var PANEL_PLACEMENTS: Dictionary  # int -> Vector2

var BOARD_X: int
var BOARD_Y: int

var DIE_SIZE: int
var SLOT_WIDTH: int
var DICEBOX_WIDTH: int
var DICEBOX_HEIGHT: int
var DICEBOX_X: int
var DICEBOX_Y: int

var MOVE_CONFIRM_X: float
var MOVE_CONFIRM_Y: float
var MOVE_CONFIRM_WIDTH: int
var MOVE_CONFIRM_HEIGHT: int

var center_x: float
var center_y: float
var non_ui_width: int
var non_ui_height: int

var MAX_MOVE_TIME: float


func init_reg() -> void:
	var vp_w: int = int(get_viewport().get_visible_rect().size.x)
	var vp_h: int = int(get_viewport().get_visible_rect().size.y)

	SPACING = 9

	GOAT_SIZE = 60
	SQUARE_SIZE = 100
	TOKEN_SIZE = 60
	RANK_SIZE = 120
	PANEL_HEIGHT = 97
	PANEL_WIDTH = TOKEN_SIZE * 6 + RANK_SIZE

	BOARD_X = roundi((vp_w - 2 * PANEL_HEIGHT - 6 * SQUARE_SIZE) / 2.0 + PANEL_HEIGHT)
	BOARD_Y = roundi((vp_h - 2 * PANEL_HEIGHT - 5 * SQUARE_SIZE - TOKEN_SIZE) / 2.0 + PANEL_HEIGHT)
	DIE_SIZE = 45
	DICEBOX_HEIGHT = 4 * DIE_SIZE + 2 * SPACING
	DICEBOX_WIDTH = 4 * DIE_SIZE + 2 * SPACING
	DICEBOX_X = vp_w - DICEBOX_WIDTH
	DICEBOX_Y = vp_h - DICEBOX_HEIGHT

	MOVE_CONFIRM_WIDTH = 221
	MOVE_CONFIRM_HEIGHT = 98
	MOVE_CONFIRM_X = DICEBOX_X - MOVE_CONFIRM_WIDTH - SPACING
	MOVE_CONFIRM_Y = DICEBOX_Y

	center_x = vp_w / 2.0
	center_y = vp_h / 2.0
	non_ui_width = vp_w - 2 * PANEL_HEIGHT
	non_ui_height = vp_h - 2 * PANEL_HEIGHT

	PANEL_PLACEMENTS = {
		0: Vector2(DICEBOX_X - SPACING - PANEL_WIDTH / 2.0, vp_h - PANEL_HEIGHT / 2.0),
		1: Vector2(vp_w - PANEL_HEIGHT / 2.0, DICEBOX_Y - SPACING - PANEL_WIDTH / 2.0),
		2: Vector2(DICEBOX_X - SPACING - PANEL_WIDTH / 2.0, PANEL_HEIGHT / 2.0),
		3: Vector2(PANEL_HEIGHT / 2.0, DICEBOX_Y - SPACING - PANEL_WIDTH / 2.0),
	}

	MAX_MOVE_TIME = 0.4
