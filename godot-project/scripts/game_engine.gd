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
var debug_screen: Control

## Game state
var current_state: GameState = GameState.TITLE
var score: int = 0
var lives: int = STARTING_LIVES
var difficulty_tier: int = 1
var consecutive_wins: int = 0

## Current microgame
var current_microgame: MicrogameBase = null
var transition_timer: float = 0.0

## Debug and Statistics
var show_debug: bool = false
var game_stats: Dictionary = {}  # Format: { "game_id": { "wins": 0, "losses": 0, "total": 0 } }


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
	debug_screen = ui_layer.get_node_or_null("DebugScreen")

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
		var instruction_label = transition_screen.get_node_or_null("InstructionLabel")
		if instruction_label:
			instruction_label.text = current_microgame.instructions

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

	# Track statistics
	if current_microgame:
		_record_game_result(current_microgame.microgame_id, true)

	# Flash effect (can be done in UI layer)
	_show_win_effect()

	_check_difficulty_increase()
	_update_hud()

	# Wait for microgame animation to complete before cleanup
	await get_tree().create_timer(0.6).timeout
	_cleanup_current_microgame()
	_start_next_microgame()


## Handle microgame loss
func _on_microgame_lost() -> void:
	lives -= 1
	consecutive_wins = 0

	# Track statistics
	if current_microgame:
		_record_game_result(current_microgame.microgame_id, false)

	# Flash effect
	_show_lose_effect()

	_update_hud()

	# Wait for microgame animation to complete before cleanup
	await get_tree().create_timer(0.6).timeout
	_cleanup_current_microgame()

	if lives <= 0:
		_game_over()
	else:
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
		var score_label = game_over_screen.get_node_or_null("CenterContainer/VBoxContainer/ScoreLabel")
		if score_label:
			score_label.text = "Final Score: %d" % score


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
		var score_label = hud.get_node_or_null("Panel/ScoreLabel")
		if score_label:
			score_label.text = "Score: %d" % score

		var lives_label = hud.get_node_or_null("Panel/LivesLabel")
		if lives_label:
			var hearts = ""
			for i in lives:
				hearts += "❤️"
			lives_label.text = "Lives: " + hearts

		var tier_label = hud.get_node_or_null("Panel/TierLabel")
		if tier_label:
			tier_label.text = "Tier: %d" % difficulty_tier


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


## Debug and Statistics Functions

## Record win/loss for a microgame
func _record_game_result(game_id: String, won: bool) -> void:
	if not game_stats.has(game_id):
		game_stats[game_id] = { "wins": 0, "losses": 0, "total": 0 }

	if won:
		game_stats[game_id]["wins"] += 1
	else:
		game_stats[game_id]["losses"] += 1

	game_stats[game_id]["total"] += 1


## Handle input for debug mode toggle
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			toggle_debug_mode()


## Toggle debug mode visibility
func toggle_debug_mode() -> void:
	show_debug = !show_debug
	if debug_screen:
		debug_screen.visible = show_debug

	if show_debug:
		_update_debug_screen()


## Launch a specific game for testing
func debug_launch_game(game_id: String, tier: int = 1) -> void:
	# Force select a specific game
	for scene in microgame_manager.registered_microgames:
		var temp = scene.instantiate() as MicrogameBase
		add_child(temp)

		if temp.microgame_id == game_id:
			remove_child(temp)
			temp.queue_free()

			# Clean up current game if any
			_cleanup_current_microgame()

			# Start the selected game
			var instance = scene.instantiate() as MicrogameBase
			microgame_container.add_child(instance)
			current_microgame = instance

			# Connect signals
			current_microgame.game_won.connect(_on_microgame_won)
			current_microgame.game_lost.connect(_on_microgame_lost)

			# Start immediately
			_change_state(GameState.PLAYING)
			current_microgame.start_game(tier)

			# Hide debug screen
			show_debug = false
			if debug_screen:
				debug_screen.visible = false

			print("Debug: Launched %s (Tier %d)" % [game_id, tier])
			return

		remove_child(temp)
		temp.queue_free()

	push_error("Debug: Game '%s' not found" % game_id)


## Update debug screen with current stats
func _update_debug_screen() -> void:
	if not debug_screen:
		return

	# Update info text
	var debug_label = debug_screen.get_node_or_null("DebugPanel/HBoxContainer/ScrollContainer/DebugLabel")
	if not debug_label:
		return

	# Create test buttons
	var buttons_container = debug_screen.get_node_or_null("DebugPanel/HBoxContainer/GameButtonsPanel/VBoxContainer/GameButtonsContainer")
	if buttons_container:
		# Clear existing buttons
		for child in buttons_container.get_children():
			child.queue_free()

		# Create button for each game
		var game_ids = ["click_circle", "dodge_block", "mash_key", "dont_click", "drag_target", "catch_falling"]
		var game_names = {
			"click_circle": "Click Circle",
			"dodge_block": "Dodge Block",
			"mash_key": "Mash Key",
			"dont_click": "Don't Click",
			"drag_target": "Drag Target",
			"catch_falling": "Catch Falling"
		}

		for game_id in game_ids:
			# Create button for each tier
			var game_label = Label.new()
			game_label.text = game_names[game_id]
			game_label.add_theme_font_size_override("font_size", 14)
			buttons_container.add_child(game_label)

			var tier_container = HBoxContainer.new()
			for tier in range(1, 5):
				var button = Button.new()
				button.text = "T%d" % tier
				button.custom_minimum_size = Vector2(50, 30)
				button.pressed.connect(debug_launch_game.bind(game_id, tier))
				tier_container.add_child(button)
			buttons_container.add_child(tier_container)

			# Add small spacer
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 5)
			buttons_container.add_child(spacer)

	var text = "[b][color=cyan]═══ MICROGAME DEBUG / QA MODE ═══[/color][/b]\n\n"
	text += "[color=yellow]Click tier buttons on the left to test any game directly![/color]\n\n"

	# Game descriptions with how to win
	var game_info = {
		"click_circle": {
			"name": "Click the Circle",
			"description": "Click the shrinking circle before time runs out",
			"how_to_win": "Click the circle before it shrinks to nothing"
		},
		"dodge_block": {
			"name": "Dodge the Block",
			"description": "Dodge falling blocks by moving mouse",
			"how_to_win": "Survive until time runs out without hitting blocks"
		},
		"mash_key": {
			"name": "Mash the Key",
			"description": "Rapidly press keys to fill the bar",
			"how_to_win": "Fill the progress bar to 100% by pressing the target key"
		},
		"dont_click": {
			"name": "Don't Click",
			"description": "Resist clicking despite distractors",
			"how_to_win": "Don't click anything until time runs out"
		},
		"drag_target": {
			"name": "Drag to Target",
			"description": "Drag object to target zone",
			"how_to_win": "Drag the circle into the target square"
		},
		"catch_falling": {
			"name": "Catch the Falling",
			"description": "Catch falling objects with basket",
			"how_to_win": "Catch the required number of items before time runs out"
		}
	}

	text += "[b][color=yellow]REGISTERED GAMES:[/color][/b] %d\n\n" % microgame_manager.get_microgame_count()

	# Show each game with stats
	for game_id in game_info.keys():
		var info = game_info[game_id]
		text += "[b][color=lime]■ %s[/color][/b]\n" % info["name"]
		text += "   [color=gray]Description:[/color] %s\n" % info["description"]
		text += "   [color=gray]How to Win:[/color] %s\n" % info["how_to_win"]

		# Show stats if available
		if game_stats.has(game_id):
			var stats = game_stats[game_id]
			var win_rate = 0.0
			if stats["total"] > 0:
				win_rate = (float(stats["wins"]) / float(stats["total"])) * 100.0

			text += "   [color=cyan]Stats:[/color] Played: %d | Wins: %d | Losses: %d | Win Rate: %.1f%%\n" % [
				stats["total"],
				stats["wins"],
				stats["losses"],
				win_rate
			]
		else:
			text += "   [color=gray]Stats:[/color] Not played yet\n"

		text += "\n"

	text += "\n[b][color=yellow]CURRENT SESSION:[/color][/b]\n"
	text += "Score: %d\n" % score
	text += "Lives: %d\n" % lives
	text += "Difficulty Tier: %d\n" % difficulty_tier
	text += "Consecutive Wins: %d\n" % consecutive_wins

	text += "\n[color=gray]Press F3 to toggle debug mode[/color]"

	debug_label.text = text
