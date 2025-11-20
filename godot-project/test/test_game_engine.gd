extends GdUnitTestSuite

## Comprehensive tests for GameEngine
## Tests game state management, difficulty progression, lifecycle, and win/loss mechanics

const GameEngine = preload("res://scripts/game_engine.gd")

var game_engine: Node
var mock_microgame_manager: Node
var mock_microgame_container: Node2D
var mock_ui_layer: CanvasLayer

func before_test() -> void:
	# Create game engine instance
	game_engine = auto_free(GameEngine.new())

	# Create mock dependencies
	mock_microgame_manager = auto_free(Node.new())
	mock_microgame_manager.name = "MicrogameManager"
	mock_microgame_manager.set_script(preload("res://scripts/microgame_manager.gd"))

	mock_microgame_container = auto_free(Node2D.new())
	mock_microgame_container.name = "MicrogameContainer"

	mock_ui_layer = auto_free(CanvasLayer.new())
	mock_ui_layer.name = "UILayer"

	# Add children to game engine
	game_engine.add_child(mock_microgame_manager)
	game_engine.add_child(mock_microgame_container)
	game_engine.add_child(mock_ui_layer)

	# Add to scene tree for proper initialization
	add_child(game_engine)


func after_test() -> void:
	# Cleanup is handled by auto_free
	pass


func test_initial_state() -> void:
	# VERIFY: Game starts in TITLE state with correct initial values
	assert_int(game_engine.current_state).is_equal(GameEngine.GameState.TITLE)
	assert_int(game_engine.score).is_equal(0)
	assert_int(game_engine.lives).is_equal(GameEngine.STARTING_LIVES)
	assert_int(game_engine.difficulty_tier).is_equal(1)
	assert_int(game_engine.consecutive_wins).is_equal(0)
	assert_object(game_engine.current_microgame).is_null()


func test_start_game_resets_state() -> void:
	# SETUP: Modify game state
	game_engine.score = 10
	game_engine.lives = 1
	game_engine.difficulty_tier = 3
	game_engine.consecutive_wins = 5

	# EXECUTE: Start new game
	game_engine.start_game()

	# VERIFY: All state is reset to initial values
	assert_int(game_engine.score).is_equal(0)
	assert_int(game_engine.lives).is_equal(GameEngine.STARTING_LIVES)
	assert_int(game_engine.difficulty_tier).is_equal(1)
	assert_int(game_engine.consecutive_wins).is_equal(0)


func test_difficulty_increases_after_5_consecutive_wins() -> void:
	# SETUP: Set up game state
	game_engine.difficulty_tier = 1
	game_engine.consecutive_wins = 4
	game_engine.score = 1

	# EXECUTE: Trigger difficulty check with 5th consecutive win
	game_engine.consecutive_wins = 5
	game_engine._check_difficulty_increase()

	# VERIFY: Difficulty increased and consecutive wins reset
	assert_int(game_engine.difficulty_tier).is_equal(2)
	assert_int(game_engine.consecutive_wins).is_equal(0)


func test_difficulty_increases_at_score_milestones() -> void:
	# SETUP: Score just before milestone
	game_engine.difficulty_tier = 1
	game_engine.score = 9
	game_engine.consecutive_wins = 0

	# EXECUTE: Reach score milestone (multiple of 10)
	game_engine.score = 10
	game_engine._check_difficulty_increase()

	# VERIFY: Difficulty increased
	assert_int(game_engine.difficulty_tier).is_equal(2)


func test_difficulty_caps_at_tier_4() -> void:
	# SETUP: Already at max difficulty
	game_engine.difficulty_tier = 4
	game_engine.consecutive_wins = 5

	# EXECUTE: Try to increase difficulty
	game_engine._check_difficulty_increase()

	# VERIFY: Difficulty stays at max tier
	assert_int(game_engine.difficulty_tier).is_equal(4)


func test_consecutive_wins_resets_on_loss() -> void:
	# SETUP: Player has consecutive wins
	game_engine.consecutive_wins = 4
	game_engine.lives = 3
	game_engine.current_state = GameEngine.GameState.PLAYING

	# EXECUTE: Simulate a loss
	game_engine._on_microgame_lost()

	# VERIFY: Consecutive wins reset, lives decremented
	assert_int(game_engine.consecutive_wins).is_equal(0)
	assert_int(game_engine.lives).is_equal(2)


func test_game_over_when_lives_reach_zero() -> void:
	# SETUP: Player has 1 life remaining
	game_engine.lives = 1
	game_engine.current_state = GameEngine.GameState.PLAYING

	# EXECUTE: Lose last life (need to await the timer)
	game_engine._on_microgame_lost()

	# Wait for the async timer in _on_microgame_lost
	await await_signal_on(game_engine.get_tree(), "process_frame", [], 1000)

	# VERIFY: Lives are zero and state is GAME_OVER
	assert_int(game_engine.lives).is_equal(0)


func test_score_increments_on_win() -> void:
	# SETUP: Initial score
	game_engine.score = 5
	game_engine.consecutive_wins = 2
	game_engine.current_state = GameEngine.GameState.PLAYING

	# EXECUTE: Win a microgame
	game_engine._on_microgame_won()

	# VERIFY: Score and consecutive wins incremented
	assert_int(game_engine.score).is_equal(6)
	assert_int(game_engine.consecutive_wins).is_equal(3)


func test_state_transitions_are_valid() -> void:
	# Test TITLE -> PLAYING transition
	game_engine._change_state(GameEngine.GameState.TITLE)
	assert_int(game_engine.current_state).is_equal(GameEngine.GameState.TITLE)

	# Test TRANSITION state
	game_engine._change_state(GameEngine.GameState.TRANSITION)
	assert_int(game_engine.current_state).is_equal(GameEngine.GameState.TRANSITION)

	# Test PLAYING state
	game_engine._change_state(GameEngine.GameState.PLAYING)
	assert_int(game_engine.current_state).is_equal(GameEngine.GameState.PLAYING)

	# Test GAME_OVER state
	game_engine._change_state(GameEngine.GameState.GAME_OVER)
	assert_int(game_engine.current_state).is_equal(GameEngine.GameState.GAME_OVER)


func test_transition_timer_countdown() -> void:
	# SETUP: Set transition state with timer
	game_engine.current_state = GameEngine.GameState.TRANSITION
	game_engine.transition_timer = 2.0

	# EXECUTE: Process some time
	game_engine._process(0.5)

	# VERIFY: Timer decreased
	assert_float(game_engine.transition_timer).is_equal_approx(1.5, 0.01)


func test_multiple_difficulty_increases() -> void:
	# SETUP: Test multiple tier increases
	game_engine.difficulty_tier = 1
	game_engine.score = 0
	game_engine.consecutive_wins = 0

	# EXECUTE: Win 5 times (tier 1 -> 2)
	for i in range(5):
		game_engine.consecutive_wins += 1
	game_engine._check_difficulty_increase()
	assert_int(game_engine.difficulty_tier).is_equal(2)

	# Score milestone (tier 2 -> 3)
	game_engine.score = 10
	game_engine._check_difficulty_increase()
	assert_int(game_engine.difficulty_tier).is_equal(3)

	# Another 5 wins (tier 3 -> 4)
	game_engine.consecutive_wins = 5
	game_engine.score = 11
	game_engine._check_difficulty_increase()
	assert_int(game_engine.difficulty_tier).is_equal(4)

	# Verify cannot exceed tier 4
	game_engine.consecutive_wins = 5
	game_engine._check_difficulty_increase()
	assert_int(game_engine.difficulty_tier).is_equal(4)


func test_constants_are_correct() -> void:
	# VERIFY: Game constants match specification
	assert_int(GameEngine.STARTING_LIVES).is_equal(3)
	assert_float(GameEngine.TRANSITION_DURATION).is_equal(2.0)
	assert_int(GameEngine.WINS_PER_TIER_INCREASE).is_equal(5)
	assert_int(GameEngine.SCORE_MILESTONE_INTERVAL).is_equal(10)


func test_cleanup_removes_current_microgame() -> void:
	# SETUP: Create a mock microgame
	var mock_microgame = auto_free(Node2D.new())
	mock_microgame.set_script(preload("res://scripts/microgame_base.gd"))
	game_engine.current_microgame = mock_microgame

	# EXECUTE: Cleanup
	game_engine._cleanup_current_microgame()

	# VERIFY: Current microgame is null
	assert_object(game_engine.current_microgame).is_null()
