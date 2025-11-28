extends MicrogameBase

## Two shapes appear - click if they're same or different

var shape1: ColorRect
var shape2: ColorRect
var buttons: Array[Dictionary] = []  # {area: Area2D, answer: bool}
var are_same: bool = false

func _define_difficulty_tiers() -> void:
	microgame_id = "same_or_different"
	microgame_name = "Same Or Different"
	instructions = "SAME OR DIFFERENT?"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"difficulty": "shape"
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"difficulty": "color"
			}
		},
		{
			"tier": 3,
			"time_limit": 3.5,
			"parameters": {
				"difficulty": "size"
			}
		}
	]

func _setup_game() -> void:
	shape1 = ColorRect.new()
	shape1.size = Vector2(150, 150)
	shape1.position = Vector2(300, 285)
	add_child(shape1)

	shape2 = ColorRect.new()
	shape2.size = Vector2(150, 150)
	shape2.position = Vector2(830, 285)
	add_child(shape2)

func _on_game_start() -> void:
	for button_data in buttons:
		if is_instance_valid(button_data.area):
			button_data.area.queue_free()
	buttons.clear()

	# Determine if same or different
	are_same = randf() > 0.5

	var difficulty = current_parameters.difficulty

	if difficulty == "shape":
		# Different shapes
		if are_same:
			shape1.size = Vector2(150, 150)
			shape2.size = Vector2(150, 150)
			shape1.color = Color.BLUE
			shape2.color = Color.BLUE
		else:
			shape1.size = Vector2(150, 150)
			shape2.size = Vector2(150, 80)
			shape1.color = Color.BLUE
			shape2.color = Color.BLUE
	elif difficulty == "color":
		# Similar colors - increased difference for better visibility
		var base_color = Color(randf(), randf(), randf())
		shape1.color = base_color
		shape1.size = Vector2(150, 150)
		shape2.size = Vector2(150, 150)

		if are_same:
			shape2.color = base_color
		else:
			# Increased color difference multipliers for clearer distinction
			shape2.color = Color(base_color.r * 0.5, base_color.g * 1.5, base_color.b * 0.6)
	else:  # size
		var base_size = 150.0
		shape1.size = Vector2(base_size, base_size)
		shape1.color = Color.GREEN
		shape2.color = Color.GREEN

		if are_same:
			shape2.size = Vector2(base_size, base_size)
		else:
			shape2.size = Vector2(base_size * 0.85, base_size * 0.85)

	# Create answer buttons
	var button_labels = ["SAME", "DIFFERENT"]
	var button_values = [true, false]

	for i in 2:
		var button = Area2D.new()
		button.position = Vector2(440 + i * 250, 550)
		add_child(button)

		var visual = ColorRect.new()
		visual.size = Vector2(180, 80)
		visual.position = Vector2(-90, -40)
		visual.color = Color.PURPLE
		button.add_child(visual)

		var label = Label.new()
		label.text = button_labels[i]
		label.position = Vector2(-70, -15)
		label.add_theme_font_size_override("font_size", 32)
		button.add_child(label)

		var collision = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(180, 80)
		collision.shape = rect_shape
		button.add_child(collision)

		button.input_pickable = true
		button.input_event.connect(_on_button_clicked.bind(button_values[i]))

		buttons.append({"area": button, "answer": button_values[i]})

func _on_button_clicked(_viewport: Node, event: InputEvent, _shape_idx: int, answer: bool) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_active or has_completed:
			return

		if answer == are_same:
			_win_game()
		else:
			_lose_game()
