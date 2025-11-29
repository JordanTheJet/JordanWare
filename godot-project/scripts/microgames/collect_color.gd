extends MicrogameBase

## Collect Color - Collect blue only

var basket: Area2D
var basket_shape: ColorRect
var falling_items: Array[Dictionary] = []  # {area: Area2D, is_target: bool}
var spawn_timer: float = 0.0
var collected_count: int = 0
var required_count: int = 0
var counter_label: Label

func _define_difficulty_tiers() -> void:
	microgame_id = "collect_color"
	microgame_name = "Collect Color"
	instructions = "GET BLUE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"required_count": 2,
				"distractor_count": 3,
				"fall_speed": 150.0
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"required_count": 3,
				"distractor_count": 5,
				"fall_speed": 180.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.5,
			"parameters": {
				"required_count": 4,
				"distractor_count": 7,
				"fall_speed": 220.0
			}
		}
	]

func _setup_game() -> void:
	# Create basket
	basket = Area2D.new()
	basket.position = Vector2(640, 600)
	add_child(basket)

	basket_shape = ColorRect.new()
	basket_shape.size = Vector2(100, 20)
	basket_shape.position = Vector2(-50, -10)
	basket_shape.color = Color.GRAY
	basket.add_child(basket_shape)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(100, 20)
	collision.shape = rect_shape
	basket.add_child(collision)

	basket.area_entered.connect(_on_item_collected)

	# Counter
	counter_label = Label.new()
	counter_label.position = Vector2(600, 20)
	counter_label.add_theme_font_size_override("font_size", 32)
	add_child(counter_label)

func _on_game_start() -> void:
	collected_count = 0
	required_count = current_parameters.required_count
	spawn_timer = 0.0

	# Clear old items
	for item_data in falling_items:
		if is_instance_valid(item_data.area):
			item_data.area.queue_free()
	falling_items.clear()

	basket.position = Vector2(640, 600)
	_update_counter()

func _update_game(delta: float) -> void:
	# Move basket
	var mouse_pos = get_viewport().get_mouse_position()
	basket.position.x = clamp(mouse_pos.x, 50, 1230)

	# Spawn items
	spawn_timer -= delta
	var total_items = current_parameters.required_count + current_parameters.distractor_count
	if spawn_timer <= 0 and falling_items.size() < total_items:
		_spawn_item()
		spawn_timer = 0.6

	# Move items
	for item_data in falling_items:
		if is_instance_valid(item_data.area):
			item_data.area.position.y += current_parameters.fall_speed * delta

			if item_data.area.position.y > 720:
				item_data.area.position.y = -50
				item_data.area.position.x = randf_range(50, 1230)

func _spawn_item() -> void:
	# Count existing target items to ensure we spawn the correct number
	var current_target_count = falling_items.filter(func(d): return d.is_target).size()
	var is_target = current_target_count < current_parameters.required_count

	var item = Area2D.new()
	item.position = Vector2(randf_range(50, 1230), -50)
	add_child(item)

	var color = Color.BLUE if is_target else ([Color.RED, Color.YELLOW, Color.GREEN, Color.ORANGE].pick_random())

	var visual = ColorRect.new()
	visual.size = Vector2(30, 30)
	visual.position = Vector2(-15, -15)
	visual.color = color
	item.add_child(visual)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(30, 30)
	collision.shape = rect_shape
	item.add_child(collision)

	falling_items.append({"area": item, "is_target": is_target})

func _on_item_collected(area: Area2D) -> void:
	if not is_active or has_completed:
		return

	var found_idx = -1
	for i in falling_items.size():
		if falling_items[i].area == area:
			found_idx = i
			break

	if found_idx == -1:
		return

	var item_data = falling_items[found_idx]

	if item_data.is_target:
		collected_count += 1
		_update_counter()

		if collected_count >= required_count:
			_win_game()
	else:
		_lose_game()

	if is_instance_valid(item_data.area):
		item_data.area.queue_free()
	falling_items.remove_at(found_idx)

func _update_counter() -> void:
	counter_label.text = "%d / %d" % [collected_count, required_count]
