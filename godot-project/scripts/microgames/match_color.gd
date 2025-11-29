extends MicrogameBase

## Match Color - Click matching color

var target_color: Color
var shapes: Array[Area2D] = []
var has_clicked: bool = false


func _define_difficulty_tiers() -> void:
	microgame_id = "match_color"
	microgame_name = "Match Color"
	instructions = "MATCH IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"shape_count": 3,
				"color_similarity": 0.3
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"shape_count": 4,
				"color_similarity": 0.5
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"shape_count": 5,
				"color_similarity": 0.7
			}
		},
		{
			"tier": 4,
			"time_limit": 2.5,
			"parameters": {
				"shape_count": 6,
				"color_similarity": 0.85
			}
		}
	]


func _setup_game() -> void:
	# Create target color display
	var target_label = Label.new()
	target_label.name = "TargetLabel"
	target_label.text = "MATCH THIS COLOR:"
	target_label.position = Vector2(480, 50)
	target_label.add_theme_font_size_override("font_size", 32)
	add_child(target_label)


func _on_game_start() -> void:
	has_clicked = false

	# Pick random target color
	target_color = Color(randf(), randf(), randf())

	# Create target color box
	var target_box = ColorRect.new()
	target_box.name = "TargetBox"
	target_box.color = target_color
	target_box.position = Vector2(590, 120)
	target_box.size = Vector2(100, 100)
	add_child(target_box)

	# Create shapes
	var shape_count = current_parameters.shape_count
	var similarity = current_parameters.color_similarity
	var correct_index = randi() % shape_count

	for i in range(shape_count):
		var color: Color
		if i == correct_index:
			color = target_color
		else:
			# Generate similar but different color
			color = _generate_similar_color(target_color, similarity)

		_create_shape(i, shape_count, color, i == correct_index)


func _create_shape(index: int, total: int, color: Color, is_correct: bool) -> void:
	var shape = Area2D.new()
	shape.input_pickable = true

	# Position shapes in a row
	var x = 200 + (index * (880 / total))
	var y = 400
	shape.position = Vector2(x, y)

	# Create visual
	var sprite = Sprite2D.new()
	sprite.texture = _create_shape_texture(color)
	shape.add_child(sprite)

	# Create collision
	var collision = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 50
	collision.shape = circle_shape
	shape.add_child(collision)

	# Store metadata
	shape.set_meta("is_correct", is_correct)

	# Connect signal
	shape.input_event.connect(_on_shape_clicked.bind(shape))

	shapes.append(shape)
	add_child(shape)


func _on_shape_clicked(_viewport: Node, event: InputEvent, _shape_idx: int, shape: Area2D) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not has_clicked and is_active:
			has_clicked = true
			if shape.get_meta("is_correct"):
				_win_game()
			else:
				_lose_game()


func _generate_similar_color(base: Color, similarity: float) -> Color:
	# Generate a color similar to base, but not identical
	var variation = 1.0 - similarity
	var new_color = Color(
		clampf(base.r + randf_range(-variation, variation), 0, 1),
		clampf(base.g + randf_range(-variation, variation), 0, 1),
		clampf(base.b + randf_range(-variation, variation), 0, 1)
	)

	# Ensure it's different enough from target
	if new_color.distance_to(base) < 0.1:
		new_color.r = 1.0 - base.r

	return new_color


func _create_shape_texture(color: Color) -> ImageTexture:
	var image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	var center = Vector2(50, 50)

	for x in range(100):
		for y in range(100):
			var dist = center.distance_to(Vector2(x, y))
			if dist <= 45:
				image.set_pixel(x, y, color)
			elif dist <= 50:
				image.set_pixel(x, y, Color.WHITE)

	return ImageTexture.create_from_image(image)


func cleanup() -> void:
	for shape in shapes:
		shape.queue_free()
	shapes.clear()
	super.cleanup()
