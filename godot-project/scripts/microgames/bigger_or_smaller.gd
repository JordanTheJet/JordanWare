extends MicrogameBase

## Bigger or Smaller - Click bigger circle

var circle1: Area2D
var circle2: Area2D
var bigger_index: int = 0  # 0 = left, 1 = right

func _define_difficulty_tiers() -> void:
	microgame_id = "bigger_or_smaller"
	microgame_name = "Bigger or Smaller"
	instructions = "BIGGER OR SMALLER?"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"size_difference": 0.5  # 50% difference
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"size_difference": 0.25  # 25% difference
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"size_difference": 0.10  # 10% difference
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old circles
	if is_instance_valid(circle1):
		circle1.queue_free()
	if is_instance_valid(circle2):
		circle2.queue_free()

	# Base size
	var base_size = randf_range(60.0, 90.0)
	var diff = current_parameters.size_difference

	# Randomly decide which is bigger
	bigger_index = randi() % 2

	var size1 = base_size if bigger_index == 0 else base_size / (1.0 + diff)
	var size2 = base_size if bigger_index == 1 else base_size / (1.0 + diff)

	# Create left circle
	circle1 = _create_circle(Vector2(400, 360), size1)

	# Create right circle
	circle2 = _create_circle(Vector2(880, 360), size2)

func _create_circle(pos: Vector2, radius: float) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	# Visual
	var visual = ColorRect.new()
	var size = radius * 2
	visual.size = Vector2(size, size)
	visual.position = Vector2(-radius, -radius)
	visual.color = Color.ORANGE
	area.add_child(visual)

	# Make it look like a circle (close enough with ColorRect)
	# In a real implementation, you'd use a CircleShape2D for rendering too

	# Collision - position must match visual center (at origin since Area2D is at pos)
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	collision.shape = circle_shape
	collision.position = Vector2(0, 0)  # Center at Area2D position
	area.add_child(collision)

	return area

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			var clicked_1 = _is_click_in_area(click_pos, circle1)
			var clicked_2 = _is_click_in_area(click_pos, circle2)

			if clicked_1 and bigger_index == 0:
				_win_game()
			elif clicked_2 and bigger_index == 1:
				_win_game()
			elif clicked_1 or clicked_2:
				_lose_game()

func _update_game(_delta: float) -> void:
	pass
