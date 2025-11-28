extends MicrogameBase

## Find Different Microgame
## Objective: Click the one object that's different from the others
## Difficulty: More objects, subtler differences at higher tiers

var objects: Array[Area2D] = []
var has_clicked: bool = false


func _define_difficulty_tiers() -> void:
	microgame_id = "find_different"
	microgame_name = "Find Different"
	instructions = "FIND IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"object_count": 4,
				"size_difference": 0.5  # Different is 50% different in size
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"object_count": 6,
				"size_difference": 0.3
			}
		},
		{
			"tier": 3,
			"time_limit": 4.0,
			"parameters": {
				"object_count": 8,
				"size_difference": 0.2
			}
		},
		{
			"tier": 4,
			"time_limit": 4.0,
			"parameters": {
				"object_count": 9,
				"size_difference": 0.15
			}
		}
	]


func _setup_game() -> void:
	# Create instruction
	var instruction = Label.new()
	instruction.text = "CLICK THE DIFFERENT ONE!"
	instruction.position = Vector2(420, 50)
	instruction.add_theme_font_size_override("font_size", 36)
	add_child(instruction)


func _on_game_start() -> void:
	has_clicked = false

	var object_count = current_parameters.object_count
	var size_diff = current_parameters.size_difference

	# Pick which one will be different
	var different_index = randi() % object_count

	# Pick random base color and size
	var base_color = Color(randf(), randf(), randf())
	var base_size = 60.0

	# Calculate different size
	var different_size = base_size * (1.0 + size_diff)

	# Create objects in a grid
	var cols = int(ceil(sqrt(object_count)))
	var rows = int(ceil(float(object_count) / cols))

	var start_x = 640 - (cols * 100) / 2
	var start_y = 360 - (rows * 100) / 2

	for i in range(object_count):
		var row = i / cols
		var col = i % cols

		var x = start_x + (col * 120) + 60
		var y = start_y + (row * 120) + 60

		var is_different = (i == different_index)
		var size = different_size if is_different else base_size

		_create_object(Vector2(x, y), base_color, size, is_different)


func _create_object(pos: Vector2, color: Color, size: float, is_different: bool) -> void:
	var obj = Area2D.new()
	obj.position = pos

	# Create visual
	var sprite = Sprite2D.new()
	sprite.texture = _create_circle_texture(color, int(size))
	obj.add_child(sprite)

	# Create collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = size / 2.0
	collision.shape = shape
	obj.add_child(collision)

	# Store metadata
	obj.set_meta("is_different", is_different)

	objects.append(obj)
	add_child(obj)


func _input(event: InputEvent) -> void:
	if not is_active or has_completed or has_clicked:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_viewport().get_mouse_position()

		# Check which object was clicked
		for obj in objects:
			if _is_click_in_area(click_pos, obj):
				has_clicked = true

				# Flash the clicked object
				var sprite = obj.get_child(0) as Sprite2D
				if sprite:
					sprite.modulate = Color.WHITE if obj.get_meta("is_different") else Color.RED

				if obj.get_meta("is_different"):
					_win_game()
				else:
					_lose_game()
				return


func _create_circle_texture(color: Color, size: int) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0

	for x in range(size):
		for y in range(size):
			var dist = center.distance_to(Vector2(x, y))
			if dist <= radius - 2:
				image.set_pixel(x, y, color)
			elif dist <= radius:
				image.set_pixel(x, y, Color.WHITE)

	return ImageTexture.create_from_image(image)


func cleanup() -> void:
	for obj in objects:
		obj.queue_free()
	objects.clear()
	super.cleanup()
