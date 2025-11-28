extends MicrogameBase

## Avoid catching falling objects - move basket to dodge them

var basket: Area2D
var basket_shape: ColorRect
var falling_items: Array[Area2D] = []
var spawn_timer: float = 0.0

func _define_difficulty_tiers() -> void:
	microgame_id = "avoid_catching"
	microgame_name = "Avoid Catching"
	instructions = "DON'T CATCH!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"item_count": 3,
				"fall_speed": 150.0,
				"basket_width": 120.0,
				"spawn_interval": 1.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"item_count": 5,
				"fall_speed": 200.0,
				"basket_width": 100.0,
				"spawn_interval": 0.7
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"item_count": 7,
				"fall_speed": 250.0,
				"basket_width": 80.0,
				"spawn_interval": 0.5
			}
		}
	]

func _setup_game() -> void:
	# Create basket
	basket = Area2D.new()
	basket.position = Vector2(640, 600)
	add_child(basket)

	# Basket visual
	basket_shape = ColorRect.new()
	basket_shape.size = Vector2(100, 20)
	basket_shape.position = Vector2(-50, -10)
	basket_shape.color = Color.BLUE
	basket.add_child(basket_shape)

	# Basket collision
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(100, 20)
	collision.shape = rect_shape
	basket.add_child(collision)

	# Connect signal
	basket.area_entered.connect(_on_item_hit_basket)

func _on_game_start() -> void:
	# Clear old items
	for item in falling_items:
		if is_instance_valid(item):
			item.queue_free()
	falling_items.clear()

	# Reset basket
	basket.position = Vector2(640, 600)
	basket_shape.size.x = current_parameters.basket_width
	basket_shape.position.x = -current_parameters.basket_width / 2

	# Update basket collision
	for child in basket.get_children():
		if child is CollisionShape2D:
			var shape = child.shape as RectangleShape2D
			shape.size.x = current_parameters.basket_width

	spawn_timer = 0.0

func _update_game(delta: float) -> void:
	# Move basket with mouse
	var mouse_pos = get_viewport().get_mouse_position()
	basket.position.x = clamp(mouse_pos.x, current_parameters.basket_width / 2, 1280 - current_parameters.basket_width / 2)

	# Spawn items
	spawn_timer -= delta
	if spawn_timer <= 0 and falling_items.size() < current_parameters.item_count:
		_spawn_item()
		spawn_timer = current_parameters.spawn_interval

	# Move items
	for item in falling_items:
		if is_instance_valid(item):
			item.position.y += current_parameters.fall_speed * delta

			# Respawn at top if reached bottom
			if item.position.y > 720:
				item.position.y = -50
				item.position.x = randf_range(50, 1230)

func _spawn_item() -> void:
	var item = Area2D.new()
	item.position = Vector2(randf_range(50, 1230), -50)
	add_child(item)

	# Visual
	var visual = ColorRect.new()
	visual.size = Vector2(30, 30)
	visual.position = Vector2(-15, -15)
	visual.color = Color.RED
	item.add_child(visual)

	# Collision
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(30, 30)
	collision.shape = rect_shape
	item.add_child(collision)

	falling_items.append(item)

func _on_item_hit_basket(_area: Area2D) -> void:
	if is_active and not has_completed:
		_lose_game()
