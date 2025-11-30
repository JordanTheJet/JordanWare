extends Node
class_name MicrogameManager

## Manages microgame registration, selection, and loading
##
## USAGE:
## 1. Add microgame scenes to the microgames array in the inspector
## 2. Manager automatically validates and registers them
## 3. Call select_microgame(tier) to get a random eligible microgame

## Array of microgame scene paths (set in inspector or code)
## FIRST BATCH: Original 20 games for testing
@export var microgame_scenes: Array[String] = [
	"res://scenes/microgames/click_circle.tscn",
	"res://scenes/microgames/dodge_block.tscn",
	"res://scenes/microgames/mash_key.tscn",
	"res://scenes/microgames/dont_click.tscn",
	"res://scenes/microgames/drag_target.tscn",
	"res://scenes/microgames/catch_falling.tscn",
	"res://scenes/microgames/match_color.tscn",
	"res://scenes/microgames/stop_timer.tscn",
	"res://scenes/microgames/avoid_obstacles.tscn",
	"res://scenes/microgames/sequence_memory.tscn",
	"res://scenes/microgames/spin_arrow.tscn",
	"res://scenes/microgames/count_objects.tscn",
	"res://scenes/microgames/type_word.tscn",
	"res://scenes/microgames/find_different.tscn",
	"res://scenes/microgames/balance_bar.tscn",
	"res://scenes/microgames/pop_balloon.tscn",
	"res://scenes/microgames/aim_target.tscn",
	"res://scenes/microgames/sort_items.tscn",
	"res://scenes/microgames/connect_dots.tscn",
	"res://scenes/microgames/shake_screen.tscn",

	# NEW 30 GAMES - Commented out for testing first batch
	#
	#"res://scenes/microgames/avoid_catching.tscn",
	#"res://scenes/microgames/collect_color.tscn",
	#"res://scenes/microgames/dodge_vertical.tscn",
	#"res://scenes/microgames/click_wrong_button.tscn",
	#"res://scenes/microgames/drag_avoid.tscn",
	#"res://scenes/microgames/match_sound.tscn",
	#"res://scenes/microgames/stop_at_color.tscn",
	#"res://scenes/microgames/press_when_full.tscn",
	#"res://scenes/microgames/same_or_different.tscn",
	#"res://scenes/microgames/click_odd_one.tscn",
	#"res://scenes/microgames/bigger_or_smaller.tscn",
	#"res://scenes/microgames/stop_on_target.tscn",
	#"res://scenes/microgames/keep_cursor_in.tscn",
	#"res://scenes/microgames/break_sequence.tscn",
	#"res://scenes/microgames/backwards_trace.tscn",
	#"res://scenes/microgames/unorder_items.tscn",
	#"res://scenes/microgames/move_slider_away.tscn",
	#"res://scenes/microgames/wrong_color_match.tscn",
	#"res://scenes/microgames/complete_pattern.tscn",
	#"res://scenes/microgames/balance_scale.tscn",
	#"res://scenes/microgames/connect_path.tscn",
	#"res://scenes/microgames/mirror_match.tscn",
	#"res://scenes/microgames/three_in_row.tscn",
	#"res://scenes/microgames/crack_code.tscn",
	#"res://scenes/microgames/double_tap.tscn",
	#"res://scenes/microgames/hold_button.tscn",
	#"res://scenes/microgames/rapid_click.tscn",
	#"res://scenes/microgames/rhythm_hold.tscn",
	#"res://scenes/microgames/charge_release.tscn",
	#"res://scenes/microgames/tap_circles.tscn",
]

## Registered microgame resources
var registered_microgames: Array[PackedScene] = []


func _ready() -> void:
	_load_microgames()


## Load and validate all microgame scenes
func _load_microgames() -> void:
	registered_microgames.clear()

	for scene_path in microgame_scenes:
		if not ResourceLoader.exists(scene_path):
			push_warning("Microgame scene not found: %s" % scene_path)
			continue

		var scene = load(scene_path) as PackedScene
		if scene == null:
			push_warning("Failed to load microgame: %s" % scene_path)
			continue

		# Instantiate to check if it's a valid microgame
		var instance = scene.instantiate()
		if not instance is MicrogameBase:
			push_warning("Scene is not a MicrogameBase: %s" % scene_path)
			instance.queue_free()
			continue

		# _ready() is not called until the node is added to the tree
		# So we need to add it temporarily to trigger _ready()
		add_child(instance)

		# Validate required fields
		if instance.microgame_id.is_empty() or instance.microgame_name.is_empty():
			push_warning("Microgame missing required fields: %s (id='%s', name='%s')" % [scene_path, instance.microgame_id, instance.microgame_name])
			instance.queue_free()
			continue

		# Remove from tree before freeing
		remove_child(instance)

		instance.queue_free()
		registered_microgames.append(scene)
		print("Registered microgame: %s" % scene_path)

	print("Total microgames registered: %d" % registered_microgames.size())


## Select a random microgame that supports the given tier
## Returns a new instance of the selected microgame, or null if none found
func select_microgame(tier: int) -> MicrogameBase:
	if registered_microgames.is_empty():
		push_error("No microgames registered!")
		return null

	# Filter microgames that support this tier
	var eligible_scenes: Array[PackedScene] = []

	for scene in registered_microgames:
		var temp_instance = scene.instantiate() as MicrogameBase
		add_child(temp_instance)  # Need to add to tree to trigger _ready()
		if temp_instance.get_max_tier() >= tier:
			eligible_scenes.append(scene)
		remove_child(temp_instance)
		temp_instance.queue_free()

	if eligible_scenes.is_empty():
		push_error("No microgames support tier %d" % tier)
		return null

	# Select random microgame
	var selected_scene = eligible_scenes[randi() % eligible_scenes.size()]
	var instance = selected_scene.instantiate() as MicrogameBase

	return instance


## Get count of registered microgames
func get_microgame_count() -> int:
	return registered_microgames.size()
