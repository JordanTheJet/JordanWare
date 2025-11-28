extends MicrogameBase

## Click button that matches audio tone

var buttons: Array[Dictionary] = []  # {area: Area2D, pitch: float}
var correct_pitch: float = 1.0
var audio_player: AudioStreamPlayer

func _define_difficulty_tiers() -> void:
	microgame_id = "match_sound"
	microgame_name = "Match Sound"
	instructions = "MATCH THE SOUND!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"choice_count": 2,
				"pitch_difference": 0.3
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"choice_count": 3,
				"pitch_difference": 0.2
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"choice_count": 4,
				"pitch_difference": 0.15
			}
		}
	]

func _setup_game() -> void:
	# Audio player with a simple sine wave tone
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	# Use AudioStreamGenerator to create a simple tone
	# We'll create a simple beep sound using a generator
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.1
	audio_player.stream = stream

func _on_game_start() -> void:
	for button_data in buttons:
		if is_instance_valid(button_data.area):
			button_data.area.queue_free()
	buttons.clear()

	# Pick random correct pitch
	correct_pitch = randf_range(0.8, 1.5)

	# Play the target sound
	_play_tone(correct_pitch)
	audio_player.pitch_scale = correct_pitch
	audio_player.play()

	# Create buttons
	var choice_count = current_parameters.choice_count
	var start_x = 640 - (choice_count * 100)
	var correct_idx = randi() % choice_count

	for i in choice_count:
		var button = Area2D.new()
		button.position = Vector2(start_x + i * 200, 400)
		add_child(button)

		var pitch = correct_pitch if i == correct_idx else correct_pitch + randf_range(-current_parameters.pitch_difference, current_parameters.pitch_difference)

		var visual = ColorRect.new()
		visual.size = Vector2(120, 80)
		visual.position = Vector2(-60, -40)
		visual.color = Color.PURPLE
		button.add_child(visual)

		var label = Label.new()
		label.text = "♪"
		label.position = Vector2(-10, -15)
		label.add_theme_font_size_override("font_size", 48)
		button.add_child(label)

		var collision = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(120, 80)
		collision.shape = rect_shape
		button.add_child(collision)

		button.input_pickable = true
		button.input_event.connect(_on_button_clicked.bind(pitch))

		buttons.append({"area": button, "pitch": pitch})

func _play_tone(pitch: float) -> void:
	# Generate a simple sine wave tone
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		var increment = 440.0 * pitch / (audio_player.stream as AudioStreamGenerator).mix_rate
		var phase = 0.0
		var frames_to_fill = playback.get_frames_available()

		for i in min(frames_to_fill, 2205):  # 0.1 seconds of audio at 22050 Hz
			playback.push_frame(Vector2.ONE * sin(phase * TAU))
			phase = fmod(phase + increment, 1.0)

func _on_button_clicked(_viewport: Node, event: InputEvent, _shape_idx: int, pitch: float) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_active or has_completed:
			return

		# Play the button's tone
		audio_player.stop()
		_play_tone(pitch)
		audio_player.pitch_scale = pitch
		audio_player.play()

		if abs(pitch - correct_pitch) < 0.05:
			_win_game()
		else:
			_lose_game()
