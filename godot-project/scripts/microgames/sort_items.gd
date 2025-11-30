extends MicrogameBase

## Sort Items - Sort by category

var items: Array[ColorRect] = []
var zones: Array[ColorRect] = []
var dragging_item: ColorRect = null
var drag_offset: Vector2 = Vector2.ZERO
var items_sorted: int = 0
var total_items: int = 0


func _define_difficulty_tiers() -> void:
	microgame_id = "sort_items"
	microgame_name = "Sort Items"
	instructions = "SORT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 6.0,
			"parameters": {
				"color_count": 2,
				"items_per_color": 2
			}
		},
		{
			"tier": 2,
			"time_limit": 7.0,
			"parameters": {
				"color_count": 3,
				"items_per_color": 2
			}
		},
		{
			"tier": 3,
			"time_limit": 8.0,
			"parameters": {
				"color_count": 3,
				"items_per_color": 3
			}
		},
		{
			"tier": 4,
			"time_limit": 9.0,
			"parameters": {
				"color_count": 4,
				"items_per_color": 3
			}
		}
	]


func _setup_game() -> void:
	# Create instruction
	var instruction = Label.new()
	instruction.text = "DRAG ITEMS TO MATCHING ZONES!"
	instruction.position = Vector2(380, 30)
	instruction.add_theme_font_size_override("font_size", 32)
	add_child(instruction)


func _on_game_start() -> void:
	items_sorted = 0
	dragging_item = null

	var color_count = current_parameters.color_count
	var items_per_color = current_parameters.items_per_color
	total_items = color_count * items_per_color

	var colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]

	# Create zones
	var zone_width = 200
	var zone_spacing = (1280 - (zone_width * color_count)) / (color_count + 1)

	for i in range(color_count):
		var zone = ColorRect.new()
		zone.color = Color(colors[i].r, colors[i].g, colors[i].b, 0.3)
		zone.size = Vector2(zone_width, 150)
		zone.position = Vector2(
			zone_spacing + (i * (zone_width + zone_spacing)),
			550
		)
		zone.set_meta("target_color", colors[i])
		zone.set_meta("sorted_count", 0)
		zones.append(zone)
		add_child(zone)

	# Create items in random positions
	var all_items = []
	for i in range(color_count):
		for j in range(items_per_color):
			all_items.append(colors[i])

	# Shuffle items
	all_items.shuffle()

	# Place items
	for i in range(all_items.size()):
		var item = ColorRect.new()
		item.color = all_items[i]
		item.size = Vector2(50, 50)
		item.position = Vector2(
			200 + (i * 100),
			200 + ((i % 3) * 80)
		)
		item.set_meta("target_color", all_items[i])
		item.set_meta("sorted", false)
		items.append(item)
		add_child(item)


func _update_game(_delta: float) -> void:
	# Check if all items sorted
	if items_sorted >= total_items:
		_win_game()


func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Start dragging
			var mouse_pos = get_viewport().get_mouse_position()
			for item in items:
				if not item.get_meta("sorted"):
					var rect = Rect2(item.position, item.size)
					if rect.has_point(mouse_pos):
						dragging_item = item
						drag_offset = item.position - mouse_pos
						# Move to front
						move_child(item, get_child_count() - 1)
						break

		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Stop dragging
			if dragging_item:
				_check_drop()
				dragging_item = null

	elif event is InputEventMouseMotion:
		if dragging_item:
			var mouse_pos = get_viewport().get_mouse_position()
			dragging_item.position = mouse_pos + drag_offset


func _check_drop() -> void:
	if not dragging_item:
		return

	var item_center = dragging_item.position + dragging_item.size / 2
	var item_color = dragging_item.get_meta("target_color")

	# Check if dropped in correct zone
	for zone in zones:
		var zone_rect = Rect2(zone.position, zone.size)
		if zone_rect.has_point(item_center):
			var zone_color = zone.get_meta("target_color")

			if item_color == zone_color:
				# Correct!
				dragging_item.set_meta("sorted", true)
				items_sorted += 1

				# Get count for this zone
				var zone_count = zone.get_meta("sorted_count")
				zone.set_meta("sorted_count", zone_count + 1)

				# Snap to zone using per-zone count
				dragging_item.position = zone.position + Vector2(
					zone_count * 60 + 20,
					50
				)

				# Visual feedback
				dragging_item.modulate = Color(1.5, 1.5, 1.5)
			else:
				# Wrong zone - return to original-ish position
				_reset_item_position(dragging_item)
			return

	# Not in any zone - stays where dropped (or can return to original)
	pass


func _reset_item_position(item: ColorRect) -> void:
	# Simple reset - could be improved
	var index = items.find(item)
	item.position = Vector2(
		200 + (index * 100),
		200 + ((index % 3) * 80)
	)


func cleanup() -> void:
	for item in items:
		if is_instance_valid(item):
			item.queue_free()
	items.clear()

	for zone in zones:
		if is_instance_valid(zone):
			zone.queue_free()
	zones.clear()

	super.cleanup()
