extends MicrogameBase

## Mash the Key Microgame
## Objective: Press the specified key rapidly to fill the bar
## Difficulty: More presses required, specific keys, faster decay at higher tiers

var progress: float = 0.0
var required_presses: int = 0
var decay_rate: float = 0.0
var target_key: String = ""

var progress_bar: ProgressBar
var key_label: Label


func _define_difficulty_tiers() -> void:
	microgame_id = "mash_key"
	microgame_name = "Mash the Key"
	instructions = "MASH THE KEY!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"required_presses": 15,
				"target_key": "",  # any key
				"decay_rate": 5.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"required_presses": 20,
				"target_key": "Space",
				"decay_rate": 8.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"required_presses": 25,
				"target_key": "A",
				"decay_rate": 10.0
			}
		},
		{
			"tier": 4,
			"time_limit": 2.5,
			"parameters": {
				"required_presses": 30,
				"target_key": "X",
				"decay_rate": 15.0
			}
		}
	]


func _setup_game() -> void:
	# Create key label
	key_label = Label.new()
	key_label.position = Vector2(540, 200)
	key_label.add_theme_font_size_override("font_size", 64)
	key_label.modulate = Color.WHITE
	add_child(key_label)

	# Create progress bar
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(340, 500)
	progress_bar.size = Vector2(600, 50)
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	add_child(progress_bar)

	# Create counter label
	var counter_label = Label.new()
	counter_label.name = "CounterLabel"
	counter_label.position = Vector2(540, 450)
	counter_label.add_theme_font_size_override("font_size", 32)
	add_child(counter_label)


func _on_game_start() -> void:
	progress = 0.0
	required_presses = current_parameters.required_presses
	decay_rate = current_parameters.decay_rate
	target_key = current_parameters.target_key

	if target_key.is_empty():
		key_label.text = "ANY KEY!"
	else:
		key_label.text = target_key

	_update_display()


func _update_game(delta: float) -> void:
	# Decay progress
	progress = maxf(0.0, progress - decay_rate * delta)

	_update_display()

	# Check win
	if int(progress) >= required_presses:
		_win_game()


func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventKey and event.pressed:
		var valid_press = false

		if target_key.is_empty():
			valid_press = true
		elif target_key == "Space" and event.keycode == KEY_SPACE:
			valid_press = true
		elif event.as_text_physical_keycode() == target_key:
			valid_press = true

		if valid_press:
			progress += 1.0
			_flash_key()


func _update_display() -> void:
	if progress_bar:
		var percentage = (progress / required_presses) * 100.0
		progress_bar.value = minf(100.0, percentage)

	var counter = get_node_or_null("CounterLabel") as Label
	if counter:
		counter.text = "%d / %d" % [int(progress), required_presses]


func _flash_key() -> void:
	if key_label:
		key_label.modulate = Color.GREEN
		await get_tree().create_timer(0.1).timeout
		if key_label:
			key_label.modulate = Color.WHITE
