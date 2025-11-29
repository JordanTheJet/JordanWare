extends MicrogameBase

## Backwards Trace - Trace path backwards

var path_points: Array[Vector2] = []
var current_point_index: int = -1
var tolerance: float = 50.0
var is_tracing: bool = false
var start_marker: ColorRect
var end_marker: ColorRect
var progress_line: Line2D

func _define_difficulty_tiers() -> void:
	microgame_id = "backwards_trace"
	microgame_name = "Backwards Trace"
	instructions = "TRACE BACKWARDS!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"point_count": 4,
				"tolerance": 60.0,
				"curve_amount": 0.2
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"point_count": 5,
				"tolerance": 45.0,
				"curve_amount": 0.5
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"point_count": 6,
				"tolerance": 35.0,
				"curve_amount": 0.8
			}
		}
	]

func _setup_game() -> void:
	# Create progress line
	progress_line = Line2D.new()
	progress_line.width = 3
	progress_line.default_color = Color.GREEN
	add_child(progress_line)

func _on_game_start() -> void:
	# Clear old markers
	if is_instance_valid(start_marker):
		start_marker.queue_free()
	if is_instance_valid(end_marker):
		end_marker.queue_free()

	path_points.clear()
	progress_line.clear_points()

	tolerance = current_parameters.tolerance
	var point_count = current_parameters.point_count

	# Generate path from left to right with some curves
	var start_x = 200.0
	var end_x = 1080.0
	var spacing = (end_x - start_x) / (point_count - 1)

	for i in point_count:
		var x = start_x + i * spacing
		var y = 360 + sin(i * current_parameters.curve_amount) * 100
		path_points.append(Vector2(x, y))

	# Draw the path (as dots or line)
	for i in path_points.size():
		var dot = ColorRect.new()
		dot.size = Vector2(12, 12)
		dot.position = path_points[i] - Vector2(6, 6)
		dot.color = Color(0.5, 0.5, 0.5, 0.5)
		add_child(dot)

		# Draw line between points
		if i > 0:
			var line = Line2D.new()
			line.add_point(path_points[i - 1])
			line.add_point(path_points[i])
			line.width = 2
			line.default_color = Color(0.5, 0.5, 0.5, 0.3)
			add_child(line)

	# Create START marker (at beginning)
	start_marker = ColorRect.new()
	start_marker.size = Vector2(60, 40)
	start_marker.position = path_points[0] - Vector2(30, 50)
	start_marker.color = Color.GREEN
	add_child(start_marker)

	var start_label = Label.new()
	start_label.text = "START"
	start_label.position = Vector2(5, 5)
	start_label.add_theme_font_size_override("font_size", 16)
	start_marker.add_child(start_label)

	# Create END marker (at end)
	end_marker = ColorRect.new()
	end_marker.size = Vector2(60, 40)
	end_marker.position = path_points[path_points.size() - 1] - Vector2(30, 50)
	end_marker.color = Color.RED
	add_child(end_marker)

	var end_label = Label.new()
	end_label.text = "END"
	end_label.position = Vector2(15, 5)
	end_label.add_theme_font_size_override("font_size", 16)
	end_marker.add_child(end_label)

	# Start from END (last point)
	current_point_index = path_points.size() - 1
	is_tracing = false

func _update_game(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()

	# Check if mouse is pressed
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not is_tracing:
			# Check if starting at END point (last point in array)
			if mouse_pos.distance_to(path_points[current_point_index]) < tolerance:
				is_tracing = true
				progress_line.add_point(mouse_pos)
		else:
			# Continue tracing - add points to show progress
			if progress_line.get_point_count() == 0 or progress_line.points[-1].distance_to(mouse_pos) > 5.0:
				progress_line.add_point(mouse_pos)

			# Validate that trace stays close to the path
			var distance_from_path = _get_distance_to_path(mouse_pos)
			if distance_from_path > tolerance:
				# Strayed too far from path
				_lose_game()
				return

			# Check if we've reached the next point (going backwards)
			var target_index = current_point_index - 1
			if target_index >= 0:
				if mouse_pos.distance_to(path_points[target_index]) < tolerance:
					current_point_index = target_index

					# Check if we've reached START
					if current_point_index == 0:
						_win_game()
						return
	else:
		# Mouse released while tracing - lose
		if is_tracing and current_point_index > 0:
			_lose_game()

func _get_distance_to_path(point: Vector2) -> float:
	# Find minimum distance from point to any path segment
	var min_distance = INF

	for i in range(current_point_index, path_points.size() - 1):
		var dist = _distance_to_line_segment(point, path_points[i], path_points[i + 1])
		min_distance = min(min_distance, dist)

	# Also check distance to current target point
	if current_point_index > 0:
		var dist_to_target = point.distance_to(path_points[current_point_index - 1])
		min_distance = min(min_distance, dist_to_target)

	return min_distance

func _distance_to_line_segment(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	# Calculate distance from point to line segment
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_length_sq = line_vec.length_squared()

	if line_length_sq == 0:
		return point.distance_to(line_start)

	var t = clamp(point_vec.dot(line_vec) / line_length_sq, 0.0, 1.0)
	var projection = line_start + t * line_vec
	return point.distance_to(projection)
