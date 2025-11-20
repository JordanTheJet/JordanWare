extends GdUnitTestSuite

## Comprehensive tests for MicrogameBase lifecycle
## Tests game initialization, state management, timer, win/loss conditions

# Create a test microgame for testing the base class
class TestMicrogame extends MicrogameBase:
	var setup_called: bool = false
	var start_called: bool = false
	var update_call_count: int = 0

	func _define_difficulty_tiers() -> void:
		microgame_id = "test_game"
		microgame_name = "Test Game"
		instructions = "TEST INSTRUCTION"

		difficulty_tiers = [
			{
				"tier": 1,
				"time_limit": 5.0,
				"parameters": {"test_param": 10}
			},
			{
				"tier": 2,
				"time_limit": 4.0,
				"parameters": {"test_param": 20}
			},
			{
				"tier": 3,
				"time_limit": 3.0,
				"parameters": {"test_param": 30}
			},
			{
				"tier": 4,
				"time_limit": 2.0,
				"parameters": {"test_param": 40}
			}
		]

	func _setup_game() -> void:
		setup_called = true

	func _on_game_start() -> void:
		start_called = true

	func _update_game(_delta: float) -> void:
		update_call_count += 1


var microgame: TestMicrogame

func before_test() -> void:
	# Create test microgame instance
	microgame = auto_free(TestMicrogame.new())
	add_child(microgame)


func after_test() -> void:
	# Cleanup handled by auto_free
	pass


func test_microgame_initializes_metadata() -> void:
	# VERIFY: Metadata is set correctly
	assert_str(microgame.microgame_id).is_equal("test_game")
	assert_str(microgame.microgame_name).is_equal("Test Game")
	assert_str(microgame.instructions).is_equal("TEST INSTRUCTION")


func test_setup_game_is_called_on_ready() -> void:
	# Wait for _ready
	await await_signal_on(microgame.get_tree(), "process_frame", [], 1000)

	# VERIFY: Setup was called
	assert_bool(microgame.setup_called).is_true()


func test_initial_state_is_inactive() -> void:
	# VERIFY: Game starts inactive
	assert_bool(microgame.is_active).is_false()
	assert_bool(microgame.has_completed).is_false()


func test_start_game_activates_microgame() -> void:
	# EXECUTE: Start game at tier 1
	microgame.start_game(1)

	# VERIFY: Game is now active
	assert_bool(microgame.is_active).is_true()
	assert_bool(microgame.has_completed).is_false()
	assert_bool(microgame.start_called).is_true()


func test_start_game_loads_correct_tier_config() -> void:
	# EXECUTE: Start at tier 2
	microgame.start_game(2)

	# VERIFY: Tier 2 parameters loaded
	assert_float(microgame.time_limit).is_equal(4.0)
	assert_float(microgame.time_remaining).is_equal(4.0)
	assert_int(microgame.current_parameters["test_param"]).is_equal(20)


func test_timer_counts_down_during_process() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	var initial_time = microgame.time_remaining

	# EXECUTE: Process some time
	microgame._process(1.0)

	# VERIFY: Time decreased
	assert_float(microgame.time_remaining).is_less(initial_time)
	assert_float(microgame.time_remaining).is_equal_approx(4.0, 0.01)


func test_timeout_triggers_loss() -> void:
	# SETUP: Start game with very short time
	microgame.start_game(1)
	microgame.time_remaining = 0.1

	# Setup signal monitor
	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Process past timeout
	microgame._process(0.2)

	# VERIFY: Loss signal emitted
	assert_signal(signal_monitor).is_emitted("game_lost")
	assert_bool(microgame.has_completed).is_true()
	assert_bool(microgame.is_active).is_false()


func test_win_game_emits_signal() -> void:
	# SETUP: Start game
	microgame.start_game(1)

	# Setup signal monitor
	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Trigger win
	microgame._win_game()

	# VERIFY: Win signal emitted
	await assert_signal(signal_monitor).is_emitted("game_won")
	assert_bool(microgame.has_completed).is_true()
	assert_bool(microgame.is_active).is_false()


func test_lose_game_emits_signal() -> void:
	# SETUP: Start game
	microgame.start_game(1)

	# Setup signal monitor
	var signal_monitor = monitor_signals(microgame)

	# EXECUTE: Trigger loss
	microgame._lose_game()

	# VERIFY: Loss signal emitted
	await assert_signal(signal_monitor).is_emitted("game_lost")
	assert_bool(microgame.has_completed).is_true()
	assert_bool(microgame.is_active).is_false()


func test_update_game_called_during_process() -> void:
	# SETUP: Start game
	microgame.start_game(1)
	microgame.update_call_count = 0

	# EXECUTE: Process multiple frames
	microgame._process(0.016)
	microgame._process(0.016)

	# VERIFY: Update was called
	assert_int(microgame.update_call_count).is_equal(2)


func test_update_not_called_when_inactive() -> void:
	# SETUP: Don't start game
	microgame.update_call_count = 0

	# EXECUTE: Process
	microgame._process(0.016)

	# VERIFY: Update not called
	assert_int(microgame.update_call_count).is_equal(0)


func test_update_not_called_after_completion() -> void:
	# SETUP: Start and complete game
	microgame.start_game(1)
	microgame._win_game()
	microgame.update_call_count = 0

	# EXECUTE: Process after completion
	microgame._process(0.016)

	# VERIFY: Update not called
	assert_int(microgame.update_call_count).is_equal(0)


func test_get_max_tier_returns_correct_value() -> void:
	# VERIFY: Max tier is 4
	assert_int(microgame.get_max_tier()).is_equal(4)


func test_get_tier_config_returns_correct_tier() -> void:
	# EXECUTE: Get tier 3 config
	var config = microgame._get_tier_config(3)

	# VERIFY: Correct config returned
	assert_dict(config).is_not_empty()
	assert_int(config["tier"]).is_equal(3)
	assert_float(config["time_limit"]).is_equal(3.0)
	assert_int(config["parameters"]["test_param"]).is_equal(30)


func test_get_tier_config_falls_back_to_lower_tier() -> void:
	# SETUP: Microgame only supports up to tier 4
	# EXECUTE: Request tier 5 (doesn't exist)
	var config = microgame._get_tier_config(5)

	# VERIFY: Falls back to highest available (tier 4)
	assert_dict(config).is_not_empty()
	assert_int(config["tier"]).is_equal(4)


func test_cannot_win_twice() -> void:
	# SETUP: Start game and win
	microgame.start_game(1)
	var signal_monitor = monitor_signals(microgame)
	microgame._win_game()

	# EXECUTE: Try to win again
	microgame._win_game()

	# VERIFY: Signal only emitted once
	await assert_signal(signal_monitor).is_emitted("game_won")


func test_cannot_lose_twice() -> void:
	# SETUP: Start game and lose
	microgame.start_game(1)
	var signal_monitor = monitor_signals(microgame)
	microgame._lose_game()

	# EXECUTE: Try to lose again
	microgame._lose_game()

	# VERIFY: Signal only emitted once
	await assert_signal(signal_monitor).is_emitted("game_lost")


func test_cleanup_marks_for_deletion() -> void:
	# EXECUTE: Call cleanup
	microgame.cleanup()

	# VERIFY: Game is inactive
	assert_bool(microgame.is_active).is_false()


func test_all_tiers_have_valid_configs() -> void:
	# VERIFY: All 4 tiers configured
	assert_array(microgame.difficulty_tiers).has_size(4)

	# VERIFY: Each tier has required fields
	for tier_config in microgame.difficulty_tiers:
		assert_dict(tier_config).contains_keys(["tier", "time_limit", "parameters"])
		assert_int(tier_config["tier"]).is_between(1, 4)
		assert_float(tier_config["time_limit"]).is_greater(0.0)


func test_time_remaining_never_goes_negative() -> void:
	# SETUP: Start game with minimal time
	microgame.start_game(1)
	microgame.time_remaining = 0.1

	# EXECUTE: Process way past timeout
	microgame._process(10.0)

	# VERIFY: Time doesn't go negative
	assert_float(microgame.time_remaining).is_less_equal(0.0)


func test_multiple_start_game_calls_reset_state() -> void:
	# SETUP: Start game, then start again
	microgame.start_game(1)
	microgame.time_remaining = 2.0
	microgame.has_completed = true

	# EXECUTE: Start again
	microgame.start_game(2)

	# VERIFY: State is reset
	assert_bool(microgame.has_completed).is_false()
	assert_bool(microgame.is_active).is_true()
	assert_float(microgame.time_remaining).is_equal(4.0)
