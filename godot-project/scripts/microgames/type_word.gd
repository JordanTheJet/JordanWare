extends MicrogameBase

## Type Word Microgame
## Objective: Type the displayed word correctly
## Difficulty: Longer words, more similar-looking words at higher tiers

var target_word: String = ""
var typed_text: String = ""
var display_label: Label
var input_label: Label

var word_lists = {
	1: ["CAT", "DOG", "RUN", "JUMP", "BLUE"],
	2: ["APPLE", "TIGER", "QUICK", "HOUSE", "WATER"],
	3: ["PYTHON", "ROCKET", "JUNGLE", "FROZEN", "PALACE"],
	4: ["ALGORITHM", "CHAMPION", "FANTASTIC", "KEYBOARD", "VELOCITY"]
}


func _define_difficulty_tiers() -> void:
	microgame_id = "type_word"
	microgame_name = "Type Word"
	instructions = "TYPE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"word_tier": 1
			}
		},
		{
			"tier": 2,
			"time_limit": 4.5,
			"parameters": {
				"word_tier": 2
			}
		},
		{
			"tier": 3,
			"time_limit": 5.0,
			"parameters": {
				"word_tier": 3
			}
		},
		{
			"tier": 4,
			"time_limit": 6.0,
			"parameters": {
				"word_tier": 4
			}
		}
	]


func _setup_game() -> void:
	# Create target word display
	display_label = Label.new()
	display_label.position = Vector2(500, 200)
	display_label.add_theme_font_size_override("font_size", 72)
	display_label.modulate = Color.WHITE
	add_child(display_label)

	# Create input display
	input_label = Label.new()
	input_label.position = Vector2(500, 350)
	input_label.add_theme_font_size_override("font_size", 64)
	input_label.modulate = Color.YELLOW
	add_child(input_label)

	# Create cursor indicator
	var cursor = Label.new()
	cursor.name = "Cursor"
	cursor.text = "_"
	cursor.position = Vector2(500, 420)
	cursor.add_theme_font_size_override("font_size", 64)
	cursor.modulate = Color.YELLOW
	add_child(cursor)


func _on_game_start() -> void:
	typed_text = ""

	# Pick random word
	var word_tier = current_parameters.word_tier
	var words = word_lists[word_tier]
	target_word = words[randi() % words.size()]

	if display_label:
		display_label.text = target_word

	_update_display()


func _update_game(_delta: float) -> void:
	# Blink cursor
	var cursor = get_node_or_null("Cursor") as Label
	if cursor:
		var blink = int(Time.get_ticks_msec() / 500) % 2 == 0
		cursor.visible = blink


func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BACKSPACE:
			# Handle backspace
			if typed_text.length() > 0:
				typed_text = typed_text.substr(0, typed_text.length() - 1)
				_update_display()
		elif event.keycode >= KEY_A and event.keycode <= KEY_Z:
			# Handle letter input
			var letter = event.as_text_physical_keycode()
			typed_text += letter
			_update_display()
			_check_word()
		elif event.keycode == KEY_SPACE:
			# Add space if target has space (for tier 4 potential multi-word)
			if " " in target_word:
				typed_text += " "
				_update_display()
				_check_word()


func _update_display() -> void:
	if input_label:
		input_label.text = typed_text

	# Update cursor position
	var cursor = get_node_or_null("Cursor") as Label
	if cursor:
		cursor.position.x = 500 + (typed_text.length() * 35)


func _check_word() -> void:
	if typed_text.to_upper() == target_word.to_upper():
		if display_label:
			display_label.modulate = Color.GREEN
		if input_label:
			input_label.modulate = Color.GREEN
		_win_game()
	elif typed_text.length() >= target_word.length():
		# Wrong word typed
		if display_label:
			display_label.modulate = Color.RED
		if input_label:
			input_label.modulate = Color.RED
		_lose_game()
