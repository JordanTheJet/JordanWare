extends MicrogameBase

## Hold button while beats scroll, release between beats

var beat_markers: Array[ColorRect] = []
var target_zone: ColorRect
var current_beat_index: int = 0
var scroll_speed: float = 200.0
var beat_count: int = 2
var should_be_holding: bool = false
var is_holding: bool = false
var failed: bool = false

func _define_difficulty_tiers() -> void:
	microgame_id = "rhythm_hold"
	microgame_name = "Rhythm Hold"
	instructions = "HOLD THE BEAT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"beat_count": 2,
				"scroll_speed": 150.0,
				"beat_width": 100.0,
				"gap_width": 80.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"beat_count": 3,
				"scroll_speed": 200.0,
				"beat_width": 80.0,
				"gap_width": 60.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"beat_count": 4,
				"scroll_speed": 250.0,
				"beat_width": 70.0,
				"gap_width": 50.0
			}
		}
	]

func _setup_game() -> void:
	# Create target zone
	target_zone = ColorRect.new()
	target_zone.size = Vector2(150, 150)
	target_zone.position = Vector2(565, 285)
	target_zone.color = Color(0.3, 0.3, 0.8, 0.3)
	add_child(target_zone)

	# Add label
	var label = Label.new()
	label.text = "HOLD ZONE"
	label.position = Vector2(20, 60)
	label.add_theme_font_size_override("font_size", 20)
	target_zone.add_child(label)

func _on_game_start() -> void:
	# Clear old markers
	for marker in beat_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	beat_markers.clear()

	current_beat_index = 0
	scroll_speed = current_parameters.scroll_speed
	beat_count = current_parameters.beat_count
	failed = false
	is_holding = false
	should_be_holding = false

	# Create beat markers scrolling from right to left
	var beat_width = current_parameters.beat_width
	var gap_width = current_parameters.gap_width
	var start_x = 1400.0

	for i in beat_count:
		var marker = ColorRect.new()
		marker.size = Vector2(beat_width, 150)
		marker.position = Vector2(start_x + i * (beat_width + gap_width), 285)
		marker.color = Color.GREEN
		add_child(marker)
		beat_markers.append(marker)

func _update_game(delta: float) -> void:
	if failed:
		return

	# Move beat markers
	for marker in beat_markers:
		if is_instance_valid(marker):
			marker.position.x -= scroll_speed * delta

	# Check if holding mouse button
	is_holding = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	# Check each beat marker with grace period for timing
	var any_in_zone = false
	var grace_pixels = 75.0  # ~75ms grace period at 200 scroll_speed

	for marker in beat_markers:
		if is_instance_valid(marker):
			var marker_left = marker.position.x
			var marker_right = marker.position.x + marker.size.x
			var zone_left = target_zone.position.x - grace_pixels
			var zone_right = target_zone.position.x + target_zone.size.x + grace_pixels

			# Check if any part of marker overlaps with zone (with grace period)
			if marker_right > zone_left and marker_left < zone_right:
				any_in_zone = true
				break

	should_be_holding = any_in_zone

	# Check if player is doing the right thing
	if should_be_holding and not is_holding:
		# Should be holding but isn't
		failed = true
		_lose_game()
		return
	elif not should_be_holding and is_holding:
		# Shouldn't be holding but is
		failed = true
		_lose_game()
		return

	# Check if all beats have passed
	if beat_markers.size() > 0:
		var last_marker = beat_markers[-1]
		if is_instance_valid(last_marker) and last_marker.position.x + last_marker.size.x < 0:
			_win_game()

	# Update target zone color based on state
	if should_be_holding:
		target_zone.color = Color(0.3, 0.8, 0.3, 0.5) if is_holding else Color(0.8, 0.3, 0.3, 0.5)
	else:
		target_zone.color = Color(0.3, 0.3, 0.8, 0.3) if not is_holding else Color(0.8, 0.3, 0.3, 0.5)
