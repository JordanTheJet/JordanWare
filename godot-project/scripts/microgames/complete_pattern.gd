extends MicrogameBase

## Complete Pattern - Finish the pattern

var pattern_display: Array[ColorRect] = []
var choice_buttons: Array[Area2D] = []
var correct_choice_index: int = 0
var pattern_colors: Array[Color] = []

func _define_difficulty_tiers() -> void:
	microgame_id = "complete_pattern"
	microgame_name = "Complete Pattern"
	instructions = "FINISH PATTERN!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"pattern_type": "ABA",  # Simple A-B-A
				"choice_count": 3
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"pattern_type": "ABC",  # A-B-C-A-B-C
				"choice_count": 4
			}
		},
		{
			"tier": 3,
			"time_limit": 3.5,
			"parameters": {
				"pattern_type": "ABCD",  # More complex
				"choice_count": 5
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old elements
	for rect in pattern_display:
		if is_instance_valid(rect):
			rect.queue_free()
	for btn in choice_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	pattern_display.clear()
	choice_buttons.clear()
	pattern_colors.clear()

	# Generate pattern colors based on type
	var pattern_type = current_parameters.pattern_type
	match pattern_type:
		"ABA":
			pattern_colors = [
				Color.RED,
				Color.BLUE,
				Color.RED
			]
		"ABC":
			pattern_colors = [
				Color.RED,
				Color.BLUE,
				Color.GREEN
			]
		"ABCD":
			pattern_colors = [
				Color.RED,
				Color.BLUE,
				Color.GREEN,
				Color.YELLOW
			]

	# Create pattern display (show pattern with one missing)
	var display_pattern = pattern_colors.duplicate()
	display_pattern.append(pattern_colors[0])  # Continue pattern
	display_pattern.append(pattern_colors[1 % pattern_colors.size()])

	# Remove one element (the one to guess)
	var missing_index = display_pattern.size() - 1
	var correct_color = display_pattern[missing_index]
	display_pattern[missing_index] = Color.GRAY  # Show as question mark

	var spacing = 100.0
	var start_x = 640 - (display_pattern.size() * spacing) / 2 + spacing / 2

	for i in display_pattern.size():
		var rect = ColorRect.new()
		rect.size = Vector2(80, 80)
		rect.position = Vector2(start_x + i * spacing - 40, 200)
		rect.color = display_pattern[i]
		add_child(rect)
		pattern_display.append(rect)

		# Add question mark if it's the missing one
		if i == missing_index:
			var label = Label.new()
			label.text = "?"
			label.position = Vector2(20, 0)
			label.add_theme_font_size_override("font_size", 64)
			label.add_theme_color_override("font_color", Color.WHITE)
			rect.add_child(label)

	# Create choice buttons
	var choice_count = current_parameters.choice_count
	var choice_colors: Array[Color] = []

	# Add correct color
	choice_colors.append(correct_color)
	correct_choice_index = 0

	# Add wrong colors
	var possible_colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.ORANGE, Color.PURPLE, Color.CYAN]
	for color in possible_colors:
		if choice_colors.size() >= choice_count:
			break
		if not choice_colors.has(color):
			choice_colors.append(color)

	# Shuffle choices
	choice_colors.shuffle()
	correct_choice_index = choice_colors.find(correct_color)

	var choice_spacing = 150.0
	var choice_start_x = 640 - ((choice_count - 1) * choice_spacing) / 2

	for i in choice_count:
		var btn = _create_choice_button(Vector2(choice_start_x + i * choice_spacing, 450), choice_colors[i])
		choice_buttons.append(btn)

func _create_choice_button(pos: Vector2, color: Color) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	var visual = ColorRect.new()
	visual.size = Vector2(100, 100)
	visual.position = Vector2(-50, -50)
	visual.color = color
	area.add_child(visual)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(100, 100)
	collision.shape = rect_shape
	area.add_child(collision)

	return area

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			for i in choice_buttons.size():
				if _is_click_in_area(click_pos, choice_buttons[i]):
					if i == correct_choice_index:
						_win_game()
					else:
						_lose_game()
					return

func _update_game(_delta: float) -> void:
	pass
