extends MicrogameBase

## Scramble ordered items by dragging them

var items: Array[Dictionary] = []  # {area: Area2D, original_index: int, current_index: int}
var dragging_item: Dictionary = {}
var drag_offset: Vector2 = Vector2.ZERO
var items_were_ordered: bool = true

func _define_difficulty_tiers() -> void:
	microgame_id = "unorder_items"
	microgame_name = "Unorder Items"
	instructions = "SCRAMBLE IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"item_count": 3
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"item_count": 4
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"item_count": 5
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old items
	for item_dict in items:
		if is_instance_valid(item_dict.area):
			item_dict.area.queue_free()
	items.clear()

	var count = current_parameters.item_count
	var spacing = 1280.0 / (count + 1)

	# Create numbered items in order
	for i in count:
		var area = Area2D.new()
		area.position = Vector2(spacing * (i + 1), 360)
		add_child(area)

		var visual = ColorRect.new()
		visual.size = Vector2(100, 100)
		visual.position = Vector2(-50, -50)
		visual.color = Color(0.3, 0.5, 0.8)
		area.add_child(visual)

		# Number label
		var label = Label.new()
		label.text = str(i + 1)
		label.position = Vector2(-20, -20)
		label.add_theme_font_size_override("font_size", 64)
		label.add_theme_color_override("font_color", Color.WHITE)
		area.add_child(label)

		var collision = CollisionShape2D.new()
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(100, 100)
		collision.shape = rect_shape
		area.add_child(collision)

		items.append({
			"area": area,
			"original_index": i,
			"current_index": i
		})

	items_were_ordered = true
	dragging_item = {}

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			# Find clicked item
			for item_dict in items:
				if _is_click_in_area(click_pos, item_dict.area):
					dragging_item = item_dict
					drag_offset = item_dict.area.position - click_pos
					break

		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not dragging_item.is_empty():
				# Snap to nearest slot
				var nearest_index = _get_nearest_slot(dragging_item.area.position)
				_swap_items(dragging_item.current_index, nearest_index)
				dragging_item = {}

				# Check if items are no longer in order
				_check_order()

func _update_game(_delta: float) -> void:
	if not dragging_item.is_empty():
		var mouse_pos = get_viewport().get_mouse_position()
		dragging_item.area.position = mouse_pos + drag_offset

func _get_nearest_slot(pos: Vector2) -> int:
	var count = items.size()
	var spacing = 1280.0 / (count + 1)

	var nearest = 0
	var nearest_dist = INF

	for i in count:
		var slot_x = spacing * (i + 1)
		var dist = abs(pos.x - slot_x)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = i

	return nearest

func _swap_items(index1: int, index2: int) -> void:
	if index1 == index2:
		return

	var count = items.size()
	var spacing = 1280.0 / (count + 1)

	# Update positions
	for item_dict in items:
		if item_dict.current_index == index1:
			item_dict.current_index = index2
			item_dict.area.position.x = spacing * (index2 + 1)
		elif item_dict.current_index == index2:
			item_dict.current_index = index1
			item_dict.area.position.x = spacing * (index1 + 1)

func _check_order() -> void:
	var is_ordered = true
	for item_dict in items:
		if item_dict.original_index != item_dict.current_index:
			is_ordered = false
			break

	if items_were_ordered and not is_ordered:
		_win_game()
