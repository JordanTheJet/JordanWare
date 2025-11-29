extends MicrogameBase

## Click Circle - Click shrinking circle

var circle: Area2D
var circle_size: float = 0.0
var shrink_rate: float = 0.0
var has_clicked: bool = false


func _define_difficulty_tiers() -> void:
	microgame_id = "click_circle"
	microgame_name = "Click the Circle"
	instructions = "CLICK IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"initial_size": 120.0,
				"shrink_rate": 20.0  # pixels per second
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"initial_size": 90.0,
				"shrink_rate": 30.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"initial_size": 60.0,
				"shrink_rate": 50.0
			}
		},
		{
			"tier": 4,
			"time_limit": 2.5,
			"parameters": {
				"initial_size": 40.0,
				"shrink_rate": 80.0
			}
		}
	]


func _setup_game() -> void:
	# Create circle
	circle = Area2D.new()
	circle.position = Vector2(640, 360)  # Center of screen
	circle.input_pickable = true  # IMPORTANT: Enable input detection

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	collision.shape = shape
	circle.add_child(collision)

	var sprite = Sprite2D.new()
	sprite.texture = _create_circle_texture()
	circle.add_child(sprite)

	# Connect input signal
	circle.input_event.connect(_on_circle_input_event)

	add_child(circle)


func _on_game_start() -> void:
	has_clicked = false
	circle_size = current_parameters.initial_size
	shrink_rate = current_parameters.shrink_rate

	_update_circle_size()


func _update_game(delta: float) -> void:
	if has_clicked:
		return

	# Shrink circle
	circle_size = max(10.0, circle_size - shrink_rate * delta)
	_update_circle_size()


func _update_circle_size() -> void:
	if circle:
		var collision = circle.get_child(0) as CollisionShape2D
		var shape = collision.shape as CircleShape2D
		shape.radius = circle_size / 2.0

		var sprite = circle.get_child(1) as Sprite2D
		sprite.scale = Vector2(circle_size / 128.0, circle_size / 128.0)


func _on_circle_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not has_clicked and is_active:
			has_clicked = true
			_win_game()


func _create_circle_texture() -> ImageTexture:
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var center = Vector2(64, 64)

	for x in range(128):
		for y in range(128):
			var dist = center.distance_to(Vector2(x, y))
			if dist <= 60:
				image.set_pixel(x, y, Color.RED)
			elif dist <= 64:
				image.set_pixel(x, y, Color.WHITE)

	return ImageTexture.create_from_image(image)
