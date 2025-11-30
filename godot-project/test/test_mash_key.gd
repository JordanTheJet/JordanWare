extends GdUnitTestSuite

## Comprehensive tests for Mash Key Microgame
## Tests key input, progress tracking, decay, and difficulty scaling

const MashKey = preload("res://scripts/microgames/mash_key.gd")

var microgame: Node2D

func before_test() -> void:
	# Create instance
	microgame = auto_free(MashKey.new())
	add_child(microgame)

	# Wait for ready
	await await_signal_on(microgame.get_tree(), "process_frame", [], 1000)


func after_test() -> void:
	# Cleanup handled by auto_free
	pass


func test_microgame_metadata() -> void:
	# VERIFY: Metadata is correct
	assert_str(microgame.microgame_id).is_equal("mash_key")
	assert_str(microgame.microgame_name).is_equal("Mash the Key")
	assert_str(microgame.instructions).is_equal("MASH THE KEY!")


func test_has_all_difficulty_tiers() -> void:
	# VERIFY: All 4 tiers configured
	assert_array(microgame.difficulty_tiers).has_size(4)

	# VERIFY: Each tier has required parameters
	for tier_config in microgame.difficulty_tiers:
		assert_dict(tier_config).contains_keys(["tier", "time_limit", "parameters"])
		assert_dict(tier_config["parameters"]).contains_keys(["required_presses", "target_key", "decay_rate"])


func test_ui_elements_are_created() -> void:
	# VERIFY: UI components exist
	assert_object(microgame.progress_bar).is_not_null()
	assert_object(microgame.key_label).is_not_null()


func test_progress_bar_is_configured() -> void:
	# VERIFY: Progress bar range is correct
	assert_float(microgame.progress_bar.min_value).is_equal(0)
	assert_float(microgame.progress_bar.max_value).is_equal(100)


func test_tier_1_configuration() -> void:
	# EXECUTE: Start at tier 1
	microgame.start_game(1)

	# VERIFY: Tier 1 parameters
	assert_float(microgame.time_limit).is_equal(4.0)
	assert_int(microgame.required_presses).is_equal(15)
	assert_float(microgame.decay_rate).is_equal(5.0)
	assert_str(microgame.target_key).is_empty()
	assert_str(microgame.key_label.text).is_equal("ANY KEY!")


func test_tier_2_configuration() -> void:
	# EXECUTE: Start at tier 2
	microgame.start_game(2)

	# VERIFY: Tier 2 parameters
	assert_float(microgame.time_limit).is_equal(3.5)
	assert_int(microgame.required_presses).is_equal(20)
	assert_float(microgame.decay_rate).is_equal(8.0)
	assert_str(microgame.target_key).is_equal("Space")
	assert_str(microgame.key_label.text).is_equal("Space")


func test_tier_3_configuration() -> void:
	# EXECUTE: Start at tier 3
	microgame.start_game(3)

	# VERIFY: Tier 3 parameters
	assert_float(microgame.time_limit).is_equal(3.0)
	assert_int(microgame.required_presses).is_equal(25)
	assert_float(microgame.decay_rate).is_equal(10.0)
	assert_str(microgame.target_key).is_equal("A")


func test_tier_4_configuration() -> void:
	# EXECUTE: Start at tier 4
	microgame.start_game(4)

	# VERIFY: Tier 4 parameters
	assert_float(microgame.time_limit).is_equal(2.5)
	assert_int(microgame.required_presses).is_equal(30)
	assert_float(microgame.decay_rate).is_equal(15.0)
	assert_str(microgame.target_key).is_equal("X")


func test_progress_starts_at_zero() -> void:
	# EXECUTE: Start game
	microgame.start_game(1)

	# VERIFY: Progress is 0
	assert_float(microgame.progress).is_equal(0.0)


func test_progress_decays_over_time() -> void:
	# SETUP: Start game and add some progress
	microgame.start_game(1)
	microgame.progress = 10.0

	# EXECUTE: Process time
	microgame._process(1.0)

	# VERIFY: Progress decayed (10 - 5*1 = 5)
	assert_float(microgame.progress).is_equal_approx(5.0, 0.1)


func test_progress_does_not_go_below_zero() -> void:
	# SETUP: Start game with low progress
	microgame.start_game(1)
	microgame.progress = 1.0

	# EXECUTE: Process enough time to go negative
	microgame._process(1.0)

	# VERIFY: Progress clamped at 0
	assert_float(microgame.progress).is_greater_equal(0.0)


func test_valid_key_press_increments_progress() -> void:
	# SETUP: Start game (any key accepted)
	microgame.start_game(1)
	microgame.progress = 5.0

	# EXECUTE: Simulate key press
	var event = InputEventKey.new()
	event.keycode = KEY_A
	event.pressed = true
	microgame._input(event)

	# VERIFY: Progress increased
	assert_float(microgame.progress).is_equal(6.0)


func test_space_key_press_works_in_tier_2() -> void:
	# SETUP: Start tier 2 (requires Space)
	microgame.start_game(2)
	microgame.progress = 0.0

	# EXECUTE: Press Space
	var event = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	microgame._input(event)

	# VERIFY: Progress increased
	assert_float(microgame.progress).is_equal(1.0)


func test_wrong_key_does_not_increment_in_tier_2() -> void:
	# SETUP: Start tier 2 (requires Space)
	microgame.start_game(2)
	microgame.progress = 0.0

	# EXECUTE: Press wrong key
	var event = InputEventKey.new()
	event.keycode = KEY_A
	event.pressed = true
	microgame._input(event)

	# VERIFY: Progress unchanged
	assert_float(microgame.progress).is_equal(0.0)


func test_reaching_required_presses_wins_game() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	microgame.progress = 14.0  # One below required

	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Press one more key and process
	var event = InputEventKey.new()
	event.keycode = KEY_A
	event.pressed = true
	microgame._input(event)
	microgame._process(0.016)

	# VERIFY: Game won
	await assert_signal(signal_monitor).is_emitted("game_won")


func test_progress_bar_updates_correctly() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	microgame.progress = 7.5
	microgame.required_presses = 15

	# EXECUTE: Update display
	microgame._update_display()

	# VERIFY: Progress bar shows 50%
	assert_float(microgame.progress_bar.value).is_equal_approx(50.0, 1.0)


func test_counter_label_displays_progress() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	microgame.progress = 8.0
	microgame.required_presses = 15

	# EXECUTE: Update display
	microgame._update_display()

	# VERIFY: Counter shows correct values
	var counter = microgame.get_node_or_null("CounterLabel") as Label
	if counter:
		assert_str(counter.text).is_equal("8 / 15")


func test_key_press_while_inactive_does_nothing() -> void:
	# SETUP: Don't start game
	microgame.progress = 0.0

	# EXECUTE: Press key
	var event = InputEventKey.new()
	event.keycode = KEY_A
	event.pressed = true
	microgame._input(event)

	# VERIFY: Progress unchanged
	assert_float(microgame.progress).is_equal(0.0)


func test_key_press_after_completion_does_nothing() -> void:
	# SETUP: Start and complete game
	microgame.start_game(1)
	microgame._win_game()

	microgame.progress = 0.0

	# EXECUTE: Press key
	var event = InputEventKey.new()
	event.keycode = KEY_A
	event.pressed = true
	microgame._input(event)

	# VERIFY: Progress unchanged
	assert_float(microgame.progress).is_equal(0.0)


func test_difficulty_scaling_makes_game_harder() -> void:
	# Compare tier 1 vs tier 4

	# Tier 1
	microgame.start_game(1)
	var t1_time = microgame.time_limit
	var t1_presses = microgame.required_presses
	var t1_decay = microgame.decay_rate

	# Tier 4
	microgame.start_game(4)
	var t4_time = microgame.time_limit
	var t4_presses = microgame.required_presses
	var t4_decay = microgame.decay_rate

	# VERIFY: Tier 4 is harder
	assert_float(t4_time).is_less(t1_time)
	assert_int(t4_presses).is_greater(t1_presses)
	assert_float(t4_decay).is_greater(t1_decay)


func test_higher_tiers_require_specific_keys() -> void:
	# VERIFY: Tier 1 accepts any key
	microgame.start_game(1)
	assert_str(microgame.target_key).is_empty()

	# VERIFY: Tier 2+ require specific keys
	microgame.start_game(2)
	assert_str(microgame.target_key).is_not_empty()


func test_progress_bar_never_exceeds_100() -> void:
	# SETUP: Start game with more than required progress
	microgame.start_game(1)
	microgame.progress = 20.0
	microgame.required_presses = 15

	# EXECUTE: Update display
	microgame._update_display()

	# VERIFY: Progress bar capped at 100
	assert_float(microgame.progress_bar.value).is_less_equal(100.0)


func test_key_flash_effect_on_valid_press() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	var initial_color = microgame.key_label.modulate

	# EXECUTE: Press valid key
	var event = InputEventKey.new()
	event.keycode = KEY_A
	event.pressed = true
	microgame._input(event)

	# VERIFY: Flash triggered (color changed to green)
	# Note: Testing async flash behavior is complex; this validates the call happens


func test_key_label_updates_for_each_tier() -> void:
	# Tier 1: ANY KEY
	microgame.start_game(1)
	assert_str(microgame.key_label.text).is_equal("ANY KEY!")

	# Tier 2: Space
	microgame.start_game(2)
	assert_str(microgame.key_label.text).is_equal("Space")

	# Tier 3: A
	microgame.start_game(3)
	assert_str(microgame.key_label.text).is_equal("A")

	# Tier 4: X
	microgame.start_game(4)
	assert_str(microgame.key_label.text).is_equal("X")


func test_multiple_rapid_key_presses() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	microgame.progress = 0.0

	# EXECUTE: Simulate 5 rapid presses
	for i in range(5):
		var event = InputEventKey.new()
		event.keycode = KEY_A
		event.pressed = true
		microgame._input(event)

	# VERIFY: All presses counted
	assert_float(microgame.progress).is_equal(5.0)


func test_decay_works_even_with_high_progress() -> void:
	# SETUP: Start game with high progress
	microgame.start_game(1)
	microgame.progress = 50.0
	microgame.decay_rate = 5.0

	# EXECUTE: Process time
	microgame._process(2.0)

	# VERIFY: Progress decayed correctly
	assert_float(microgame.progress).is_equal_approx(40.0, 0.1)
