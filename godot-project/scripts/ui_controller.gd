extends Control

## UI Controller - Handles UI updates and interactions
## This can be attached to HUD, TitleScreen, TransitionScreen, or GameOverScreen

var game_engine: Node

func _ready() -> void:
	# Get reference to game engine
	game_engine = get_node("/root/Main")

	# Connect buttons
	_connect_buttons()


func _connect_buttons() -> void:
	# Title screen button
	var start_button = get_node_or_null("../TitleScreen/CenterContainer/VBoxContainer/StartButton")
	if start_button:
		start_button.pressed.connect(_on_start_pressed)

	# Game over screen button
	var restart_button = get_node_or_null("../GameOverScreen/CenterContainer/VBoxContainer/RestartButton")
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)


func _on_start_pressed() -> void:
	if game_engine:
		game_engine.on_start_button_pressed()


func _on_restart_pressed() -> void:
	if game_engine:
		game_engine.on_restart_button_pressed()


## Called by game engine to update HUD
func update_display(score: int, lives: int, tier: int) -> void:
	var score_label = get_node_or_null("Panel/ScoreLabel")
	if score_label:
		score_label.text = "Score: %d" % score

	var lives_label = get_node_or_null("Panel/LivesLabel")
	if lives_label:
		var heart_str = ""
		for i in range(lives):
			heart_str += "❤️"
		lives_label.text = "Lives: %s" % heart_str

	var tier_label = get_node_or_null("Panel/TierLabel")
	if tier_label:
		tier_label.text = "Tier: %d" % tier


## Show instruction on transition screen
func show_instruction(text: String) -> void:
	var instruction_label = get_node_or_null("InstructionLabel")
	if instruction_label:
		instruction_label.text = text


## Show final score on game over screen
func show_score(score: int) -> void:
	var score_label = get_node_or_null("CenterContainer/VBoxContainer/ScoreLabel")
	if score_label:
		score_label.text = "Final Score: %d" % score
