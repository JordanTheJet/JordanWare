extends MicrogameBase

## Click the odd one out - find the object that's different

var objects: Array[Area2D] = []
var odd_one_index: int = -1

func _define_difficulty_tiers() -> void:
	microgame_id = "click_odd_one"
	microgame_name = "Click Odd One"
	instructions = "FIND ODD ONE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"object_count": 3,
				"difference_type": "color",  # color, size, shade
				"object_size": 80.0
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"object_count": 5,
				"difference_type": "size",
				"object_size": 80.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.5,
			"parameters": {
				"object_count": 7,
				"difference_type": "shade",
				"object_size": 70.0
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old objects
	for obj in objects:
		if is_instance_valid(obj):
			obj.queue_free()
	objects.clear()

	var count = current_parameters.object_count
	var spacing = 1280.0 / (count + 1)

	# Pick which one is odd
	odd_one_index = randi() % count

	# Base properties
	var base_color = Color(randf_range(0.3, 0.8), randf_range(0.3, 0.8), randf_range(0.3, 0.8))
	var base_size = current_parameters.object_size

	# Create objects
	for i in count:
		var obj = Area2D.new()
		obj.position = Vector2(spacing * (i + 1), 360)
		add_child(obj)

		var visual = ColorRect.new()
		var size = base_size
		var color = base_color

		# Apply difference to odd one
		if i == odd_one_index:
			match current_parameters.difference_type:
				"color":
					# Completely different color
					color = Color(randf_range(0.0, 0.3), randf_range(0.0, 0.3), randf_range(0.8, 1.0))
				"size":
					# 50% larger
					size = base_size * 1.5
				"shade":
					# Subtle shade difference
					color = base_color.lightened(0.3)

		visual.size = Vector2(size, size)
		visual.position = Vector2(-size / 2, -size / 2)
		visual.color = color
		obj.add_child(visual)

		# Collision - position must match visual center (at origin since Area2D is at pos)
		var collision = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(size, size)
		collision.shape = rect_shape
		collision.position = Vector2(0, 0)  # Center at Area2D position
		obj.add_child(collision)

		objects.append(obj)

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			# Check which object was clicked
			for i in objects.size():
				if _is_click_in_area(click_pos, objects[i]):
					if i == odd_one_index:
						_win_game()
					else:
						_lose_game()
					return

func _update_game(_delta: float) -> void:
	pass
