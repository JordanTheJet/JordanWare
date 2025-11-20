extends GdUnitTestSuite

## Comprehensive tests for Click Circle Microgame
## Tests circle creation, shrinking behavior, click detection, and difficulty scaling

const ClickCircle = preload("res://scripts/microgames/click_circle.gd")

var microgame: Node2D

func before_test() -> void:
	# Create instance
	microgame = auto_free(ClickCircle.new())
	add_child(microgame)

	# Wait for ready
	await await_signal_on(microgame.get_tree(), "process_frame", [], 1000)


func after_test() -> void:
	# Cleanup handled by auto_free
	pass


func test_microgame_metadata() -> void:
	# VERIFY: Metadata is correct
	assert_str(microgame.microgame_id).is_equal("click_circle")
	assert_str(microgame.microgame_name).is_equal("Click the Circle")
	assert_str(microgame.instructions).is_equal("CLICK THE CIRCLE!")


func test_has_all_difficulty_tiers() -> void:
	# VERIFY: All 4 tiers configured
	assert_array(microgame.difficulty_tiers).has_size(4)

	# VERIFY: Each tier has required parameters
	for tier_config in microgame.difficulty_tiers:
		assert_dict(tier_config).contains_keys(["tier", "time_limit", "parameters"])
		assert_dict(tier_config["parameters"]).contains_keys(["initial_size", "shrink_rate"])


func test_circle_is_created() -> void:
	# VERIFY: Circle node exists
	assert_object(microgame.circle).is_not_null()


func test_circle_has_collision_shape() -> void:
	# VERIFY: Circle has CollisionShape2D child
	var collision = microgame.circle.get_child(0)
	assert_bool(collision is CollisionShape2D).is_true()
	assert_bool(collision.shape is CircleShape2D).is_true()


func test_circle_has_sprite() -> void:
	# VERIFY: Circle has Sprite2D child
	var sprite = microgame.circle.get_child(1)
	assert_bool(sprite is Sprite2D).is_true()
	assert_object(sprite.texture).is_not_null()


func test_circle_positioned_at_screen_center() -> void:
	# VERIFY: Circle is centered
	assert_that(microgame.circle.position).is_equal(Vector2(640, 360))


func test_tier_1_configuration() -> void:
	# EXECUTE: Start at tier 1
	microgame.start_game(1)

	# VERIFY: Tier 1 parameters applied
	assert_float(microgame.time_limit).is_equal(4.0)
	assert_float(microgame.circle_size).is_equal(120.0)
	assert_float(microgame.shrink_rate).is_equal(20.0)


func test_tier_2_configuration() -> void:
	# EXECUTE: Start at tier 2
	microgame.start_game(2)

	# VERIFY: Tier 2 parameters applied
	assert_float(microgame.time_limit).is_equal(3.5)
	assert_float(microgame.circle_size).is_equal(90.0)
	assert_float(microgame.shrink_rate).is_equal(30.0)


func test_tier_3_configuration() -> void:
	# EXECUTE: Start at tier 3
	microgame.start_game(3)

	# VERIFY: Tier 3 parameters applied
	assert_float(microgame.time_limit).is_equal(3.0)
	assert_float(microgame.circle_size).is_equal(60.0)
	assert_float(microgame.shrink_rate).is_equal(50.0)


func test_tier_4_configuration() -> void:
	# EXECUTE: Start at tier 4
	microgame.start_game(4)

	# VERIFY: Tier 4 parameters applied
	assert_float(microgame.time_limit).is_equal(2.5)
	assert_float(microgame.circle_size).is_equal(40.0)
	assert_float(microgame.shrink_rate).is_equal(80.0)


func test_circle_shrinks_over_time() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	var initial_size = microgame.circle_size

	# EXECUTE: Process time
	microgame._process(1.0)

	# VERIFY: Circle shrank
	assert_float(microgame.circle_size).is_less(initial_size)
	assert_float(microgame.circle_size).is_equal_approx(100.0, 0.1)


func test_circle_size_has_minimum() -> void:
	# SETUP: Start game with very small circle
	microgame.start_game(1)
	microgame.circle_size = 15.0

	# EXECUTE: Shrink past minimum
	microgame._process(1.0)

	# VERIFY: Size doesn't go below minimum
	assert_float(microgame.circle_size).is_greater_equal(10.0)


func test_click_detection_wins_game() -> void:
	# SETUP: Start game
	microgame.start_game(1)

	# Setup signal monitor
	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Simulate click
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	microgame._on_circle_input_event(null, event, 0)

	# VERIFY: Game won
	await assert_signal(signal_monitor).is_emitted("game_won")
	assert_bool(microgame.has_clicked).is_true()


func test_clicking_while_inactive_does_nothing() -> void:
	# SETUP: Don't start game
	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Try to click
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	microgame._on_circle_input_event(null, event, 0)

	# VERIFY: Nothing happens
	await assert_signal(signal_monitor).is_not_emitted("game_won")


func test_multiple_clicks_only_register_once() -> void:
	# SETUP: Start game and click once
	microgame.start_game(1)
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	microgame._on_circle_input_event(null, event, 0)

	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Click again
	microgame._on_circle_input_event(null, event, 0)

	# VERIFY: Second click ignored
	await assert_signal(signal_monitor).is_not_emitted("game_won")


func test_circle_stops_shrinking_after_click() -> void:
	# SETUP: Start game and click
	microgame.start_game(1)
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	microgame._on_circle_input_event(null, event, 0)

	var size_after_click = microgame.circle_size

	# EXECUTE: Process more time
	microgame._process(1.0)

	# VERIFY: Size unchanged (because has_clicked is true)
	assert_float(microgame.circle_size).is_equal(size_after_click)


func test_difficulty_scaling_makes_game_harder() -> void:
	# Compare tier 1 vs tier 4 difficulty

	# Tier 1
	microgame.start_game(1)
	var t1_time = microgame.time_limit
	var t1_size = microgame.circle_size
	var t1_shrink = microgame.shrink_rate

	# Tier 4
	microgame.start_game(4)
	var t4_time = microgame.time_limit
	var t4_size = microgame.circle_size
	var t4_shrink = microgame.shrink_rate

	# VERIFY: Tier 4 is harder
	assert_float(t4_time).is_less(t1_time)  # Less time
	assert_float(t4_size).is_less(t1_size)  # Smaller circle
	assert_float(t4_shrink).is_greater(t1_shrink)  # Faster shrinking


func test_collision_shape_size_matches_circle_size() -> void:
	# SETUP: Start game
	microgame.start_game(1)

	# Get collision shape
	var collision = microgame.circle.get_child(0) as CollisionShape2D
	var shape = collision.shape as CircleShape2D

	# VERIFY: Radius is half the circle size
	assert_float(shape.radius).is_equal_approx(microgame.circle_size / 2.0, 0.1)


func test_sprite_scale_matches_circle_size() -> void:
	# SETUP: Start game
	microgame.start_game(1)

	# Get sprite
	var sprite = microgame.circle.get_child(1) as Sprite2D

	# VERIFY: Sprite scale is proportional to circle size
	var expected_scale = microgame.circle_size / 128.0
	assert_float(sprite.scale.x).is_equal_approx(expected_scale, 0.01)
	assert_float(sprite.scale.y).is_equal_approx(expected_scale, 0.01)


func test_right_mouse_button_does_not_trigger_win() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Right click
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	microgame._on_circle_input_event(null, event, 0)

	# VERIFY: Not won
	await assert_signal(signal_monitor).is_not_emitted("game_won")


func test_mouse_release_does_not_trigger_win() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Mouse release (not pressed)
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	microgame._on_circle_input_event(null, event, 0)

	# VERIFY: Not won
	await assert_signal(signal_monitor).is_not_emitted("game_won")
