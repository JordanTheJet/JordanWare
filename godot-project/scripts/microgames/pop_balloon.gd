extends MicrogameBase

## Pop Balloon - Pop all balloons

var balloon: Area2D
var balloon_y: float = 600.0
var float_speed: float = 100.0
var balloon_size: float = 80.0
var has_popped: bool = false


func _define_difficulty_tiers() -> void:
	microgame_id = "pop_balloon"
	microgame_name = "Pop Balloon"
	instructions = "POP IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"float_speed": 120.0,
				"balloon_size": 120.0
			}
		},
		{
			"tier": 2,
			"time_limit": 4.5,
			"parameters": {
				"float_speed": 150.0,
				"balloon_size": 100.0
			}
		},
		{
			"tier": 3,
			"time_limit": 4.0,
			"parameters": {
				"float_speed": 180.0,
				"balloon_size": 80.0
			}
		},
		{
			"tier": 4,
			"time_limit": 3.5,
			"parameters": {
				"float_speed": 220.0,
				"balloon_size": 60.0
			}
		}
	]


func _setup_game() -> void:
	# Create instruction
	var instruction = Label.new()
	instruction.text = "CLICK THE BALLOON!"
	instruction.position = Vector2(460, 50)
	instruction.add_theme_font_size_override("font_size", 36)
	add_child(instruction)


func _on_game_start() -> void:
	has_popped = false
	float_speed = current_parameters.float_speed
	balloon_size = current_parameters.balloon_size

	# Create balloon
	balloon = Area2D.new()
	balloon.position = Vector2(640, 600)

	# Create balloon visual
	var sprite = Sprite2D.new()
	sprite.texture = _create_balloon_texture()
	balloon.add_child(sprite)

	# Create collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = balloon_size / 2.0
	collision.shape = shape
	balloon.add_child(collision)

	add_child(balloon)
	balloon_y = 600.0


func _update_game(delta: float) -> void:
	if has_popped:
		return

	# Float balloon upward
	balloon_y -= float_speed * delta

	if balloon:
		balloon.position.y = balloon_y

		# Add gentle sway
		var sway = sin(Time.get_ticks_msec() / 500.0) * 30.0
		balloon.position.x = 640 + sway

	# Lose if balloon floats off screen
	if balloon_y < -100:
		_lose_game()


func _input(event: InputEvent) -> void:
	if not is_active or has_completed or has_popped:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_viewport().get_mouse_position()

		if _is_click_in_area(click_pos, balloon):
			has_popped = true
			_pop_balloon()
			_win_game()


func _pop_balloon() -> void:
	if balloon:
		# Create pop effect
		for i in range(8):
			var particle = ColorRect.new()
			particle.color = Color(1, 0.5, 0.5)
			particle.size = Vector2(10, 10)
			particle.position = balloon.position

			var angle = (i / 8.0) * TAU
			var velocity = Vector2(cos(angle), sin(angle)) * 200.0
			particle.set_meta("velocity", velocity)
			particle.set_meta("lifetime", 0.5)
			add_child(particle)

			# Animate particle
			_animate_particle(particle)

		balloon.queue_free()


func _animate_particle(particle: ColorRect) -> void:
	var velocity = particle.get_meta("velocity") as Vector2
	var lifetime = particle.get_meta("lifetime") as float

	while lifetime > 0:
		await get_tree().create_timer(0.016).timeout
		if not is_instance_valid(particle):
			return

		lifetime -= 0.016
		particle.position += velocity * 0.016
		velocity.y += 500.0 * 0.016  # Gravity

		particle.modulate.a = lifetime * 2.0

	if is_instance_valid(particle):
		particle.queue_free()


func _create_balloon_texture() -> ImageTexture:
	var size = int(balloon_size)
	var image = Image.create(size, int(size * 1.2), false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)

	# Draw balloon body
	for x in range(size):
		for y in range(int(size * 1.1)):
			var pos = Vector2(x, y)
			var dist = center.distance_to(pos)

			if dist <= size / 2.0 - 2:
				image.set_pixel(x, y, Color.RED)
			elif dist <= size / 2.0:
				image.set_pixel(x, y, Color.DARK_RED)

	# Draw string
	for y in range(int(size * 1.1), int(size * 1.2)):
		var x = size / 2
		image.set_pixel(int(x), y, Color.WHITE)

	return ImageTexture.create_from_image(image)


func cleanup() -> void:
	if is_instance_valid(balloon):
		balloon.queue_free()
	super.cleanup()
