extends MicrogameBase

## Connect Path - Make path to end

var tiles: Array[Area2D] = []
var start_index: int = 0
var end_index: int = 0
var path_indices: Array[int] = []
var clicked_tiles: Array[int] = []

func _define_difficulty_tiers() -> void:
	microgame_id = "connect_path"
	microgame_name = "Connect Path"
	instructions = "CONNECT PATH!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"path_length": 3,
				"grid_size": Vector2i(4, 3)
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"path_length": 4,
				"grid_size": Vector2i(5, 3)
			}
		},
		{
			"tier": 3,
			"time_limit": 3.5,
			"parameters": {
				"path_length": 5,
				"grid_size": Vector2i(6, 4)
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old tiles
	for tile in tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	tiles.clear()
	path_indices.clear()
	clicked_tiles.clear()

	var grid_size = current_parameters.grid_size
	var tile_size = 80.0
	var spacing = 20.0
	var total_width = grid_size.x * tile_size + (grid_size.x - 1) * spacing
	var total_height = grid_size.y * tile_size + (grid_size.y - 1) * spacing
	var start_x = 640 - total_width / 2
	var start_y = 360 - total_height / 2

	# Create grid
	for y in grid_size.y:
		for x in grid_size.x:
			var tile = _create_tile(
				Vector2(start_x + x * (tile_size + spacing), start_y + y * (tile_size + spacing)),
				tile_size,
				Color.DARK_GRAY
			)
			tiles.append(tile)

	# Generate path
	var path_length = current_parameters.path_length
	start_index = 0
	end_index = tiles.size() - 1

	# Simple path: create adjacent connections
	path_indices.append(start_index)
	var current = start_index

	for _i in range(path_length - 2):
		var neighbors = _get_adjacent_tiles(current, grid_size)
		# Filter out already used tiles
		var available = []
		for n in neighbors:
			if not path_indices.has(n) and n != end_index:
				available.append(n)

		if available.size() > 0:
			current = available[randi() % available.size()]
			path_indices.append(current)
		else:
			break

	path_indices.append(end_index)

	# Mark start and end
	var start_tile_visual = tiles[start_index].get_child(0) as ColorRect
	start_tile_visual.color = Color.GREEN

	var end_tile_visual = tiles[end_index].get_child(0) as ColorRect
	end_tile_visual.color = Color.RED

	# Add labels
	var start_label = Label.new()
	start_label.text = "S"
	start_label.position = Vector2(25, 15)
	start_label.add_theme_font_size_override("font_size", 32)
	tiles[start_index].add_child(start_label)

	var end_label = Label.new()
	end_label.text = "E"
	end_label.position = Vector2(25, 15)
	end_label.add_theme_font_size_override("font_size", 32)
	tiles[end_index].add_child(end_label)

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

func _get_adjacent_tiles(index: int, grid_size: Vector2i) -> Array[int]:
	var result: Array[int] = []
	var x = index % grid_size.x
	var y = index / grid_size.x

	# Up
	if y > 0:
		result.append(index - grid_size.x)
	# Down
	if y < grid_size.y - 1:
		result.append(index + grid_size.x)
	# Left
	if x > 0:
		result.append(index - 1)
	# Right
	if x < grid_size.x - 1:
		result.append(index + 1)

	return result

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			for i in tiles.size():
				if _is_click_in_area(click_pos, tiles[i]):
					# Can't click start or end
					if i == start_index or i == end_index:
						return

					# Can't click already clicked tiles
					if clicked_tiles.has(i):
						return

					# Must be in the path
					if not path_indices.has(i):
						_lose_game()
						return

					# Must be adjacent to last clicked or start
					var last = start_index if clicked_tiles.is_empty() else clicked_tiles[-1]
					var grid_size = current_parameters.grid_size
					var neighbors = _get_adjacent_tiles(last, grid_size)

					if not neighbors.has(i):
						_lose_game()
						return

					# Valid click!
					clicked_tiles.append(i)
					var visual = tiles[i].get_child(0) as ColorRect
					visual.color = Color.BLUE

					# Check if reached end
					var end_neighbors = _get_adjacent_tiles(i, grid_size)
					if end_neighbors.has(end_index) and clicked_tiles.size() >= path_indices.size() - 2:
						_win_game()
					return

func _update_game(_delta: float) -> void:
	pass
