extends MicrogameBase

## Count Objects - Count and click

var objects: Array[ColorRect] = []
var correct_count: int = 0
var buttons: Array[Button] = []
var showing_objects: bool = true
var show_timer: float = 0.0


func _define_difficulty_tiers() -> void:
	microgame_id = "count_objects"
	microgame_name = "Count Objects"
	instructions = "COUNT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 6.0,
			"parameters": {
				"min_count": 3,
				"max_count": 5,
				"show_duration": 2.0
			}
		},
		{
			"tier": 2,
			"time_limit": 6.0,
			"parameters": {
				"min_count": 5,
				"max_count": 8,
				"show_duration": 1.5
			}
		},
		{
			"tier": 3,
			"time_limit": 6.0,
			"parameters": {
				"min_count": 7,
				"max_count": 12,
				"show_duration": 1.2
			}
		},
		{
			"tier": 4,
			"time_limit": 6.0,
			"parameters": {
				"min_count": 10,
				"max_count": 15,
				"show_duration": 1.0
			}
		}
	]


func _setup_game() -> void:
	# Create instruction
	var instruction = Label.new()
	instruction.name = "Instruction"
	instruction.text = "WATCH AND COUNT!"
	instruction.position = Vector2(480, 50)
	instruction.add_theme_font_size_override("font_size", 36)
	add_child(instruction)


func _on_game_start() -> void:
	showing_objects = true
	show_timer = 0.0
	objects.clear()

	var min_count = current_parameters.min_count
	var max_count = current_parameters.max_count
	correct_count = randi_range(min_count, max_count)

	# Create objects at random positions
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE]

	for i in range(correct_count):
		var obj = ColorRect.new()
		obj.color = colors[randi() % colors.size()]
		obj.size = Vector2(50, 50)
		obj.position = Vector2(
			randf_range(100, 1180),
			randf_range(150, 550)
		)
		objects.append(obj)
		add_child(obj)


func _update_game(delta: float) -> void:
	if showing_objects:
		show_timer += delta
		var show_duration = current_parameters.show_duration

		if show_timer >= show_duration:
			# Hide objects and show buttons
			for obj in objects:
				obj.queue_free()
			objects.clear()

			showing_objects = false
			_show_answer_buttons()

			var instruction = get_node_or_null("Instruction") as Label
			if instruction:
				instruction.text = "HOW MANY?"


func _show_answer_buttons() -> void:
	# Generate answer options (correct + 3 wrong)
	var options = [correct_count]

	while options.size() < 4:
		var wrong = correct_count + randi_range(-3, 3)
		if wrong > 0 and wrong not in options:
			options.append(wrong)

	# Shuffle options
	options.shuffle()

	# Create buttons
	for i in range(4):
		var button = Button.new()
		button.text = str(options[i])
		button.custom_minimum_size = Vector2(120, 100)
		button.position = Vector2(340 + (i * 160), 320)
		button.add_theme_font_size_override("font_size", 56)
		button.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure it receives mouse input
		button.z_index = 100  # Bring to front

		var option_value = options[i]
		button.pressed.connect(_on_answer_clicked.bind(option_value))
		buttons.append(button)
		add_child(button)


func _on_answer_clicked(value: int) -> void:
	if not is_active or has_completed:
		return

	if value == correct_count:
		_win_game()
	else:
		_lose_game()


func cleanup() -> void:
	for obj in objects:
		if is_instance_valid(obj):
			obj.queue_free()
	objects.clear()

	for button in buttons:
		if is_instance_valid(button):
			button.queue_free()
	buttons.clear()

	super.cleanup()
