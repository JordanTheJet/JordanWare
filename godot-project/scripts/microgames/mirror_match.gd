extends MicrogameBase

## Create a mirror image of the pattern on the left

var left_grid: Array[ColorRect] = []
var right_grid: Array[Area2D] = []
var pattern: Array[bool] = []
var player_pattern: Array[bool] = []
var grid_size: int = 3

func _define_difficulty_tiers() -> void:
	microgame_id = "mirror_match"
	microgame_name = "Mirror Match"
	instructions = "MIRROR IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"grid_size": 3
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"grid_size": 4
			}
		},
		{
			"tier": 3,
			"time_limit": 3.5,
			"parameters": {
				"grid_size": 5
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old grids
	for cell in left_grid:
		if is_instance_valid(cell):
			cell.queue_free()
	for cell in right_grid:
		if is_instance_valid(cell):
			cell.queue_free()
	left_grid.clear()
	right_grid.clear()
	pattern.clear()
	player_pattern.clear()

	grid_size = current_parameters.grid_size
	var cell_size = 60.0
	var spacing = 5.0
	var grid_total = grid_size * cell_size + (grid_size - 1) * spacing

	# Generate random pattern
	for _i in range(grid_size * grid_size):
		pattern.append(randf() > 0.5)
		player_pattern.append(false)

	# Create left grid (pattern to mirror)
	var left_start_x = 320 - grid_total / 2
	var grid_start_y = 360 - grid_total / 2

	for y in grid_size:
		for x in grid_size:
			var cell = ColorRect.new()
			cell.size = Vector2(cell_size, cell_size)
			cell.position = Vector2(
				left_start_x + x * (cell_size + spacing),
				grid_start_y + y * (cell_size + spacing)
			)
			var index = y * grid_size + x
			cell.color = Color.BLUE if pattern[index] else Color.DARK_GRAY
			add_child(cell)
			left_grid.append(cell)

	# Create right grid (interactive, mirrored positions)
	var right_start_x = 960 - grid_total / 2

	for y in grid_size:
		for x in grid_size:
			var area = Area2D.new()
			# Mirror the x position
			var mirrored_x = grid_size - 1 - x
			area.position = Vector2(
				right_start_x + mirrored_x * (cell_size + spacing) + cell_size / 2,
				grid_start_y + y * (cell_size + spacing) + cell_size / 2
			)
			add_child(area)

			var cell = ColorRect.new()
			cell.size = Vector2(cell_size, cell_size)
			cell.position = Vector2(-cell_size / 2, -cell_size / 2)
			cell.color = Color.DARK_GRAY
			area.add_child(cell)

			var collision = CollisionShape2D.new()
			var rect_shape = RectangleShape2D.new()
			rect_shape.size = Vector2(cell_size, cell_size)
			collision.shape = rect_shape
			area.add_child(collision)

			right_grid.append(area)

	# Add divider line
	var divider = ColorRect.new()
	divider.size = Vector2(5, grid_total)
	divider.position = Vector2(637.5, 360 - grid_total / 2)
	divider.color = Color.WHITE
	add_child(divider)

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_pos = event.position

			for i in right_grid.size():
				if _is_click_in_area(click_pos, right_grid[i]):
					# Toggle cell
					player_pattern[i] = !player_pattern[i]
					var visual = right_grid[i].get_child(0) as ColorRect
					visual.color = Color.BLUE if player_pattern[i] else Color.DARK_GRAY

					# Check if pattern matches (mirrored)
					_check_match()
					return

func _check_match() -> void:
	for y in grid_size:
		for x in grid_size:
			var pattern_index = y * grid_size + x
			var mirrored_x = grid_size - 1 - x
			var player_index = y * grid_size + mirrored_x

			if pattern[pattern_index] != player_pattern[player_index]:
				return

	_win_game()

func _update_game(_delta: float) -> void:
	pass
