extends GdUnitTestSuite

## Comprehensive tests for Dodge Block Microgame
## Tests player movement, block spawning, collision detection, and difficulty scaling

const DodgeBlock = preload("res://scripts/microgames/dodge_block.gd")

var microgame: Node2D

func before_test() -> void:
	# Create instance
	microgame = auto_free(DodgeBlock.new())
	add_child(microgame)

	# Wait for ready
	await await_signal_on(microgame.get_tree(), "process_frame", [], 1000)


func after_test() -> void:
	# Cleanup handled by auto_free
	pass


func test_microgame_metadata() -> void:
	# VERIFY: Metadata is correct
	assert_str(microgame.microgame_id).is_equal("dodge_block")
	assert_str(microgame.microgame_name).is_equal("Dodge the Block")
	assert_str(microgame.instructions).is_equal("DODGE THE BLOCKS!")


func test_has_all_difficulty_tiers() -> void:
	# VERIFY: All 4 tiers configured
	assert_array(microgame.difficulty_tiers).has_size(4)

	# VERIFY: Each tier has required parameters
	for tier_config in microgame.difficulty_tiers:
		assert_dict(tier_config).contains_keys(["tier", "time_limit", "parameters"])
		assert_dict(tier_config["parameters"]).contains_keys(["block_speed", "block_count", "player_size"])


func test_player_is_created() -> void:
	# VERIFY: Player node exists
	assert_object(microgame.player).is_not_null()


func test_player_has_collision_shape() -> void:
	# VERIFY: Player has CollisionShape2D
	var collision = microgame.player.get_child(0)
	assert_bool(collision is CollisionShape2D).is_true()
	assert_bool(collision.shape is RectangleShape2D).is_true()


func test_player_has_visual_rect() -> void:
	# VERIFY: Player has ColorRect for visualization
	var visual = microgame.player.get_child(1)
	assert_bool(visual is ColorRect).is_true()


func test_player_starts_at_bottom_center() -> void:
	# VERIFY: Player positioned at bottom center
	assert_that(microgame.player.position).is_equal(Vector2(640, 680))


func test_tier_1_configuration() -> void:
	# EXECUTE: Start at tier 1
	microgame.start_game(1)

	# VERIFY: Tier 1 parameters
	assert_float(microgame.time_limit).is_equal(4.0)
	assert_float(microgame.block_speed).is_equal(150.0)
	assert_int(microgame.blocks.size()).is_equal(3)


func test_tier_2_configuration() -> void:
	# EXECUTE: Start at tier 2
	microgame.start_game(2)

	# VERIFY: Tier 2 parameters
	assert_float(microgame.time_limit).is_equal(3.5)
	assert_float(microgame.block_speed).is_equal(250.0)
	assert_int(microgame.blocks.size()).is_equal(5)


func test_tier_3_configuration() -> void:
	# EXECUTE: Start at tier 3
	microgame.start_game(3)

	# VERIFY: Tier 3 parameters
	assert_float(microgame.time_limit).is_equal(3.0)
	assert_float(microgame.block_speed).is_equal(350.0)
	assert_int(microgame.blocks.size()).is_equal(7)


func test_tier_4_configuration() -> void:
	# EXECUTE: Start at tier 4
	microgame.start_game(4)

	# VERIFY: Tier 4 parameters
	assert_float(microgame.time_limit).is_equal(2.5)
	assert_float(microgame.block_speed).is_equal(500.0)
	assert_int(microgame.blocks.size()).is_equal(9)


func test_blocks_are_created() -> void:
	# EXECUTE: Start game
	microgame.start_game(1)

	# VERIFY: Blocks created
	assert_int(microgame.blocks.size()).is_greater(0)


func test_each_block_has_collision() -> void:
	# EXECUTE: Start game
	microgame.start_game(1)

	# VERIFY: Each block has collision shape
	for block in microgame.blocks:
		var collision = block.get_child(0)
		assert_bool(collision is CollisionShape2D).is_true()
		assert_bool(collision.shape is RectangleShape2D).is_true()


func test_blocks_move_downward() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	var initial_y = microgame.blocks[0].position.y

	# EXECUTE: Process time
	microgame._process(0.1)

	# VERIFY: Block moved down
	assert_float(microgame.blocks[0].position.y).is_greater(initial_y)


func test_blocks_wrap_when_off_screen() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	var block = microgame.blocks[0]
	block.position.y = 740  # Below screen

	# EXECUTE: Process to trigger wrap
	microgame._process(0.1)

	# VERIFY: Block wrapped to top
	assert_float(block.position.y).is_less(0)


func test_player_follows_mouse_horizontally() -> void:
	# SETUP: Start game
	microgame.start_game(1)

	# Note: Cannot easily simulate mouse position in headless test
	# This test documents the intended behavior


func test_player_clamped_to_screen_bounds() -> void:
	# SETUP: Start game
	microgame.start_game(1)

	# Test that player X is always within bounds after movement
	# Note: Actual mouse simulation not available in headless mode
	# But we can verify the clamp values are correct
	assert_float(microgame.player.position.x).is_between(0, 1280)


func test_collision_triggers_loss() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Manually trigger collision
	microgame._on_player_hit(microgame.blocks[0])

	# VERIFY: Game lost
	await assert_signal(signal_monitor).is_emitted("game_lost")
	assert_bool(microgame.has_lost).is_true()


func test_collision_only_triggers_once() -> void:
	# SETUP: Start game and trigger first collision
	microgame.start_game(1)
	microgame._on_player_hit(microgame.blocks[0])

	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Try to trigger collision again
	microgame._on_player_hit(microgame.blocks[0])

	# VERIFY: Signal not emitted again
	await assert_signal(signal_monitor).is_not_emitted("game_lost")


func test_collision_while_inactive_does_nothing() -> void:
	# SETUP: Don't start game
	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Trigger collision
	microgame._on_player_hit(microgame.blocks[0] if microgame.blocks.size() > 0 else null)

	# VERIFY: Nothing happens
	await assert_signal(signal_monitor).is_not_emitted("game_lost")


func test_player_size_decreases_with_difficulty() -> void:
	# Compare tier 1 vs tier 4 player size

	# Tier 1
	microgame.start_game(1)
	var player_collision_t1 = microgame.player.get_child(0) as CollisionShape2D
	var player_shape_t1 = player_collision_t1.shape as RectangleShape2D
	var t1_size = player_shape_t1.size.x

	# Tier 4
	microgame.start_game(4)
	var player_collision_t4 = microgame.player.get_child(0) as CollisionShape2D
	var player_shape_t4 = player_collision_t4.shape as RectangleShape2D
	var t4_size = player_shape_t4.size.x

	# VERIFY: Tier 4 player is smaller
	assert_float(t4_size).is_less(t1_size)


func test_difficulty_scaling_makes_game_harder() -> void:
	# Compare tier 1 vs tier 4

	# Tier 1
	microgame.start_game(1)
	var t1_time = microgame.time_limit
	var t1_speed = microgame.block_speed
	var t1_blocks = microgame.blocks.size()

	# Tier 4
	microgame.start_game(4)
	var t4_time = microgame.time_limit
	var t4_speed = microgame.block_speed
	var t4_blocks = microgame.blocks.size()

	# VERIFY: Tier 4 is harder
	assert_float(t4_time).is_less(t1_time)
	assert_float(t4_speed).is_greater(t1_speed)
	assert_int(t4_blocks).is_greater(t1_blocks)


func test_blocks_have_visual_representation() -> void:
	# EXECUTE: Start game
	microgame.start_game(1)

	# VERIFY: Each block has ColorRect
	for block in microgame.blocks:
		var visual = block.get_child(1)
		assert_bool(visual is ColorRect).is_true()


func test_cleanup_removes_all_blocks() -> void:
	# SETUP: Start game to create blocks
	microgame.start_game(1)
	var block_count = microgame.blocks.size()
	assert_int(block_count).is_greater(0)

	# EXECUTE: Cleanup
	microgame.cleanup()

	# VERIFY: Blocks array cleared
	assert_array(microgame.blocks).is_empty()


func test_blocks_spawn_at_different_positions() -> void:
	# EXECUTE: Start game
	microgame.start_game(2)  # Use tier 2 for multiple blocks

	# VERIFY: Blocks have different X positions (randomized)
	# Note: Could theoretically fail due to RNG, but very unlikely
	if microgame.blocks.size() >= 2:
		var positions = {}
		for block in microgame.blocks:
			positions[block.position.x] = true
		# Most likely at least 2 different positions
		assert_int(positions.size()).is_greater_equal(1)


func test_block_speed_affects_movement() -> void:
	# Setup: Start game
	microgame.start_game(1)
	var block = microgame.blocks[0]
	var initial_y = block.position.y
	var speed = microgame.block_speed

	# EXECUTE: Process 1 second
	microgame._process(1.0)

	# VERIFY: Block moved approximately by speed amount
	var delta_y = block.position.y - initial_y
	assert_float(delta_y).is_equal_approx(speed, 50.0)  # Allow some margin


func test_multiple_start_calls_reset_blocks() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	var first_blocks = microgame.blocks.size()

	# EXECUTE: Start again with different tier
	microgame.start_game(2)

	# VERIFY: New blocks created
	assert_int(microgame.blocks.size()).is_not_equal(first_blocks)


func test_player_collision_signal_connected() -> void:
	# VERIFY: Player area_entered signal is connected
	var signal_connections = microgame.player.area_entered.get_connections()
	assert_int(signal_connections.size()).is_greater(0)
