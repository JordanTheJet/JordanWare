extends MicrogameBase

## Double tap the target quickly

var target: Area2D
var first_tap_time: float = -1.0
var max_time_between_taps: float = 1.0
var visual_feedback_tween: Tween

func _define_difficulty_tiers() -> void:
	microgame_id = "double_tap"
	microgame_name = "Double Tap"
	instructions = "DOUBLE TAP!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"target_size": 150.0,
				"tap_interval": 1.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"target_size": 120.0,
				"tap_interval": 0.5
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"target_size": 90.0,
				"tap_interval": 0.3
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old target
	if is_instance_valid(target):
		target.queue_free()

	first_tap_time = -1.0
	max_time_between_taps = current_parameters.tap_interval

	var size = current_parameters.target_size

	# Create target at random position
	var margin = size / 2 + 50
	var pos = Vector2(
		randf_range(margin, 1280 - margin),
		randf_range(margin, 720 - margin)
	)

	target = Area2D.new()
	target.position = pos
	add_child(target)

	var visual = ColorRect.new()
	visual.size = Vector2(size, size)
	visual.position = Vector2(-size / 2, -size / 2)
	visual.color = Color.ORANGE
	target.add_child(visual)

	var label = Label.new()
	label.text = "TAP\nTWICE"
	label.position = Vector2(-30, -20)
	label.add_theme_font_size_override("font_size", 20)
	target.add_child(label)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(size, size)
	collision.shape = rect_shape
	target.add_child(collision)

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			if _is_click_in_area(click_pos, target):
				var current_time = Time.get_ticks_msec() / 1000.0

				if first_tap_time < 0:
					# First tap - provide visual feedback
					first_tap_time = current_time
					var visual = target.get_child(0) as ColorRect
					visual.color = Color.YELLOW

					# Add scale pulse feedback
					if visual_feedback_tween:
						visual_feedback_tween.kill()
					visual_feedback_tween = create_tween()
					visual_feedback_tween.tween_property(target, "scale", Vector2(1.2, 1.2), 0.1)
					visual_feedback_tween.tween_property(target, "scale", Vector2(1.0, 1.0), 0.1)
				else:
					# Second tap
					var time_diff = current_time - first_tap_time

					if time_diff <= max_time_between_taps:
						_win_game()
					else:
						_lose_game()

func _update_game(_delta: float) -> void:
	# Check if too much time has passed since first tap
	if first_tap_time >= 0:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - first_tap_time > max_time_between_taps:
			# Reset tap state and visual feedback
			first_tap_time = -1.0
			if is_instance_valid(target):
				target.scale = Vector2(1.0, 1.0)
				var visual = target.get_child(0) as ColorRect
				visual.color = Color.ORANGE
