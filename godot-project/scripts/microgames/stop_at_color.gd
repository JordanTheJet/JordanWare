extends MicrogameBase

## Click when rectangle is green - color cycling game

var color_rect: ColorRect
var current_color_idx: int = 0
var color_timer: float = 0.0
var colors: Array[Color] = [Color.RED, Color.BLUE, Color.YELLOW, Color.GREEN, Color.PURPLE]
var clickable_area: Area2D

func _define_difficulty_tiers() -> void:
	microgame_id = "stop_at_color"
	microgame_name = "Stop At Color"
	instructions = "STOP ON GREEN!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"cycle_speed": 1.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"cycle_speed": 0.5
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"cycle_speed": 0.3
			}
		}
	]

func _setup_game() -> void:
	color_rect = ColorRect.new()
	color_rect.size = Vector2(300, 300)
	color_rect.position = Vector2(490, 210)
	color_rect.color = colors[0]
	add_child(color_rect)

	clickable_area = Area2D.new()
	clickable_area.position = Vector2(640, 360)
	add_child(clickable_area)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(300, 300)
	collision.shape = rect_shape
	clickable_area.add_child(collision)

	clickable_area.input_pickable = true
	clickable_area.input_event.connect(_on_clicked)

func _on_game_start() -> void:
	current_color_idx = 0
	color_timer = current_parameters.cycle_speed
	color_rect.color = colors[0]

func _update_game(delta: float) -> void:
	color_timer -= delta

	if color_timer <= 0:
		current_color_idx = (current_color_idx + 1) % colors.size()
		color_rect.color = colors[current_color_idx]
		color_timer = current_parameters.cycle_speed

func _on_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_active or has_completed:
			return

		if color_rect.color == Color.GREEN:
			_win_game()
		else:
			_lose_game()
