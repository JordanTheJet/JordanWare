extends Node2D
class_name MicrogameBase

## Base class for all microgames
## All microgames must inherit from this and implement the required methods
##
## ARCHITECTURE:
## - Each microgame is a scene with this script (or a child class) attached
## - Microgames declare their difficulty tiers with parameters
## - The game engine loads, initializes, and updates microgames
## - Microgames signal when they're won or lost

## Emitted when player wins the microgame
signal game_won

## Emitted when player loses the microgame
signal game_lost

## Microgame metadata
@export var microgame_id: String = ""
@export var microgame_name: String = ""
@export var instructions: String = ""

## Difficulty tier configurations
## Each tier should have: { tier: int, time_limit: float, parameters: Dictionary }
var difficulty_tiers: Array[Dictionary] = []

## Current difficulty parameters (set by game engine)
var current_parameters: Dictionary = {}
var time_limit: float = 5.0
var time_remaining: float = 0.0

## Game state
var is_active: bool = false
var has_completed: bool = false


func _ready() -> void:
	# Define difficulty tiers in child classes
	_define_difficulty_tiers()

	# Initialize game-specific elements
	_setup_game()


## Override this in child classes to define difficulty tiers
func _define_difficulty_tiers() -> void:
	push_error("MicrogameBase: _define_difficulty_tiers() must be overridden")


## Override this in child classes to set up game elements
func _setup_game() -> void:
	push_error("MicrogameBase: _setup_game() must be overridden")


## Called by game engine to start the microgame with specific tier
func start_game(tier: int) -> void:
	# Find the appropriate tier configuration
	var tier_config = _get_tier_config(tier)

	if tier_config.is_empty():
		push_error("No tier configuration found for tier %d" % tier)
		return

	current_parameters = tier_config.parameters
	time_limit = tier_config.time_limit
	time_remaining = time_limit
	is_active = true
	has_completed = false

	# Call game-specific initialization
	_on_game_start()


## Override this in child classes for game-specific start logic
func _on_game_start() -> void:
	pass


## Called every frame while game is active
func _process(delta: float) -> void:
	if not is_active or has_completed:
		return

	# Update timer
	time_remaining -= delta

	# Check timeout
	if time_remaining <= 0:
		_lose_game()
		return

	# Update game-specific logic
	_update_game(delta)


## Override this in child classes for game-specific update logic
func _update_game(delta: float) -> void:
	pass


## Call this when player wins
func _win_game() -> void:
	if has_completed:
		return

	has_completed = true
	is_active = false
	game_won.emit()


## Call this when player loses
func _lose_game() -> void:
	if has_completed:
		return

	has_completed = true
	is_active = false
	game_lost.emit()


## Get tier configuration for given tier number
func _get_tier_config(tier: int) -> Dictionary:
	for config in difficulty_tiers:
		if config.tier == tier:
			return config

	# If exact tier not found, get highest available tier <= requested tier
	var best_config = {}
	var best_tier = 0

	for config in difficulty_tiers:
		if config.tier <= tier and config.tier > best_tier:
			best_config = config
			best_tier = config.tier

	return best_config


## Get the maximum tier this microgame supports
func get_max_tier() -> int:
	var max_tier = 0
	for config in difficulty_tiers:
		if config.tier > max_tier:
			max_tier = config.tier
	return max_tier


## Clean up when microgame is removed
func cleanup() -> void:
	is_active = false
	queue_free()
