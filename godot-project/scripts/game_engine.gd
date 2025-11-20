extends Node

## Main Game Engine
## Manages game state, difficulty progression, and microgame flow
##
## GAME FLOW:
## TITLE -> TRANSITION -> PLAYING -> (repeat) -> GAME_OVER
##
## DIFFICULTY SCALING:
## - Starts at tier 1
## - Increases every 5 consecutive wins OR every 10 score points
## - Max tier is 4
## - Each microgame defines its own tier parameters

enum GameState {
	TITLE,
	TRANSITION,
	PLAYING,
	GAME_OVER
}

## Configuration
const STARTING_LIVES = 3
const TRANSITION_DURATION = 2.0
const WINS_PER_TIER_INCREASE = 5
const SCORE_MILESTONE_INTERVAL = 10

## References (set these in the scene)
@onready var microgame_manager: MicrogameManager = $MicrogameManager
@onready var microgame_container: Node2D = $MicrogameContainer
@onready var ui_layer: CanvasLayer = $UILayer

## UI References (will be set when UI scenes are created)
var hud: Control
var title_screen: Control
var transition_screen: Control
var game_over_screen: Control

## Game state
var current_state: GameState = GameState.TITLE
var score: int = 0
var lives: int = STARTING_LIVES
var difficulty_tier: int = 1
var consecutive_wins: int = 0

## Current microgame
var current_microgame: MicrogameBase = null
var transition_timer: float = 0.0


func _ready() -> void:
	# Get UI references
	_setup_ui_references()

	# Start at title screen
	_change_state(GameState.TITLE)

	print("WarioWare Game Engine initialized!")
	print("Microgames loaded: %d" % microgame_manager.get_microgame_count())


func _setup_ui_references() -> void:
	# These will be set when we create the UI scenes
	# For now, we'll handle them gracefully if they don't exist
	hud = ui_layer.get_node_or_null("HUD")
	title_screen = ui_layer.get_node_or_null("TitleScreen")
	transition_screen = ui_layer.get_node_or_null("TransitionScreen")
	game_over_screen = ui_layer.get_node_or_null("GameOverScreen")

	# Connect button signals
	if title_screen:
		var start_button = title_screen.get_node_or_null("CenterContainer/VBoxContainer/StartButton")
		if start_button:
			start_button.pressed.connect(on_start_button_pressed)

	if game_over_screen:
		var restart_button = game_over_screen.get_node_or_null("CenterContainer/VBoxContainer/RestartButton")
		if restart_button:
			restart_button.pressed.connect(on_restart_button_pressed)


func _process(delta: float) -> void:
	match current_state:
		GameState.TRANSITION:
			_process_transition(delta)


func _process_transition(delta: float) -> void:
	transition_timer -= delta
	if transition_timer <= 0:
		_start_microgame()


## Start a new game
func start_game() -> void:
	score = 0
	lives = STARTING_LIVES
	difficulty_tier = 1
	consecutive_wins = 0

	_update_hud()
	_start_next_microgame()


## Start the next microgame
func _start_next_microgame() -> void:
	# Select microgame
	var microgame = microgame_manager.select_microgame(difficulty_tier)

	if microgame == null:
		push_error("Failed to select microgame")
		_game_over()
		return

	current_microgame = microgame

	# Show transition screen with instruction
	_change_state(GameState.TRANSITION)
	if transition_screen:
		transition_screen.show_instruction(current_microgame.instructions)

	transition_timer = TRANSITION_DURATION


## Start playing the selected microgame
func _start_microgame() -> void:
	_change_state(GameState.PLAYING)

	# Add microgame to scene
	microgame_container.add_child(current_microgame)

	# Connect signals
	current_microgame.game_won.connect(_on_microgame_won)
	current_microgame.game_lost.connect(_on_microgame_lost)

	# Start the microgame
	current_microgame.start_game(difficulty_tier)


## Handle microgame win
func _on_microgame_won() -> void:
	score += 1
	consecutive_wins += 1

	# Flash effect (can be done in UI layer)
	_show_win_effect()

	_cleanup_current_microgame()
	_check_difficulty_increase()
	_update_hud()

	# Small delay before next microgame
	await get_tree().create_timer(0.6).timeout
	_start_next_microgame()


## Handle microgame loss
func _on_microgame_lost() -> void:
	lives -= 1
	consecutive_wins = 0

	# Flash effect
	_show_lose_effect()

	_cleanup_current_microgame()
	_update_hud()

	if lives <= 0:
		await get_tree().create_timer(0.6).timeout
		_game_over()
	else:
		await get_tree().create_timer(0.6).timeout
		_start_next_microgame()


## Clean up current microgame
func _cleanup_current_microgame() -> void:
	if current_microgame:
		current_microgame.cleanup()
		current_microgame = null


## Check if difficulty should increase
func _check_difficulty_increase() -> void:
	var should_increase = false

	# Check consecutive wins
	if consecutive_wins >= WINS_PER_TIER_INCREASE:
		should_increase = true
		consecutive_wins = 0

	# Check score milestones
	if score > 0 and score % SCORE_MILESTONE_INTERVAL == 0:
		should_increase = true

	if should_increase and difficulty_tier < 4:
		difficulty_tier += 1
		print("Difficulty increased to tier %d" % difficulty_tier)


## Game over
func _game_over() -> void:
	_change_state(GameState.GAME_OVER)
	if game_over_screen:
		game_over_screen.show_score(score)


## Change game state
func _change_state(new_state: GameState) -> void:
	current_state = new_state

	# Hide all screens
	if title_screen:
		title_screen.visible = (new_state == GameState.TITLE)
	if transition_screen:
		transition_screen.visible = (new_state == GameState.TRANSITION)
	if game_over_screen:
		game_over_screen.visible = (new_state == GameState.GAME_OVER)
	if hud:
		hud.visible = (new_state != GameState.TITLE)


## Update HUD
func _update_hud() -> void:
	if hud:
		hud.update_display(score, lives, difficulty_tier)


## Visual effects
func _show_win_effect() -> void:
	# TODO: Implement screen flash or particle effect
	pass


func _show_lose_effect() -> void:
	# TODO: Implement screen flash or particle effect
	pass


## Called from UI buttons
func on_start_button_pressed() -> void:
	start_game()


func on_restart_button_pressed() -> void:
	start_game()
