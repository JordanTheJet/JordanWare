extends MicrogameBase

## Move slider away from target position

var slider_handle: Area2D
var slider_track: ColorRect
var target_marker: ColorRect
var dragging: bool = false
var drag_offset: float = 0.0
var slider_value: float = 0.5  # 0.0 to 1.0
var target_value: float = 0.5
var track_start_x: float = 200.0
var track_end_x: float = 1080.0

func _define_difficulty_tiers() -> void:
	microgame_id = "move_slider_away"
	microgame_name = "Move Slider Away"
	instructions = "MOVE AWAY!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"distance_required": 0.70  # 70% away
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"distance_required": 0.85  # 85% away
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"distance_required": 0.95  # 95% away
			}
		}
	]

func _setup_game() -> void:
	# Create slider track
	slider_track = ColorRect.new()
	slider_track.size = Vector2(track_end_x - track_start_x, 10)
	slider_track.position = Vector2(track_start_x, 355)
	slider_track.color = Color(0.3, 0.3, 0.3)
	add_child(slider_track)

	# Create target marker
	target_marker = ColorRect.new()
	target_marker.size = Vector2(20, 40)
	target_marker.position = Vector2(640, 340)
	target_marker.color = Color.RED
	add_child(target_marker)

	# Create slider handle
	slider_handle = Area2D.new()
	slider_handle.position = Vector2(640, 360)
	add_child(slider_handle)

	var handle_visual = ColorRect.new()
	handle_visual.size = Vector2(30, 50)
	handle_visual.position = Vector2(-15, -25)
	handle_visual.color = Color.BLUE
	slider_handle.add_child(handle_visual)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(30, 50)
	collision.shape = rect_shape
	slider_handle.add_child(collision)

func _on_game_start() -> void:
	# Set target at a random position
	target_value = randf_range(0.3, 0.7)

	# Start slider near target
	slider_value = target_value + randf_range(-0.05, 0.05)
	slider_value = clamp(slider_value, 0.0, 1.0)

	# Update positions
	_update_slider_position()
	_update_target_position()

	dragging = false

func _update_slider_position() -> void:
	var x = lerp(track_start_x, track_end_x, slider_value)
	slider_handle.position.x = x

func _update_target_position() -> void:
	var x = lerp(track_start_x, track_end_x, target_value)
	target_marker.position.x = x - 10  # Center the marker

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position
			if _is_click_in_area(click_pos, slider_handle):
				dragging = true
				drag_offset = slider_handle.position.x - click_pos.x

		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false

func _update_game(_delta: float) -> void:
	if dragging:
		var mouse_pos = get_viewport().get_mouse_position()
		var new_x = clamp(mouse_pos.x + drag_offset, track_start_x, track_end_x)
		slider_value = (new_x - track_start_x) / (track_end_x - track_start_x)
		_update_slider_position()

		# Check if moved far enough away
		var distance = abs(slider_value - target_value)
		if distance >= current_parameters.distance_required:
			_win_game()
