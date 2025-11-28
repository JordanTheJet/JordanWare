extends MicrogameBase

## Shake Screen Microgame
## Objective: Shake mouse or mash keys to fill the bar
## Difficulty: Higher requirement, faster decay at higher tiers

var shake_progress: float = 0.0
var required_shake: float = 100.0
var decay_rate: float = 20.0
var last_mouse_pos: Vector2 = Vector2.ZERO
var progress_bar: ProgressBar


func _define_difficulty_tiers() -> void:
	microgame_id = "shake_screen"
	microgame_name = "Shake Screen"
	instructions = "SHAKE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"required_shake": 100.0,
				"decay_rate": 15.0
			}
		},
		{
			"tier": 2,
			"time_limit": 5.0,
			"parameters": {
				"required_shake": 150.0,
				"decay_rate": 20.0
			}
		},
		{
			"tier": 3,
			"time_limit": 5.0,
			"parameters": {
				"required_shake": 200.0,
				"decay_rate": 25.0
			}
		},
		{
			"tier": 4,
			"time_limit": 6.0,
			"parameters": {
				"required_shake": 250.0,
				"decay_rate": 30.0
			}
		}
	]


func _setup_game() -> void:
	# Create instruction
	var instruction = Label.new()
	instruction.text = "SHAKE MOUSE OR MASH KEYS!"
	instruction.position = Vector2(390, 100)
	instruction.add_theme_font_size_override("font_size", 36)
	add_child(instruction)

	# Create progress bar
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(340, 400)
	progress_bar.size = Vector2(600, 60)
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	add_child(progress_bar)

	# Create progress label
	var label = Label.new()
	label.name = "ProgressLabel"
	label.text = "0%"
	label.position = Vector2(620, 350)
	label.add_theme_font_size_override("font_size", 48)
	add_child(label)

	# Create visual shake effect container
	var shake_container = Node2D.new()
	shake_container.name = "ShakeContainer"
	shake_container.position = Vector2(640, 250)
	add_child(shake_container)

	# Create chains
	for i in range(3):
		var chain = ColorRect.new()
		chain.color = Color.GRAY
		chain.size = Vector2(10, 100)
		chain.position = Vector2(-150 + (i * 150), -100)
		shake_container.add_child(chain)

	# Create object to shake free
	var box = ColorRect.new()
	box.color = Color.ORANGE
	box.size = Vector2(100, 100)
	box.position = Vector2(-50, 0)
	shake_container.add_child(box)


func _on_game_start() -> void:
	shake_progress = 0.0
	required_shake = current_parameters.required_shake
	decay_rate = current_parameters.decay_rate
	last_mouse_pos = get_viewport().get_mouse_position()


func _update_game(delta: float) -> void:
	# Decay progress
	shake_progress = maxf(0.0, shake_progress - decay_rate * delta)

	# Update display
	_update_display()

	# Apply shake effect to visual
	var shake_container = get_node_or_null("ShakeContainer") as Node2D
	if shake_container:
		var shake_amount = (shake_progress / required_shake) * 20.0
		shake_container.position = Vector2(
			640 + randf_range(-shake_amount, shake_amount),
			250 + randf_range(-shake_amount, shake_amount)
		)

	# Check win
	if shake_progress >= required_shake:
		_win_game()


func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseMotion:
		# Calculate mouse movement
		var current_pos = event.position
		var movement = current_pos.distance_to(last_mouse_pos)
		shake_progress += movement * 0.5
		last_mouse_pos = current_pos

	elif event is InputEventKey and event.pressed:
		# Key mashing adds progress
		shake_progress += 5.0


func _update_display() -> void:
	var percentage = (shake_progress / required_shake) * 100.0
	percentage = minf(100.0, percentage)

	if progress_bar:
		progress_bar.value = percentage

	var label = get_node_or_null("ProgressLabel") as Label
	if label:
		label.text = "%d%%" % int(percentage)

		# Change color based on progress
		if percentage >= 75:
			label.modulate = Color.GREEN
		elif percentage >= 50:
			label.modulate = Color.YELLOW
		else:
			label.modulate = Color.WHITE
