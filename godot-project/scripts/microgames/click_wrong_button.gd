extends MicrogameBase

## Don't click any buttons - restraint-based game

var buttons: Array[Area2D] = []

func _define_difficulty_tiers() -> void:
	microgame_id = "click_wrong_button"
	microgame_name = "Click Wrong Button"
	instructions = "DON'T CLICK!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"button_count": 2,
				"pulse_speed": 1.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"button_count": 4,
				"pulse_speed": 1.5
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"button_count": 6,
				"pulse_speed": 2.0
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	for button in buttons:
		if is_instance_valid(button):
			button.queue_free()
	buttons.clear()

	var button_count = current_parameters.button_count
	var grid_cols = 3
	var start_x = 340
	var start_y = 200
	var spacing_x = 200
	var spacing_y = 150

	for i in button_count:
		var button = Area2D.new()
		var row = i / grid_cols
		var col = i % grid_cols
		button.position = Vector2(start_x + col * spacing_x, start_y + row * spacing_y)
		add_child(button)

		var visual = ColorRect.new()
		visual.size = Vector2(120, 80)
		visual.position = Vector2(-60, -40)
		visual.color = Color.ORANGE
		button.add_child(visual)

		var label = Label.new()
		label.text = "CLICK ME!"
		label.position = Vector2(-50, -15)
		label.add_theme_font_size_override("font_size", 20)
		button.add_child(label)

		var collision = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(120, 80)
		collision.shape = rect_shape
		button.add_child(collision)

		button.input_pickable = true
		button.input_event.connect(_on_button_clicked.bind(button))

		buttons.append(button)

func _update_game(delta: float) -> void:
	# Pulse buttons to tempt clicking
	var pulse_scale = 1.0 + sin(Time.get_ticks_msec() * 0.001 * current_parameters.pulse_speed * PI) * 0.1

	for button in buttons:
		if is_instance_valid(button):
			button.scale = Vector2(pulse_scale, pulse_scale)

func _on_button_clicked(_viewport: Node, event: InputEvent, _shape_idx: int, _button: Area2D) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_active and not has_completed:
			_lose_game()
