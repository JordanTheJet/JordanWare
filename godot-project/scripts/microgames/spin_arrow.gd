extends MicrogameBase

## Spin Arrow - Stop in zone

var arrow: Node2D
var rotation_speed: float = 2.0
var target_start: float = 0.0
var target_size: float = 60.0
var has_stopped: bool = false


func _define_difficulty_tiers() -> void:
	microgame_id = "spin_arrow"
	microgame_name = "Spin Arrow"
	instructions = "HIT GREEN!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"rotation_speed": 2.0,
				"target_size": 70.0
			}
		},
		{
			"tier": 2,
			"time_limit": 5.0,
			"parameters": {
				"rotation_speed": 3.0,
				"target_size": 50.0
			}
		},
		{
			"tier": 3,
			"time_limit": 5.0,
			"parameters": {
				"rotation_speed": 4.0,
				"target_size": 35.0
			}
		},
		{
			"tier": 4,
			"time_limit": 5.0,
			"parameters": {
				"rotation_speed": 5.0,
				"target_size": 25.0
			}
		}
	]


func _setup_game() -> void:
	# Create circle background
	var circle = Sprite2D.new()
	circle.texture = _create_circle_texture()
	circle.position = Vector2(640, 360)
	add_child(circle)

	# Create arrow
	arrow = Node2D.new()
	arrow.position = Vector2(640, 360)

	var arrow_rect = ColorRect.new()
	arrow_rect.color = Color.WHITE
	arrow_rect.size = Vector2(10, 150)
	arrow_rect.position = Vector2(-5, -150)
	arrow.add_child(arrow_rect)

	var arrow_tip = Polygon2D.new()
	arrow_tip.polygon = PackedVector2Array([
		Vector2(-15, -150),
		Vector2(15, -150),
		Vector2(0, -180)
	])
	arrow_tip.color = Color.WHITE
	arrow.add_child(arrow_tip)

	add_child(arrow)

	# Create instruction
	var instruction = Label.new()
	instruction.text = "PRESS SPACE TO STOP"
	instruction.position = Vector2(450, 550)
	instruction.add_theme_font_size_override("font_size", 32)
	add_child(instruction)


func _on_game_start() -> void:
	has_stopped = false
	rotation_speed = current_parameters.rotation_speed
	target_size = current_parameters.target_size

	# Random target position
	target_start = randf() * 360.0

	# Reset arrow rotation
	if arrow:
		arrow.rotation_degrees = randf() * 360.0


func _update_game(delta: float) -> void:
	if has_stopped:
		return

	# Rotate arrow
	if arrow:
		arrow.rotation_degrees += rotation_speed * 100.0 * delta
		if arrow.rotation_degrees >= 360.0:
			arrow.rotation_degrees -= 360.0


func _input(event: InputEvent) -> void:
	if not is_active or has_completed or has_stopped:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		has_stopped = true
		_check_result()


func _check_result() -> void:
	# Arrow rotation: 0 = pointing up (north), increases clockwise
	# Texture angle: uses atan2 which has 0 = right (east), so texture adds 90
	# To match: arrow at 0° should match texture at 0° (both pointing up)
	var arrow_angle = arrow.rotation_degrees
	var target_end = target_start + target_size

	# Normalize angles
	while arrow_angle < 0:
		arrow_angle += 360.0
	while arrow_angle >= 360.0:
		arrow_angle -= 360.0

	# Add larger tolerance (5 degrees) to account for visual perception and fast spinning
	var tolerance = 5.0
	var check_start = target_start - tolerance
	var check_end = target_end + tolerance

	# Normalize check bounds
	if check_start < 0:
		check_start += 360.0
	if check_end > 360.0:
		check_end -= 360.0

	# Check if arrow is in target zone
	var in_target = false

	# Handle wrapping cases
	if check_start > check_end:
		# Range wraps around 0
		in_target = arrow_angle >= check_start or arrow_angle <= check_end
	else:
		# Normal range
		in_target = arrow_angle >= check_start and arrow_angle <= check_end

	# Debug output
	print("Arrow angle: ", arrow_angle, " Target: ", target_start, "-", target_end, " (with tolerance: ", check_start, "-", check_end, ") In target: ", in_target)

	if in_target:
		_win_game()
	else:
		_lose_game()


func _create_circle_texture() -> ImageTexture:
	var image = Image.create(400, 400, false, Image.FORMAT_RGBA8)
	var center = Vector2(200, 200)

	for x in range(400):
		for y in range(400):
			var dist = center.distance_to(Vector2(x, y))
			var angle = rad_to_deg(atan2(y - 200, x - 200)) + 90.0
			if angle < 0:
				angle += 360.0

			if dist >= 180 and dist <= 200:
				# Draw target zone in green
				var target_end = target_start + target_size
				var in_zone = false

				if target_end <= 360.0:
					in_zone = angle >= target_start and angle <= target_end
				else:
					in_zone = angle >= target_start or angle <= (target_end - 360.0)

				if in_zone:
					image.set_pixel(x, y, Color.GREEN)
				else:
					image.set_pixel(x, y, Color.DARK_GRAY)
			elif dist < 180:
				image.set_pixel(x, y, Color(0.2, 0.2, 0.2, 1.0))

	return ImageTexture.create_from_image(image)
