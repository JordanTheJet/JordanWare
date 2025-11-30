extends MicrogameBase

## Balance Scale - Balance with weights

var scale_visual: Line2D
var left_weight_display: Label
var right_weight_display: Label
var weight_buttons: Array[Area2D] = []
var weight_values: Array[int] = []
var left_weight: int = 0
var right_weight: int = 0
var target_difference: int = 0

func _define_difficulty_tiers() -> void:
	microgame_id = "balance_scale"
	microgame_name = "Balance Scale"
	instructions = "BALANCE IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"weight_count": 3,
				"max_weight": 5
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"weight_count": 4,
				"max_weight": 7
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"weight_count": 5,
				"max_weight": 10
			}
		}
	]

func _setup_game() -> void:
	# Create scale base
	var base = ColorRect.new()
	base.size = Vector2(400, 20)
	base.position = Vector2(440, 300)
	base.color = Color.DARK_GRAY
	add_child(base)

	# Create scale arms
	scale_visual = Line2D.new()
	scale_visual.width = 5
	scale_visual.default_color = Color.GRAY
	add_child(scale_visual)

	# Create weight displays
	var left_plate = ColorRect.new()
	left_plate.size = Vector2(150, 20)
	left_plate.position = Vector2(350, 350)
	left_plate.color = Color.DARK_GRAY
	add_child(left_plate)

	var right_plate = ColorRect.new()
	right_plate.size = Vector2(150, 20)
	right_plate.position = Vector2(780, 350)
	right_plate.color = Color.DARK_GRAY
	add_child(right_plate)

	left_weight_display = Label.new()
	left_weight_display.position = Vector2(410, 320)
	left_weight_display.add_theme_font_size_override("font_size", 32)
	add_child(left_weight_display)

	right_weight_display = Label.new()
	right_weight_display.position = Vector2(840, 320)
	right_weight_display.add_theme_font_size_override("font_size", 32)
	add_child(right_weight_display)

func _on_game_start() -> void:
	# Clear old buttons
	for btn in weight_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	weight_buttons.clear()
	weight_values.clear()

	# Generate starting weights (unbalanced)
	var max_weight = current_parameters.max_weight
	left_weight = randi() % max_weight + 3
	right_weight = randi() % (max_weight - 2) + 1

	# Ensure they're different
	while abs(left_weight - right_weight) < 2:
		right_weight = randi() % max_weight + 1

	target_difference = left_weight - right_weight

	# Create weight buttons (one of them will balance the scale)
	var weight_count = current_parameters.weight_count
	weight_values.append(abs(target_difference))  # Correct weight

	# Add wrong weights
	for _i in range(weight_count - 1):
		var wrong_weight = randi() % max_weight + 1
		while wrong_weight == abs(target_difference):
			wrong_weight = randi() % max_weight + 1
		weight_values.append(wrong_weight)

	weight_values.shuffle()

	var spacing = 150.0
	var start_x = 640 - ((weight_count - 1) * spacing) / 2

	for i in weight_count:
		var btn = _create_weight_button(Vector2(start_x + i * spacing, 550), weight_values[i])
		weight_buttons.append(btn)

	_update_displays()

func _create_weight_button(pos: Vector2, weight: int) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	var visual = ColorRect.new()
	visual.size = Vector2(80, 80)
	visual.position = Vector2(-40, -40)
	visual.color = Color.BROWN
	area.add_child(visual)

	var label = Label.new()
	label.text = str(weight)
	label.position = Vector2(-15, -15)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	area.add_child(label)

	# Collision - position must match visual center (at origin since Area2D is at pos)
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(80, 80)
	collision.shape = rect_shape
	collision.position = Vector2(0, 0)  # Center at Area2D position
	area.add_child(collision)

	return area

func _update_displays() -> void:
	left_weight_display.text = str(left_weight)
	right_weight_display.text = str(right_weight)

	# Update scale tilt
	scale_visual.clear_points()
	var tilt = clamp(float(left_weight - right_weight) / 10.0, -1.0, 1.0)
	scale_visual.add_point(Vector2(640 - 200, 310 - tilt * 30))
	scale_visual.add_point(Vector2(640 + 200, 310 + tilt * 30))

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			for i in weight_buttons.size():
				if _is_click_in_area(click_pos, weight_buttons[i]):
					# Add weight to lighter side
					if left_weight < right_weight:
						left_weight += weight_values[i]
					else:
						right_weight += weight_values[i]

					_update_displays()

					# Check if balanced
					if abs(left_weight - right_weight) <= 1:
						_win_game()
					return

func _update_game(_delta: float) -> void:
	pass
