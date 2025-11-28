extends MicrogameBase

## Sequence Memory Microgame
## Objective: Repeat the sequence of buttons shown
## Difficulty: Longer sequences, faster display at higher tiers

var buttons: Array[Button] = []
var sequence: Array[int] = []
var player_sequence: Array[int] = []
var showing_sequence: bool = false
var current_show_index: int = 0
var show_timer: float = 0.0
var show_duration: float = 0.5
var show_gap: float = 0.3


func _define_difficulty_tiers() -> void:
	microgame_id = "sequence_memory"
	microgame_name = "Sequence Memory"
	instructions = "REPEAT IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 8.0,
			"parameters": {
				"sequence_length": 3,
				"button_count": 4,
				"show_duration": 0.6
			}
		},
		{
			"tier": 2,
			"time_limit": 10.0,
			"parameters": {
				"sequence_length": 4,
				"button_count": 4,
				"show_duration": 0.5
			}
		},
		{
			"tier": 3,
			"time_limit": 12.0,
			"parameters": {
				"sequence_length": 5,
				"button_count": 6,
				"show_duration": 0.4
			}
		},
		{
			"tier": 4,
			"time_limit": 14.0,
			"parameters": {
				"sequence_length": 6,
				"button_count": 6,
				"show_duration": 0.3
			}
		}
	]


func _setup_game() -> void:
	# Create instruction label
	var instruction = Label.new()
	instruction.name = "Instruction"
	instruction.text = "WATCH..."
	instruction.position = Vector2(550, 100)
	instruction.add_theme_font_size_override("font_size", 48)
	add_child(instruction)


func _on_game_start() -> void:
	sequence.clear()
	player_sequence.clear()
	showing_sequence = true
	current_show_index = 0
	show_timer = 0.0

	var button_count = current_parameters.button_count
	var sequence_length = current_parameters.sequence_length
	show_duration = current_parameters.show_duration

	# Create buttons
	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.PURPLE, Color.ORANGE]
	var positions = [
		Vector2(400, 300), Vector2(640, 300), Vector2(880, 300),
		Vector2(400, 450), Vector2(640, 450), Vector2(880, 450)
	]

	for i in range(button_count):
		var button = Button.new()
		button.custom_minimum_size = Vector2(140, 100)
		button.position = positions[i]
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.z_index = 100

		# Add colored panel as background
		var panel = Panel.new()
		panel.custom_minimum_size = button.custom_minimum_size
		panel.modulate = colors[i]
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block button clicks
		button.add_child(panel)

		button.pressed.connect(_on_button_pressed.bind(i))
		buttons.append(button)
		add_child(button)

	# Generate random sequence
	for i in range(sequence_length):
		sequence.append(randi() % button_count)


func _update_game(delta: float) -> void:
	if showing_sequence:
		show_timer += delta

		# Show next button in sequence
		if show_timer >= show_duration + show_gap:
			show_timer = 0.0

			# Reset previous button
			if current_show_index > 0:
				_reset_button(sequence[current_show_index - 1])

			# Show current button
			if current_show_index < sequence.size():
				_highlight_button(sequence[current_show_index])
				current_show_index += 1
			else:
				# Sequence shown, now player's turn
				_reset_button(sequence[sequence.size() - 1])
				showing_sequence = false
				_enable_buttons()

				var instruction = get_node_or_null("Instruction") as Label
				if instruction:
					instruction.text = "YOUR TURN!"


func _highlight_button(index: int) -> void:
	if index < buttons.size():
		var button = buttons[index]
		button.modulate = Color.WHITE
		var panel = button.get_child(0) as Panel
		if panel:
			panel.modulate.a = 1.0  # Fully visible


func _reset_button(index: int) -> void:
	if index < buttons.size():
		var button = buttons[index]
		button.modulate = Color.WHITE
		var panel = button.get_child(0) as Panel
		if panel:
			panel.modulate.a = 0.5  # Half transparent


func _enable_buttons() -> void:
	for button in buttons:
		button.disabled = false
		button.modulate = Color.WHITE
		var panel = button.get_child(0) as Panel
		if panel:
			panel.modulate.a = 0.5  # Half transparent when waiting for input


func _on_button_pressed(index: int) -> void:
	if showing_sequence or not is_active:
		return

	player_sequence.append(index)

	# Flash button
	_highlight_button(index)
	await get_tree().create_timer(0.2).timeout
	_reset_button(index)

	# Check if correct so far
	var correct = true
	for i in range(player_sequence.size()):
		if player_sequence[i] != sequence[i]:
			correct = false
			break

	if not correct:
		_lose_game()
	elif player_sequence.size() == sequence.size():
		_win_game()


func cleanup() -> void:
	for button in buttons:
		button.queue_free()
	buttons.clear()
	super.cleanup()
