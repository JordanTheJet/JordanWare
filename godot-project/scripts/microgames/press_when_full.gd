extends MicrogameBase

## Click when progress bar reaches 100%

var progress_rect: ColorRect
var fill_amount: float = 0.0
var is_full: bool = false
var full_timer: float = 0.0
var clickable_area: Area2D

func _define_difficulty_tiers() -> void:
	microgame_id = "press_when_full"
	microgame_name = "Press When Full"
	instructions = "CLICK WHEN FULL!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"fill_time": 2.0,
				"click_window": 3.0
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"fill_time": 1.5,
				"click_window": 2.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"fill_time": 1.0,
				"click_window": 1.0
			}
		}
	]

func _setup_game() -> void:
	# Background bar
	var bg_rect = ColorRect.new()
	bg_rect.size = Vector2(600, 80)
	bg_rect.position = Vector2(340, 320)
	bg_rect.color = Color.DARK_GRAY
	add_child(bg_rect)

	# Progress bar
	progress_rect = ColorRect.new()
	progress_rect.size = Vector2(0, 80)
	progress_rect.position = Vector2(340, 320)
	progress_rect.color = Color.CYAN
	add_child(progress_rect)

	# Clickable area
	clickable_area = Area2D.new()
	clickable_area.position = Vector2(640, 360)
	add_child(clickable_area)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(600, 80)
	collision.shape = rect_shape
	clickable_area.add_child(collision)

	clickable_area.input_pickable = true
	clickable_area.input_event.connect(_on_clicked)

func _on_game_start() -> void:
	fill_amount = 0.0
	is_full = false
	full_timer = 0.0
	progress_rect.size.x = 0

func _update_game(delta: float) -> void:
	if not is_full:
		fill_amount += delta / current_parameters.fill_time
		fill_amount = min(fill_amount, 1.0)
		progress_rect.size.x = fill_amount * 600

		if fill_amount >= 1.0:
			is_full = true
			full_timer = current_parameters.click_window
	else:
		full_timer -= delta
		if full_timer <= 0:
			_lose_game()

func _on_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_active or has_completed:
			return

		if fill_amount >= 0.95:
			_win_game()
		else:
			_lose_game()
