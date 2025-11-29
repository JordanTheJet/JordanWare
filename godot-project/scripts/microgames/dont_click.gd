extends MicrogameBase

## Don't Click - Don't click anything

var has_clicked: bool = false
var distractors: Array[Button] = []


func _define_difficulty_tiers() -> void:
	microgame_id = "dont_click"
	microgame_name = "Don't Click"
	instructions = "RESIST!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 3.0,
			"parameters": {
				"distractor_count": 0,
				"moving": false
			}
		},
		{
			"tier": 2,
			"time_limit": 3.0,
			"parameters": {
				"distractor_count": 3,
				"moving": false
			}
		},
		{
			"tier": 3,
			"time_limit": 2.5,
			"parameters": {
				"distractor_count": 5,
				"moving": true
			}
		},
		{
			"tier": 4,
			"time_limit": 2.5,
			"parameters": {
				"distractor_count": 8,
				"moving": true
			}
		}
	]


func _setup_game() -> void:
	# Create warning text
	var warning = Label.new()
	warning.text = "RESIST!"
	warning.position = Vector2(500, 300)
	warning.add_theme_font_size_override("font_size", 72)
	warning.add_theme_color_override("font_color", Color.CRIMSON)
	add_child(warning)


func _on_game_start() -> void:
	has_clicked = false

	# Create distractors
	var distractor_count = current_parameters.distractor_count
	var moving = current_parameters.moving

	for i in range(distractor_count):
		_create_distractor(moving)


# Override _process to make timeout = win (survival game)
func _process(delta: float) -> void:
	if not is_active or has_completed:
		return

	# Update timer
	time_remaining -= delta

	# Win if survived without clicking
	if time_remaining <= 0:
		_win_game()
		return

	# Update game-specific logic
	_update_game(delta)


func _update_game(delta: float) -> void:
	# Move distractors if applicable
	var moving = current_parameters.moving
	if moving:
		for i in range(distractors.size()):
			var button = distractors[i]
			var velocity = button.get_meta("velocity") as Vector2
			var pos = button.position + velocity * delta * 10.0

			# Bounce off edges
			if pos.x < 0 or pos.x > 1100:
				velocity.x *= -1
			if pos.y < 0 or pos.y > 600:
				velocity.y *= -1

			button.set_meta("velocity", velocity)
			button.position = pos


func _create_distractor(moving: bool) -> void:
	var button = Button.new()
	var texts = ["CLICK ME!", "PRESS!", "TAP HERE!", "DO IT!"]
	button.text = texts[randi() % texts.size()]
	button.position = Vector2(randf_range(100, 1000), randf_range(50, 500))
	button.size = Vector2(150, 60)

	if moving:
		var velocity = Vector2(randf_range(-2, 2), randf_range(-2, 2))
		button.set_meta("velocity", velocity)

	button.pressed.connect(_on_distractor_clicked)
	distractors.append(button)
	add_child(button)


func _on_distractor_clicked() -> void:
	if not has_clicked and is_active:
		has_clicked = true
		_lose_game()


func _input(event: InputEvent) -> void:
	# Only process input when game is actively running
	if not is_active or has_completed or has_clicked:
		return

	# Only detect mouse button down events (not releases)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		has_clicked = true
		_lose_game()


func cleanup() -> void:
	for button in distractors:
		button.queue_free()
	distractors.clear()
	super.cleanup()
