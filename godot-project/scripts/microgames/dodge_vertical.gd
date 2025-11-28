extends MicrogameBase

## Move character up/down to dodge obstacles coming from sides

var player: Area2D
var player_shape: ColorRect
var obstacles: Array[Area2D] = []
var spawn_timer: float = 0.0

func _define_difficulty_tiers() -> void:
	microgame_id = "dodge_vertical"
	microgame_name = "Dodge Vertical"
	instructions = "DODGE UP/DOWN!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"obstacle_count": 3,
				"obstacle_speed": 250.0,
				"gap_size": 200.0,
				"spawn_interval": 1.5
			}
		},
		{
			"tier": 2,
			"time_limit": 4.0,
			"parameters": {
				"obstacle_count": 5,
				"obstacle_speed": 300.0,
				"gap_size": 150.0,
				"spawn_interval": 1.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.5,
			"parameters": {
				"obstacle_count": 7,
				"obstacle_speed": 350.0,
				"gap_size": 120.0,
				"spawn_interval": 0.7
			}
		}
	]

func _setup_game() -> void:
	# Create player
	player = Area2D.new()
	player.position = Vector2(200, 360)
	add_child(player)

	player_shape = ColorRect.new()
	player_shape.size = Vector2(40, 40)
	player_shape.position = Vector2(-20, -20)
	player_shape.color = Color.GREEN
	player.add_child(player_shape)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(40, 40)
	collision.shape = rect_shape
	player.add_child(collision)

	player.area_entered.connect(_on_hit_obstacle)

func _on_game_start() -> void:
	for obstacle in obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	obstacles.clear()

	player.position = Vector2(200, 360)
	spawn_timer = 0.5

func _update_game(delta: float) -> void:
	# Move player vertically with mouse
	var mouse_pos = get_viewport().get_mouse_position()
	player.position.y = clamp(mouse_pos.y, 20, 700)

	# Spawn obstacles
	spawn_timer -= delta
	if spawn_timer <= 0:
		_spawn_obstacle()
		spawn_timer = current_parameters.spawn_interval

	# Move obstacles
	for obstacle in obstacles:
		if is_instance_valid(obstacle):
			obstacle.position.x -= current_parameters.obstacle_speed * delta

			if obstacle.position.x < -100:
				obstacle.queue_free()
				obstacles.erase(obstacle)

func _spawn_obstacle() -> void:
	# Create gap in random position
	var gap_center = randf_range(current_parameters.gap_size, 720 - current_parameters.gap_size)

	# Top obstacle
	var top_height = gap_center - current_parameters.gap_size / 2
	var top = Area2D.new()
	top.position = Vector2(1380, 0)  # Position at top of screen
	add_child(top)

	var top_visual = ColorRect.new()
	top_visual.size = Vector2(50, top_height)
	top_visual.position = Vector2(-25, 0)  # Start from top
	top_visual.color = Color.RED
	top.add_child(top_visual)

	var top_collision = CollisionShape2D.new()
	var top_shape = RectangleShape2D.new()
	top_shape.size = Vector2(50, top_height)
	top_collision.shape = top_shape
	top_collision.position = Vector2(0, top_height / 2)  # Center collision shape
	top.add_child(top_collision)

	obstacles.append(top)

	# Bottom obstacle
	var bottom = Area2D.new()
	bottom.position = Vector2(1380, gap_center + current_parameters.gap_size / 2)
	add_child(bottom)

	var bottom_height = 720 - (gap_center + current_parameters.gap_size / 2)
	var bottom_visual = ColorRect.new()
	bottom_visual.size = Vector2(50, bottom_height)
	bottom_visual.position = Vector2(-25, 0)
	bottom_visual.color = Color.RED
	bottom.add_child(bottom_visual)

	var bottom_collision = CollisionShape2D.new()
	var bottom_shape = RectangleShape2D.new()
	bottom_shape.size = Vector2(50, bottom_height)
	bottom_collision.shape = bottom_shape
	bottom_collision.position = Vector2(0, bottom_height / 2)
	bottom.add_child(bottom_collision)

	obstacles.append(bottom)

func _on_hit_obstacle(_area: Area2D) -> void:
	if is_active and not has_completed:
		_lose_game()
