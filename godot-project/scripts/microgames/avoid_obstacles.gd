extends MicrogameBase

## Avoid Obstacles - Move to avoid

var player: ColorRect
var player_x: float = 640.0
var player_speed: float = 400.0
var obstacles: Array[ColorRect] = []
var spawn_timer: float = 0.0
var spawn_interval: float = 0.5
var obstacle_speed: float = 200.0
var has_hit: bool = false


func _define_difficulty_tiers() -> void:
	microgame_id = "avoid_obstacles"
	microgame_name = "Avoid Obstacles"
	instructions = "DODGE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 5.0,
			"parameters": {
				"obstacle_speed": 200.0,
				"spawn_interval": 0.8
			}
		},
		{
			"tier": 2,
			"time_limit": 5.0,
			"parameters": {
				"obstacle_speed": 300.0,
				"spawn_interval": 0.6
			}
		},
		{
			"tier": 3,
			"time_limit": 5.0,
			"parameters": {
				"obstacle_speed": 400.0,
				"spawn_interval": 0.5
			}
		},
		{
			"tier": 4,
			"time_limit": 6.0,
			"parameters": {
				"obstacle_speed": 500.0,
				"spawn_interval": 0.4
			}
		}
	]


func _setup_game() -> void:
	# Create player
	player = ColorRect.new()
	player.color = Color.CYAN
	player.size = Vector2(40, 40)
	player.position = Vector2(player_x - 20, 650)
	add_child(player)

	# Create instruction
	var instruction = Label.new()
	instruction.text = "DODGE!"
	instruction.position = Vector2(560, 50)
	instruction.add_theme_font_size_override("font_size", 48)
	add_child(instruction)


func _on_game_start() -> void:
	has_hit = false
	player_x = 640.0
	obstacles.clear()
	spawn_timer = 0.0
	obstacle_speed = current_parameters.obstacle_speed
	spawn_interval = current_parameters.spawn_interval


# Override _process to make timeout = win (survival game)
func _process(delta: float) -> void:
	if not is_active or has_completed:
		return

	# Update timer
	time_remaining -= delta

	# Win if survived without getting hit
	if time_remaining <= 0:
		_win_game()
		return

	# Update game-specific logic
	_update_game(delta)


func _update_game(delta: float) -> void:
	if has_hit:
		return

	# Handle player input
	var move_dir = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_dir = -1.0
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_dir = 1.0

	# Move player
	player_x += move_dir * player_speed * delta
	player_x = clampf(player_x, 50, 1230)

	if player:
		player.position.x = player_x - 20

	# Spawn obstacles
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_obstacle()

	# Update obstacles
	for obstacle in obstacles:
		obstacle.position.y += obstacle_speed * delta

		# Check collision with player
		if not has_hit and _check_collision(player, obstacle):
			has_hit = true
			if player:
				player.color = Color.RED
			_lose_game()
			return

		# Remove if off screen
		if obstacle.position.y > 800:
			obstacle.queue_free()
			obstacles.erase(obstacle)


func _spawn_obstacle() -> void:
	var obstacle = ColorRect.new()
	obstacle.color = Color.RED
	obstacle.size = Vector2(40, 40)
	obstacle.position = Vector2(randf_range(50, 1230), -50)
	obstacles.append(obstacle)
	add_child(obstacle)


func _check_collision(rect1: ColorRect, rect2: ColorRect) -> bool:
	var r1 = Rect2(rect1.position, rect1.size)
	var r2 = Rect2(rect2.position, rect2.size)
	return r1.intersects(r2)


func cleanup() -> void:
	for obstacle in obstacles:
		if is_instance_valid(obstacle):
			obstacle.queue_free()
	obstacles.clear()
	super.cleanup()
