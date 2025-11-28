extends MicrogameBase

## Click target many times quickly

var target: Area2D
var click_count: int = 0
var required_clicks: int = 5
var counter_label: Label

func _define_difficulty_tiers() -> void:
	microgame_id = "rapid_click"
	microgame_name = "Rapid Click"
	instructions = "TAP FAST!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 3.0,
			"parameters": {
				"required_clicks": 5
			}
		},
		{
			"tier": 2,
			"time_limit": 3.0,
			"parameters": {
				"required_clicks": 8
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"required_clicks": 12
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old target
	if is_instance_valid(target):
		target.queue_free()

	click_count = 0
	required_clicks = current_parameters.required_clicks

	# Create target
	target = Area2D.new()
	target.position = Vector2(640, 360)
	add_child(target)

	var visual = ColorRect.new()
	visual.size = Vector2(200, 200)
	visual.position = Vector2(-100, -100)
	visual.color = Color.RED
	target.add_child(visual)

	counter_label = Label.new()
	counter_label.text = "0 / %d" % required_clicks
	counter_label.position = Vector2(-60, -40)
	counter_label.add_theme_font_size_override("font_size", 56)
	counter_label.add_theme_color_override("font_color", Color.WHITE)
	target.add_child(counter_label)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(200, 200)
	collision.shape = rect_shape
	target.add_child(collision)

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			if _is_click_in_area(click_pos, target):
				click_count += 1

				# Update counter to show progress (X / Y format)
				counter_label.text = "%d / %d" % [click_count, required_clicks]

				# Visual feedback
				var visual = target.get_child(0) as ColorRect
				visual.color = Color.YELLOW
				await get_tree().create_timer(0.05).timeout
				if is_instance_valid(visual):
					visual.color = Color.RED

				# Check if enough clicks
				if click_count >= required_clicks:
					_win_game()

func _update_game(_delta: float) -> void:
	pass
