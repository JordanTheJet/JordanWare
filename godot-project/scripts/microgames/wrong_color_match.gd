extends MicrogameBase

## Click any button that does NOT match the central color

var center_display: ColorRect
var buttons: Array[Area2D] = []
var button_colors: Array[Color] = []
var center_color: Color
var correct_indices: Array[int] = []  # Buttons that DON'T match

func _define_difficulty_tiers() -> void:
	microgame_id = "wrong_color_match"
	microgame_name = "Wrong Color Match"
	instructions = "CLICK WRONG COLOR!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"button_count": 3,
				"color_variance": 0.5  # Obvious difference
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"button_count": 4,
				"color_variance": 0.3  # Subtle difference
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"button_count": 5,
				"color_variance": 0.15  # Very similar
			}
		}
	]

func _setup_game() -> void:
	# Create center display
	center_display = ColorRect.new()
	center_display.size = Vector2(150, 150)
	center_display.position = Vector2(565, 180)
	add_child(center_display)

func _on_game_start() -> void:
	# Clear old buttons
	for btn in buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	buttons.clear()
	button_colors.clear()
	correct_indices.clear()

	# Generate center color
	center_color = Color(randf_range(0.2, 0.8), randf_range(0.2, 0.8), randf_range(0.2, 0.8))
	center_display.color = center_color

	var count = current_parameters.button_count
	var spacing = 200.0
	var start_x = 640 - ((count - 1) * spacing) / 2

	# Generate button colors
	# At least one must match, at least one must not match
	var matching_count = randi() % (count - 1) + 1  # 1 to count-1

	for i in count:
		var color: Color
		if i < matching_count:
			# Matching color (with tiny variance)
			color = center_color + Color(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05), randf_range(-0.05, 0.05))
		else:
			# Non-matching color
			var variance = current_parameters.color_variance
			color = center_color + Color(randf_range(-variance, variance), randf_range(-variance, variance), randf_range(-variance, variance))
			correct_indices.append(i)

		button_colors.append(color)

	# Shuffle button positions
	button_colors.shuffle()

	# Update correct indices after shuffle
	correct_indices.clear()
	for i in count:
		# Calculate color difference manually (Euclidean distance in RGB space)
		var diff = button_colors[i] - center_color
		var color_diff = sqrt(diff.r * diff.r + diff.g * diff.g + diff.b * diff.b)
		if color_diff > 0.1:  # Threshold for "different"
			correct_indices.append(i)

	# Create buttons
	for i in count:
		var btn = _create_button(Vector2(start_x + i * spacing, 480), button_colors[i])
		buttons.append(btn)

func _create_button(pos: Vector2, color: Color) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	var visual = ColorRect.new()
	visual.size = Vector2(120, 120)
	visual.position = Vector2(-60, -60)
	visual.color = color
	area.add_child(visual)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(120, 120)
	collision.shape = rect_shape
	area.add_child(collision)

	return area

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			for i in buttons.size():
				if _is_click_in_area(click_pos, buttons[i]):
					if correct_indices.has(i):
						_win_game()
					else:
						_lose_game()
					return

func _update_game(_delta: float) -> void:
	pass
