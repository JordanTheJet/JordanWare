extends MicrogameBase

## Connect Dots Microgame
## Objective: Click dots in numerical order
## Difficulty: More dots, less organized layout at higher tiers

var dots: Array[Dictionary] = []
var current_number: int = 1
var total_dots: int = 0
var has_failed: bool = false


func _define_difficulty_tiers() -> void:
	microgame_id = "connect_dots"
	microgame_name = "Connect Dots"
	instructions = "CONNECT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"dot_count": 3,
				"randomness": 0.2
			}
		},
		{
			"tier": 2,
			"time_limit": 6.0,
			"parameters": {
				"dot_count": 7,
				"randomness": 0.5
			}
		},
		{
			"tier": 3,
			"time_limit": 7.0,
			"parameters": {
				"dot_count": 9,
				"randomness": 0.7
			}
		},
		{
			"tier": 4,
			"time_limit": 8.0,
			"parameters": {
				"dot_count": 12,
				"randomness": 0.9
			}
		}
	]


func _setup_game() -> void:
	# Create instruction
	var instruction = Label.new()
	instruction.text = "CLICK 1, 2, 3..."
	instruction.position = Vector2(500, 50)
	instruction.add_theme_font_size_override("font_size", 36)
	add_child(instruction)


func _on_game_start() -> void:
	current_number = 1
	has_failed = false
	dots.clear()

	var dot_count = current_parameters.dot_count
	var randomness = current_parameters.randomness
	total_dots = dot_count

	# Create dots
	for i in range(dot_count):
		var number = i + 1

		# Base position in a circle pattern
		var angle = (float(i) / dot_count) * TAU
		var radius = 200.0
		var base_x = 640 + cos(angle) * radius
		var base_y = 360 + sin(angle) * radius

		# Add randomness
		var random_offset = Vector2(
			randf_range(-randomness * 200, randomness * 200),
			randf_range(-randomness * 200, randomness * 200)
		)

		var pos = Vector2(base_x, base_y) + random_offset
		pos.x = clampf(pos.x, 100, 1180)
		pos.y = clampf(pos.y, 150, 650)

		_create_dot(number, pos)


func _create_dot(number: int, pos: Vector2) -> void:
	var dot_area = Area2D.new()
	dot_area.position = pos

	# Create circle visual
	var sprite = Sprite2D.new()
	sprite.texture = _create_dot_texture()
	dot_area.add_child(sprite)

	# Create number label
	var label = Label.new()
	label.text = str(number)
	label.position = Vector2(-15, -20)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color.WHITE)
	dot_area.add_child(label)

	# Create collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30
	collision.shape = shape
	dot_area.add_child(collision)

	# Store data
	var dot_data = {
		"number": number,
		"area": dot_area,
		"clicked": false
	}
	dots.append(dot_data)

	add_child(dot_area)


func _input(event: InputEvent) -> void:
	if not is_active or has_completed or has_failed:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_viewport().get_mouse_position()

		# Check which dot was clicked
		for dot_data in dots:
			var area = dot_data["area"]
			if _is_click_in_area(click_pos, area):
				var number = dot_data["number"]

				if number == current_number:
					# Correct!
					dot_data["clicked"] = true

					# Change color and animate
					var sprite = area.get_child(0) as Sprite2D
					if sprite:
						sprite.modulate = Color.GREEN
						# Pulse animation
						var tween = create_tween()
						tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.1)
						tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

					# Draw line to previous dot
					if current_number > 1:
						_draw_line_to_previous(current_number - 1, area.position)

					current_number += 1

					# Check win
					if current_number > total_dots:
						_win_game()
				else:
					# Wrong!
					has_failed = true

					var sprite = area.get_child(0) as Sprite2D
					if sprite:
						sprite.modulate = Color.RED
						# Shake animation
						var original_pos = area.position
						var tween = create_tween()
						tween.tween_property(area, "position", original_pos + Vector2(10, 0), 0.05)
						tween.tween_property(area, "position", original_pos - Vector2(10, 0), 0.05)
						tween.tween_property(area, "position", original_pos + Vector2(10, 0), 0.05)
						tween.tween_property(area, "position", original_pos, 0.05)

					_lose_game()
				return


func _draw_line_to_previous(prev_number: int, current_pos: Vector2) -> void:
	# Find previous dot
	var prev_pos = Vector2.ZERO
	for dot in dots:
		if dot["number"] == prev_number:
			prev_pos = dot["area"].position
			break

	# Create line
	var line = Line2D.new()
	line.add_point(prev_pos)
	line.add_point(current_pos)
	line.default_color = Color.YELLOW
	line.width = 3
	add_child(line)
	move_child(line, 0)  # Move to back


func _create_dot_texture() -> ImageTexture:
	var image = Image.create(60, 60, false, Image.FORMAT_RGBA8)
	var center = Vector2(30, 30)

	for x in range(60):
		for y in range(60):
			var dist = center.distance_to(Vector2(x, y))
			if dist <= 25:
				image.set_pixel(x, y, Color.BLUE)
			elif dist <= 30:
				image.set_pixel(x, y, Color.WHITE)

	return ImageTexture.create_from_image(image)


func cleanup() -> void:
	for dot in dots:
		var area = dot.get("area")
		if is_instance_valid(area):
			area.queue_free()
	dots.clear()
	super.cleanup()
