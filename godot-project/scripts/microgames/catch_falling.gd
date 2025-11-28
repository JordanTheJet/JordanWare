extends MicrogameBase

## Catch the Falling Microgame
## Objective: Catch the falling objects with your basket
## Difficulty: More items to catch, faster speed, smaller basket at higher tiers

var basket: Area2D
var falling_items: Array[Area2D] = []
var basket_x: float = 640.0
var caught_count: int = 0
var required_catches: int = 0
var fall_speed: float = 0.0
var basket_width: float = 0.0

var counter_label: Label


func _define_difficulty_tiers() -> void:
	microgame_id = "catch_falling"
	microgame_name = "Catch the Falling"
	instructions = "CATCH!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"required_catches": 2,
				"fall_speed": 200.0,
				"item_count": 3,
				"basket_width": 120.0
			}
		},
		{
			"tier": 2,
			"time_limit": 4.5,
			"parameters": {
				"required_catches": 3,
				"fall_speed": 300.0,
				"item_count": 5,
				"basket_width": 100.0
			}
		},
		{
			"tier": 3,
			"time_limit": 4.0,
			"parameters": {
				"required_catches": 4,
				"fall_speed": 400.0,
				"item_count": 6,
				"basket_width": 80.0
			}
		},
		{
			"tier": 4,
			"time_limit": 3.5,
			"parameters": {
				"required_catches": 5,
				"fall_speed": 500.0,
				"item_count": 7,
				"basket_width": 60.0
			}
		}
	]


func _setup_game() -> void:
	# Create basket
	basket = Area2D.new()
	basket.position = Vector2(640, 680)

	var basket_collision = CollisionShape2D.new()
	var basket_shape = RectangleShape2D.new()
	basket_collision.shape = basket_shape
	basket.add_child(basket_collision)

	var basket_sprite = ColorRect.new()
	basket_sprite.color = Color.DODGER_BLUE
	basket.add_child(basket_sprite)

	basket.area_entered.connect(_on_basket_catch)

	add_child(basket)

	# Create counter
	counter_label = Label.new()
	counter_label.position = Vector2(520, 80)
	counter_label.add_theme_font_size_override("font_size", 32)
	add_child(counter_label)


func _on_game_start() -> void:
	caught_count = 0
	required_catches = current_parameters.required_catches
	fall_speed = current_parameters.fall_speed
	basket_width = current_parameters.basket_width
	basket_x = 640.0

	# Update basket size
	var basket_collision = basket.get_child(0) as CollisionShape2D
	var basket_shape = basket_collision.shape as RectangleShape2D
	basket_shape.size = Vector2(basket_width, 30)

	var basket_sprite = basket.get_child(1) as ColorRect
	basket_sprite.position = Vector2(-basket_width / 2, -15)
	basket_sprite.size = Vector2(basket_width, 30)

	# Create falling items
	var item_count = current_parameters.item_count
	for i in range(item_count):
		_create_falling_item(i * 150.0)

	_update_counter()


func _update_game(delta: float) -> void:
	# Move basket to mouse
	var mouse_pos = get_viewport().get_mouse_position()
	basket_x = clampf(mouse_pos.x, basket_width / 2, 1280 - basket_width / 2)
	basket.position.x = basket_x

	# Update falling items
	for item in falling_items:
		if not item.get_meta("caught"):
			item.position.y += fall_speed * delta

			# Reset if missed
			if item.position.y > 750:
				item.position.y = -30
				item.position.x = randf_range(30, 1250)

	# Check win
	if caught_count >= required_catches:
		_win_game()


func _create_falling_item(y_offset: float) -> void:
	var item = Area2D.new()
	item.position = Vector2(randf_range(30, 1250), -30 - y_offset)
	item.set_meta("caught", false)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15
	collision.shape = shape
	item.add_child(collision)

	var sprite = ColorRect.new()
	sprite.color = Color.ORANGE
	sprite.position = Vector2(-15, -15)
	sprite.size = Vector2(30, 30)
	item.add_child(sprite)

	falling_items.append(item)
	add_child(item)


func _on_basket_catch(area: Area2D) -> void:
	if is_active and not area.get_meta("caught"):
		area.set_meta("caught", true)
		area.visible = false
		caught_count += 1
		_update_counter()


func _update_counter() -> void:
	if counter_label:
		counter_label.text = "%d / %d" % [caught_count, required_catches]


func cleanup() -> void:
	for item in falling_items:
		item.queue_free()
	falling_items.clear()
	super.cleanup()
