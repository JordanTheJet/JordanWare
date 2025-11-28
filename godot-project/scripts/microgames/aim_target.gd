extends MicrogameBase

## Aim Target Microgame
## Objective: Click when the crosshair is over the target
## Difficulty: Faster movement, smaller target at higher tiers

var crosshair: ColorRect
var target: ColorRect
var crosshair_pos: Vector2 = Vector2(640, 360)
var movement_speed: float = 200.0
var movement_dir: Vector2 = Vector2.ZERO
var target_size: float = 100.0
var has_clicked: bool = false


func _define_difficulty_tiers() -> void:
	microgame_id = "aim_target"
	microgame_name = "Aim Target"
	instructions = "AIM!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"movement_speed": 150.0,
				"target_size": 120.0
			}
		},
		{
			"tier": 2,
			"time_limit": 5.0,
			"parameters": {
				"movement_speed": 200.0,
				"target_size": 90.0
			}
		},
		{
			"tier": 3,
			"time_limit": 5.0,
			"parameters": {
				"movement_speed": 250.0,
				"target_size": 70.0
			}
		},
		{
			"tier": 4,
			"time_limit": 5.0,
			"parameters": {
				"movement_speed": 300.0,
				"target_size": 50.0
			}
		}
	]


func _setup_game() -> void:
	# Create instruction
	var instruction = Label.new()
	instruction.text = "CLICK WHEN OVER TARGET!"
	instruction.position = Vector2(420, 50)
	instruction.add_theme_font_size_override("font_size", 36)
	add_child(instruction)

	# Create crosshair
	crosshair = ColorRect.new()
	crosshair.color = Color.TRANSPARENT
	crosshair.size = Vector2(40, 40)
	add_child(crosshair)

	# Create crosshair lines
	var h_line = ColorRect.new()
	h_line.color = Color.RED
	h_line.size = Vector2(40, 2)
	h_line.position = Vector2(0, 19)
	crosshair.add_child(h_line)

	var v_line = ColorRect.new()
	v_line.color = Color.RED
	v_line.size = Vector2(2, 40)
	v_line.position = Vector2(19, 0)
	crosshair.add_child(v_line)

	# Create center dot
	var center = ColorRect.new()
	center.color = Color.RED
	center.size = Vector2(4, 4)
	center.position = Vector2(18, 18)
	crosshair.add_child(center)


func _on_game_start() -> void:
	has_clicked = false
	movement_speed = current_parameters.movement_speed
	target_size = current_parameters.target_size

	# Create target at random position
	target = ColorRect.new()
	target.color = Color(0, 0.8, 0, 0.5)
	target.size = Vector2(target_size, target_size)
	target.position = Vector2(
		randf_range(200, 1080 - target_size),
		randf_range(200, 520 - target_size)
	)
	add_child(target)

	# Draw target circles
	var outer_ring = ColorRect.new()
	outer_ring.color = Color.TRANSPARENT
	target.add_child(outer_ring)

	# Random starting position for crosshair
	crosshair_pos = Vector2(
		randf_range(100, 1180),
		randf_range(100, 620)
	)

	# Random movement direction
	var angle = randf() * TAU
	movement_dir = Vector2(cos(angle), sin(angle))


func _update_game(delta: float) -> void:
	if has_clicked:
		return

	# Move crosshair
	crosshair_pos += movement_dir * movement_speed * delta

	# Bounce off edges
	if crosshair_pos.x < 50 or crosshair_pos.x > 1230:
		movement_dir.x *= -1
		crosshair_pos.x = clampf(crosshair_pos.x, 50, 1230)

	if crosshair_pos.y < 50 or crosshair_pos.y > 670:
		movement_dir.y *= -1
		crosshair_pos.y = clampf(crosshair_pos.y, 50, 670)

	# Update crosshair position
	if crosshair:
		crosshair.position = crosshair_pos - Vector2(20, 20)


func _input(event: InputEvent) -> void:
	if not is_active or has_completed or has_clicked:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		has_clicked = true
		_check_hit()


func _check_hit() -> void:
	# Check if crosshair center is over target
	var target_rect = Rect2(target.position, target.size)
	var crosshair_center = crosshair_pos

	if target_rect.has_point(crosshair_center):
		# Hit!
		if target:
			target.color = Color.GREEN
		if crosshair:
			var center = crosshair.get_node_or_null("ColorRect2")
			if center:
				center.color = Color.GREEN
		_win_game()
	else:
		# Miss!
		if target:
			target.color = Color.RED
		_lose_game()


func cleanup() -> void:
	if is_instance_valid(target):
		target.queue_free()
	super.cleanup()
