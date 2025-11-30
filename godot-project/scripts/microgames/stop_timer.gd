extends MicrogameBase

## Stop Timer - Stop at target time

var timer_value: float = 0.0
var timer_speed: float = 1.0
var target_value: float = 0.0
var tolerance: float = 0.0
var has_stopped: bool = false
var timer_label: Label


func _define_difficulty_tiers() -> void:
	microgame_id = "stop_timer"
	microgame_name = "Stop Timer"
	instructions = "STOP IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"timer_speed": 1.0,
				"target_value": 3.0,
				"tolerance": 0.3
			}
		},
		{
			"tier": 2,
			"time_limit": 5.0,
			"parameters": {
				"timer_speed": 1.5,
				"target_value": 3.33,
				"tolerance": 0.2
			}
		},
		{
			"tier": 3,
			"time_limit": 5.0,
			"parameters": {
				"timer_speed": 2.0,
				"target_value": 2.5,
				"tolerance": 0.15
			}
		},
		{
			"tier": 4,
			"time_limit": 5.0,
			"parameters": {
				"timer_speed": 3.0,
				"target_value": 1.67,
				"tolerance": 0.1
			}
		}
	]


func _setup_game() -> void:
	# Create instruction label
	var instruction = Label.new()
	instruction.text = "PRESS SPACE TO STOP"
	instruction.position = Vector2(450, 150)
	instruction.add_theme_font_size_override("font_size", 36)
	add_child(instruction)

	# Create timer display
	timer_label = Label.new()
	timer_label.position = Vector2(570, 300)
	timer_label.add_theme_font_size_override("font_size", 96)
	timer_label.modulate = Color.WHITE
	add_child(timer_label)

	# Create target display
	var target_label = Label.new()
	target_label.name = "TargetLabel"
	target_label.position = Vector2(520, 450)
	target_label.add_theme_font_size_override("font_size", 48)
	target_label.modulate = Color.YELLOW
	add_child(target_label)


func _on_game_start() -> void:
	has_stopped = false
	timer_value = 0.0
	timer_speed = current_parameters.timer_speed
	target_value = current_parameters.target_value
	tolerance = current_parameters.tolerance

	var target_label = get_node_or_null("TargetLabel") as Label
	if target_label:
		target_label.text = "TARGET: %.2f" % target_value


func _update_game(delta: float) -> void:
	if has_stopped:
		return

	# Increment timer
	timer_value += timer_speed * delta

	# Update display
	if timer_label:
		timer_label.text = "%.2f" % timer_value

	# Auto-fail if timer goes too far past target
	if timer_value > target_value + 2.0:
		_lose_game()


func _input(event: InputEvent) -> void:
	if not is_active or has_completed or has_stopped:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		has_stopped = true
		_check_result()


func _check_result() -> void:
	var difference = abs(timer_value - target_value)

	if difference <= tolerance:
		# Perfect or close enough
		if timer_label:
			timer_label.modulate = Color.GREEN
		_win_game()
	else:
		# Too far off
		if timer_label:
			timer_label.modulate = Color.RED
		_lose_game()
