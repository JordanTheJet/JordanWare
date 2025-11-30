extends MicrogameBase

## Crack Code - Guess the code

var code: Array[int] = []
var current_guess: Array[int] = []
var digit_buttons: Array[Array] = []  # 2D array of buttons
var submit_button: Area2D
var attempts_left: int = 3
var feedback_label: Label
var attempts_label: Label

func _define_difficulty_tiers() -> void:
	microgame_id = "crack_code"
	microgame_name = "Crack Code"
	instructions = "GUESS CODE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 6.0,
			"parameters": {
				"code_length": 2,
				"max_attempts": 3
			}
		},
		{
			"tier": 2,
			"time_limit": 5.0,
			"parameters": {
				"code_length": 3,
				"max_attempts": 2
			}
		},
		{
			"tier": 3,
			"time_limit": 4.0,
			"parameters": {
				"code_length": 3,
				"max_attempts": 1
			}
		}
	]

func _setup_game() -> void:
	# Create feedback label
	feedback_label = Label.new()
	feedback_label.position = Vector2(440, 150)
	feedback_label.add_theme_font_size_override("font_size", 32)
	add_child(feedback_label)

	# Create attempts label
	attempts_label = Label.new()
	attempts_label.position = Vector2(520, 200)
	attempts_label.add_theme_font_size_override("font_size", 24)
	add_child(attempts_label)

func _on_game_start() -> void:
	# Clear old buttons
	for row in digit_buttons:
		for btn in row:
			if is_instance_valid(btn):
				btn.queue_free()
	digit_buttons.clear()

	if is_instance_valid(submit_button):
		submit_button.queue_free()

	var code_length = current_parameters.code_length
	attempts_left = current_parameters.max_attempts

	# Generate random code
	code.clear()
	for _i in code_length:
		code.append(randi() % 10)

	# Initialize guess
	current_guess.clear()
	for _i in code_length:
		current_guess.append(0)

	# Create digit selector buttons for each position
	var button_size = 50.0
	var spacing = 10.0
	var start_y = 300.0

	for pos in code_length:
		var col_buttons: Array = []
		var start_x = 640 - (code_length * (button_size + spacing)) / 2 + pos * (button_size + spacing)

		for digit in 10:
			var btn = _create_digit_button(
				Vector2(start_x, start_y + digit * (button_size + spacing)),
				button_size,
				digit,
				pos
			)
			col_buttons.append(btn)

		digit_buttons.append(col_buttons)

	# Create submit button
	submit_button = Area2D.new()
	submit_button.position = Vector2(640, 650)
	add_child(submit_button)

	var submit_visual = ColorRect.new()
	submit_visual.size = Vector2(200, 50)
	submit_visual.position = Vector2(-100, -25)
	submit_visual.color = Color.GREEN
	submit_button.add_child(submit_visual)

	var submit_label = Label.new()
	submit_label.text = "SUBMIT"
	submit_label.position = Vector2(-40, -10)
	submit_label.add_theme_font_size_override("font_size", 24)
	submit_button.add_child(submit_label)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(200, 50)
	collision.shape = rect_shape
	submit_button.add_child(collision)

	_update_display()

func _create_digit_button(pos: Vector2, size: float, digit: int, position: int) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	var visual = ColorRect.new()
	visual.size = Vector2(size, size)
	visual.position = Vector2(-size / 2, -size / 2)
	visual.color = Color.GRAY
	area.add_child(visual)

	var label = Label.new()
	label.text = str(digit)
	label.position = Vector2(-10, -10)
	label.add_theme_font_size_override("font_size", 24)
	area.add_child(label)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(size, size)
	collision.shape = rect_shape
	area.add_child(collision)

	# Store digit and position as metadata
	area.set_meta("digit", digit)
	area.set_meta("position", position)

	return area

func _update_display() -> void:
	feedback_label.text = "Code: " + " ".join(current_guess.map(func(d): return str(d)))
	attempts_label.text = "Attempts: " + str(attempts_left)

	# Highlight selected digits
	for pos in digit_buttons.size():
		for digit in digit_buttons[pos].size():
			var btn = digit_buttons[pos][digit]
			var visual = btn.get_child(0) as ColorRect
			if digit == current_guess[pos]:
				visual.color = Color.YELLOW
			else:
				visual.color = Color.GRAY

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			# Check digit buttons
			for pos in digit_buttons.size():
				for btn in digit_buttons[pos]:
					if _is_click_in_area(click_pos, btn):
						var digit = btn.get_meta("digit")
						var position = btn.get_meta("position")
						current_guess[position] = digit
						_update_display()
						return

			# Check submit button
			if _is_click_in_area(click_pos, submit_button):
				_submit_guess()

func _submit_guess() -> void:
	# Check if guess matches code
	var matches = true
	for i in code.size():
		if current_guess[i] != code[i]:
			matches = false
			break

	if matches:
		_win_game()
	else:
		attempts_left -= 1

		if attempts_left <= 0:
			_lose_game()
		else:
			# Give Mastermind-style feedback
			var correct_position = 0  # Right digit in right position
			var correct_digit = 0  # Right digit in wrong position

			# Check for correct positions first
			var code_used = []
			var guess_used = []
			for i in code.size():
				code_used.append(false)
				guess_used.append(false)

			# First pass: count exact matches (correct position)
			for i in code.size():
				if current_guess[i] == code[i]:
					correct_position += 1
					code_used[i] = true
					guess_used[i] = true

			# Second pass: count digits that exist but are in wrong position
			for i in code.size():
				if not guess_used[i]:
					for j in code.size():
						if not code_used[j] and current_guess[i] == code[j]:
							correct_digit += 1
							code_used[j] = true
							break

			# Display feedback
			feedback_label.text = "Code: " + " ".join(current_guess.map(func(d): return str(d))) + " | ✓" + str(correct_position) + " ~" + str(correct_digit)
			_update_display()

func _update_game(_delta: float) -> void:
	pass
