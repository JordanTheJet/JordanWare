extends MicrogameBase

## Drag object from start to goal while avoiding danger zones

var draggable: Area2D
var goal: Area2D
var danger_zones: Array[Area2D] = []
var is_dragging: bool = false
var has_won: bool = false

func _define_difficulty_tiers() -> void:
	microgame_id = "drag_avoid"
	microgame_name = "Drag Avoid"
	instructions = "DON'T TOUCH!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"danger_count": 2,
				"danger_speed": 0.0,
				"path_length": 300.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"danger_count": 3,
				"danger_speed": 50.0,
				"path_length": 400.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"danger_count": 4,
				"danger_speed": 100.0,
				"path_length": 500.0
			}
		}
	]

func _setup_game() -> void:
	# Draggable object
	draggable = Area2D.new()
	draggable.position = Vector2(200, 360)
	add_child(draggable)

	var drag_visual = ColorRect.new()
	drag_visual.size = Vector2(40, 40)
	drag_visual.position = Vector2(-20, -20)
	drag_visual.color = Color.BLUE
	draggable.add_child(drag_visual)

	var drag_collision = CollisionShape2D.new()
	var drag_shape = RectangleShape2D.new()
	drag_shape.size = Vector2(40, 40)
	drag_collision.shape = drag_shape
	draggable.add_child(drag_collision)

	draggable.input_pickable = true
	draggable.input_event.connect(_on_draggable_input)
	draggable.area_entered.connect(_on_danger_hit)

	# Goal
	goal = Area2D.new()
	goal.position = Vector2(1000, 360)
	add_child(goal)

	var goal_visual = ColorRect.new()
	goal_visual.size = Vector2(60, 60)
	goal_visual.position = Vector2(-30, -30)
	goal_visual.color = Color.GREEN
	goal.add_child(goal_visual)

	var goal_collision = CollisionShape2D.new()
	var goal_shape = RectangleShape2D.new()
	goal_shape.size = Vector2(60, 60)
	goal_collision.shape = goal_shape
	goal.add_child(goal_collision)

func _on_game_start() -> void:
	has_won = false
	is_dragging = false

	draggable.position = Vector2(200, 360)
	goal.position = Vector2(200 + current_parameters.path_length, 360)

	for zone in danger_zones:
		if is_instance_valid(zone):
			zone.queue_free()
	danger_zones.clear()

	# Create danger zones
	for i in current_parameters.danger_count:
		var zone = Area2D.new()
		var x = 250 + (current_parameters.path_length - 100) * (i + 1) / (current_parameters.danger_count + 1)
		var y = 360 + randf_range(-150, 150)
		zone.position = Vector2(x, y)
		zone.set_meta("move_direction", Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized())
		add_child(zone)

		var zone_visual = ColorRect.new()
		zone_visual.size = Vector2(60, 60)
		zone_visual.position = Vector2(-30, -30)
		zone_visual.color = Color.RED
		zone.add_child(zone_visual)

		var zone_collision = CollisionShape2D.new()
		var zone_shape = RectangleShape2D.new()
		zone_shape.size = Vector2(60, 60)
		zone_collision.shape = zone_shape
		zone.add_child(zone_collision)

		danger_zones.append(zone)

func _update_game(delta: float) -> void:
	if is_dragging:
		draggable.position = get_viewport().get_mouse_position()

		# Check if reached goal - calculate based on goal size dynamically
		var goal_visual = goal.get_child(0) as ColorRect
		var goal_radius = goal_visual.size.x / 2.0  # Use half the goal width as radius
		if draggable.position.distance_to(goal.position) < goal_radius and not has_won:
			has_won = true
			_win_game()

	# Move danger zones
	for zone in danger_zones:
		if is_instance_valid(zone):
			var move_dir = zone.get_meta("move_direction") as Vector2
			zone.position += move_dir * current_parameters.danger_speed * delta

			# Bounce off edges
			if zone.position.x < 50 or zone.position.x > 1230:
				move_dir.x *= -1
			if zone.position.y < 50 or zone.position.y > 670:
				move_dir.y *= -1
			zone.set_meta("move_direction", move_dir)

func _on_draggable_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = false

func _on_danger_hit(_area: Area2D) -> void:
	if is_active and not has_completed:
		_lose_game()
