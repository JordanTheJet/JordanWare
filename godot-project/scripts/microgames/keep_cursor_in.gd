extends MicrogameBase

## Keep Cursor In - Stay in box

var box: ColorRect
var initial_size: Vector2
var final_size: Vector2
var shrink_time: float
var elapsed: float = 0.0
var box_center: Vector2 = Vector2(640, 360)

func _define_difficulty_tiers() -> void:
	microgame_id = "keep_cursor_in"
	microgame_name = "Keep Cursor In"
	instructions = "STAY IN BOX!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"initial_size": Vector2(600, 600),
				"final_size": Vector2(200, 200),
				"shrink_time": 4.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"initial_size": Vector2(500, 500),
				"final_size": Vector2(150, 150),
				"shrink_time": 3.5
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"initial_size": Vector2(400, 400),
				"final_size": Vector2(100, 100),
				"shrink_time": 3.0
			}
		}
	]

func _setup_game() -> void:
	# Create box
	box = ColorRect.new()
	box.color = Color(0.3, 0.3, 0.8, 0.5)
	add_child(box)

func _on_game_start() -> void:
	initial_size = current_parameters.initial_size
	final_size = current_parameters.final_size
	shrink_time = current_parameters.shrink_time
	elapsed = 0.0

	box.size = initial_size
	box.position = box_center - initial_size / 2

func _update_game(delta: float) -> void:
	elapsed += delta

	# Calculate current size with interpolation
	var t = clamp(elapsed / shrink_time, 0.0, 1.0)
	var current_size = initial_size.lerp(final_size, t)

	box.size = current_size
	box.position = box_center - current_size / 2

	# Grace period: only check cursor position after 0.5 seconds
	if elapsed < 0.5:
		return

	# Check if mouse is inside box
	var mouse_pos = get_viewport().get_mouse_position()
	var box_rect = Rect2(box.position, box.size)

	if not box_rect.has_point(mouse_pos):
		_lose_game()
