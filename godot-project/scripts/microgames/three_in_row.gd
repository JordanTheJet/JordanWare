extends MicrogameBase

## Swap tiles to make three in a row

var grid: Array[Area2D] = []
var grid_colors: Array[Color] = []
var grid_size: Vector2i = Vector2i(4, 4)
var selected_tile: int = -1
var possible_colors: Array[Color] = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.ORANGE]

func _define_difficulty_tiers() -> void:
	microgame_id = "three_in_row"
	microgame_name = "Three in Row"
	instructions = "MAKE THREE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"grid_size": Vector2i(4, 4),
				"color_count": 3
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"grid_size": Vector2i(5, 5),
				"color_count": 4
			}
		},
		{
			"tier": 3,
			"time_limit": 3.5,
			"parameters": {
				"grid_size": Vector2i(5, 5),
				"color_count": 5
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old grid
	for tile in grid:
		if is_instance_valid(tile):
			tile.queue_free()
	grid.clear()
	grid_colors.clear()
	selected_tile = -1

	grid_size = current_parameters.grid_size
	var color_count = current_parameters.color_count
	var colors = possible_colors.slice(0, color_count)

	var tile_size = 70.0
	var spacing = 5.0
	var grid_total_x = grid_size.x * tile_size + (grid_size.x - 1) * spacing
	var grid_total_y = grid_size.y * tile_size + (grid_size.y - 1) * spacing
	var start_x = 640 - grid_total_x / 2
	var start_y = 360 - grid_total_y / 2

	# Generate grid with at least one possible match
	for y in grid_size.y:
		for x in grid_size.x:
			var color = colors[randi() % colors.size()]
			grid_colors.append(color)

	# Ensure at least one valid swap exists
	_ensure_valid_swap(colors)

	# Create tiles
	for y in grid_size.y:
		for x in grid_size.x:
			var tile = _create_tile(
				Vector2(start_x + x * (tile_size + spacing), start_y + y * (tile_size + spacing)),
				tile_size,
				grid_colors[y * grid_size.x + x]
			)
			grid.append(tile)

func _create_tile(pos: Vector2, size: float, color: Color) -> Area2D:
	var area = Area2D.new()
	area.position = pos
	add_child(area)

	var visual = ColorRect.new()
	visual.size = Vector2(size, size)
	visual.position = Vector2(0, 0)
	visual.color = color
	area.add_child(visual)

	# Collision - position must match visual center
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(size, size)
	collision.position = Vector2(size / 2, size / 2)  # Center of the tile
	collision.shape = rect_shape
	area.add_child(collision)

	return area

func _ensure_valid_swap(colors: Array[Color]) -> void:
	# Create a guaranteed match opportunity
	var row = randi() % grid_size.y
	var col = randi() % (grid_size.x - 2)
	var color = colors[randi() % colors.size()]

	var idx1 = row * grid_size.x + col
	var idx2 = row * grid_size.x + col + 1
	var idx3 = row * grid_size.x + col + 2

	grid_colors[idx1] = color
	grid_colors[idx2] = colors[(colors.find(color) + 1) % colors.size()]
	grid_colors[idx3] = color

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			for i in grid.size():
				if _is_click_in_area(click_pos, grid[i]):
					if selected_tile == -1:
						# First tile selected
						selected_tile = i
						var visual = grid[i].get_child(0) as ColorRect
						visual.modulate = Color.WHITE * 1.5
					else:
						# Second tile selected - try to swap
						var x1 = selected_tile % grid_size.x
						var y1 = selected_tile / grid_size.x
						var x2 = i % grid_size.x
						var y2 = i / grid_size.x

						# Check if adjacent
						if abs(x1 - x2) + abs(y1 - y2) == 1:
							# Swap colors
							var temp = grid_colors[selected_tile]
							grid_colors[selected_tile] = grid_colors[i]
							grid_colors[i] = temp

							# Update visuals
							var visual1 = grid[selected_tile].get_child(0) as ColorRect
							visual1.color = grid_colors[selected_tile]
							visual1.modulate = Color.WHITE

							var visual2 = grid[i].get_child(0) as ColorRect
							visual2.color = grid_colors[i]

							# Check for match
							if _check_for_match():
								_win_game()

							selected_tile = -1
						else:
							# Deselect previous, select new
							var visual1 = grid[selected_tile].get_child(0) as ColorRect
							visual1.modulate = Color.WHITE

							selected_tile = i
							var visual2 = grid[i].get_child(0) as ColorRect
							visual2.modulate = Color.WHITE * 1.5
					return

func _check_for_match() -> bool:
	# Check horizontal matches
	for y in grid_size.y:
		for x in range(grid_size.x - 2):
			var idx1 = y * grid_size.x + x
			var idx2 = y * grid_size.x + x + 1
			var idx3 = y * grid_size.x + x + 2

			if grid_colors[idx1] == grid_colors[idx2] and grid_colors[idx2] == grid_colors[idx3]:
				return true

	# Check vertical matches
	for x in grid_size.x:
		for y in range(grid_size.y - 2):
			var idx1 = y * grid_size.x + x
			var idx2 = (y + 1) * grid_size.x + x
			var idx3 = (y + 2) * grid_size.x + x

			if grid_colors[idx1] == grid_colors[idx2] and grid_colors[idx2] == grid_colors[idx3]:
				return true

	return false

func _update_game(_delta: float) -> void:
	pass
