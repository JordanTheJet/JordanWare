extends MicrogameBase

## Dodge the Block Microgame
## Objective: Dodge falling blocks by moving the mouse
## Difficulty: More blocks, faster speed, smaller player at higher tiers

var player: Area2D
var blocks: Array[Area2D] = []
var player_x: float = 640.0
var block_speed: float = 0.0
var has_lost: bool = false


func _define_difficulty_tiers() -> void:
	microgame_id = "dodge_block"
	microgame_name = "Dodge the Block"
	instructions = "DODGE THE BLOCKS!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"block_speed": 150.0,
				"block_count": 3,
				"player_size": 40.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"block_speed": 250.0,
				"block_count": 5,
				"player_size": 35.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"block_speed": 350.0,
				"block_count": 7,
				"player_size": 30.0
			}
		},
		{
			"tier": 4,
			"time_limit": 2.5,
			"parameters": {
				"block_speed": 500.0,
				"block_count": 9,
				"player_size": 25.0
			}
		}
	]


func _setup_game() -> void:
	# Create player
	player = Area2D.new()
	player.position = Vector2(640, 680)

	var player_collision = CollisionShape2D.new()
	var player_shape = RectangleShape2D.new()
	player_collision.shape = player_shape
	player.add_child(player_collision)

	var player_sprite = ColorRect.new()
	player_sprite.color = Color.DODGER_BLUE
	player_sprite.position = Vector2(-20, -20)
	player_sprite.size = Vector2(40, 40)
	player.add_child(player_sprite)

	# Connect collision signal
	player.area_entered.connect(_on_player_hit)

	add_child(player)


func _on_game_start() -> void:
	has_lost = false
	block_speed = current_parameters.block_speed
	player_x = 640.0

	# Update player size
	var player_size = current_parameters.player_size
	var player_collision = player.get_child(0) as CollisionShape2D
	var player_shape = player_collision.shape as RectangleShape2D
	player_shape.size = Vector2(player_size, player_size)

	var player_sprite = player.get_child(1) as ColorRect
	player_sprite.position = Vector2(-player_size / 2, -player_size / 2)
	player_sprite.size = Vector2(player_size, player_size)

	# Create blocks
	var block_count = current_parameters.block_count
	for i in range(block_count):
		_create_block(i * (500.0 / block_count))


func _update_game(delta: float) -> void:
	if has_lost:
		return

	# Move player to mouse
	var mouse_pos = get_viewport().get_mouse_position()
	player_x = clampf(mouse_pos.x, 20, 1260)
	player.position.x = player_x

	# Move blocks
	for block in blocks:
		block.position.y += block_speed * delta

		# Reset if off screen
		if block.position.y > 750:
			block.position.y = -50
			block.position.x = randf_range(30, 1250)


func _create_block(y_offset: float) -> void:
	var block = Area2D.new()
	block.position = Vector2(randf_range(30, 1250), -50 - y_offset)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 40)
	collision.shape = shape
	block.add_child(collision)

	var sprite = ColorRect.new()
	sprite.color = Color.CRIMSON
	sprite.position = Vector2(-20, -20)
	sprite.size = Vector2(40, 40)
	block.add_child(sprite)

	blocks.append(block)
	add_child(block)


func _on_player_hit(_area: Area2D) -> void:
	if not has_lost and is_active:
		has_lost = true
		_lose_game()


func cleanup() -> void:
	for block in blocks:
		block.queue_free()
	blocks.clear()
	super.cleanup()
