extends MicrogameBase

## Break Sequence - Click wrong button

var buttons: Array[Area2D] = []
var pattern: Array[int] = []
var flash_timer: float = 0.0
var pattern_shown: bool = false
var current_flash_index: int = 0
var flash_duration: float = 0.3
var flash_gap: float = 0.2

func _define_difficulty_tiers() -> void:
	microgame_id = "break_sequence"
	microgame_name = "Break Sequence"
	instructions = "BREAK PATTERN!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"pattern_length": 2,
				"button_count": 4
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"pattern_length": 3,
				"button_count": 5
			}
		},
		{
			"tier": 3,
			"time_limit": 3.5,
			"parameters": {
				"pattern_length": 4,
				"button_count": 6
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old buttons
	for btn in buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	buttons.clear()
	pattern.clear()

	var count = current_parameters.button_count
	var cols = ceili(sqrt(count))
	var spacing = 150.0
	var start_x = 640 - (cols * spacing) / 2 + spacing / 2

	# Create buttons
	for i in count:
		var row = i / cols
		var col = i % cols
		var btn = _create_button(Vector2(start_x + col * spacing, 250 + row * spacing), Color.GRAY)
		buttons.append(btn)

	# Generate pattern (unique indices)
	var available_indices = range(count)
	for _i in current_parameters.pattern_length:
		var idx = randi() % available_indices.size()
		pattern.append(available_indices[idx])
		available_indices.remove_at(idx)

	flash_timer = 0.0
	pattern_shown = false
	current_flash_index = 0

func _create_button(pos: Vector2, color: Color) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	var visual = ColorRect.new()
	visual.size = Vector2(80, 80)
	visual.position = Vector2(-40, -40)
	visual.color = color
	area.add_child(visual)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(80, 80)
	collision.shape = rect_shape
	area.add_child(collision)

	return area

func _update_game(delta: float) -> void:
	if pattern_shown:
		return

	flash_timer += delta

	var cycle_time = flash_duration + flash_gap
	var total_time = pattern.size() * cycle_time + 0.5  # Extra time at end

	if flash_timer > total_time:
		pattern_shown = true
		# Reset all buttons to normal
		for btn in buttons:
			var visual = btn.get_child(0) as ColorRect
			visual.color = Color.GRAY
		return

	var cycle_index = int(flash_timer / cycle_time)
	var in_cycle_time = fmod(flash_timer, cycle_time)

	if cycle_index < pattern.size():
		var is_flashing = in_cycle_time < flash_duration

		# Update button colors
		for i in buttons.size():
			var visual = buttons[i].get_child(0) as ColorRect
			if i == pattern[cycle_index] and is_flashing:
				visual.color = Color.YELLOW
			else:
				visual.color = Color.GRAY

func _input(event: InputEvent) -> void:
	if not is_active or has_completed or not pattern_shown:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			for i in buttons.size():
				if _is_click_in_area(click_pos, buttons[i]):
					# Check if this button is NOT in pattern
					if not pattern.has(i):
						_win_game()
					else:
						_lose_game()
					return
