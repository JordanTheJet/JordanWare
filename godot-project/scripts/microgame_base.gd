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
	_show_result_animation(true)
	await get_tree().create_timer(0.5).timeout
	game_won.emit()


## Call this when player loses
func _lose_game() -> void:
	if has_completed:
		return

	has_completed = true
	is_active = false
	_show_result_animation(false)
	await get_tree().create_timer(0.5).timeout
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


## Helper: Check if mouse click is inside an area
func _is_click_in_area(click_pos: Vector2, area: Area2D) -> bool:
	if not is_instance_valid(area):
		return false

	# Get collision shape
	for child in area.get_children():
		if child is CollisionShape2D:
			var collision = child as CollisionShape2D
			var shape = collision.shape

			if shape is CircleShape2D:
				var circle = shape as CircleShape2D
				var dist = area.position.distance_to(click_pos)
				return dist <= circle.radius
			elif shape is RectangleShape2D:
				var rect_shape = shape as RectangleShape2D
				var half_size = rect_shape.size / 2.0
				var rect = Rect2(area.position - half_size, rect_shape.size)
				return rect.has_point(click_pos)

	return false


## Show universal win/lose animation
func _show_result_animation(won: bool) -> void:
	# Create fullscreen overlay
	var overlay = ColorRect.new()
	overlay.size = Vector2(1280, 720)
	overlay.position = Vector2.ZERO
	overlay.color = Color.GREEN if won else Color.RED
	overlay.color.a = 0.0
	overlay.z_index = 1000
	add_child(overlay)

	# Create result text
	var result_label = Label.new()
	result_label.text = "SUCCESS!" if won else "FAILED!"
	result_label.position = Vector2(440, 300)
	result_label.add_theme_font_size_override("font_size", 96)
	result_label.add_theme_color_override("font_color", Color.WHITE)
	result_label.modulate.a = 0.0
	result_label.z_index = 1001
	add_child(result_label)

	# Animate flash
	var tween = create_tween()
	tween.set_parallel(true)

	# Flash overlay
	tween.tween_property(overlay, "color:a", 0.7, 0.1)
	tween.tween_property(overlay, "color:a", 0.0, 0.4).set_delay(0.1)

	# Fade in text
	tween.tween_property(result_label, "modulate:a", 1.0, 0.15)

	# Scale text
	result_label.scale = Vector2(0.5, 0.5)
	tween.tween_property(result_label, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(result_label, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.2)

	# Clean up after animation
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(overlay):
		overlay.queue_free()
	if is_instance_valid(result_label):
		result_label.queue_free()


## Clean up when microgame is removed
func cleanup() -> void:
	is_active = false
	queue_free()
