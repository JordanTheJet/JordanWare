extends Node
class_name MicrogameManager

## Manages microgame registration, selection, and loading
##
## USAGE:
## 1. Add microgame scenes to the microgames array in the inspector
## 2. Manager automatically validates and registers them
## 3. Call select_microgame(tier) to get a random eligible microgame

## Array of microgame scene paths (set in inspector or code)
@export var microgame_scenes: Array[String] = [
	"res://scenes/microgames/click_circle.tscn",
	"res://scenes/microgames/dodge_block.tscn",
	"res://scenes/microgames/mash_key.tscn",
	"res://scenes/microgames/dont_click.tscn",
	"res://scenes/microgames/drag_target.tscn",
	"res://scenes/microgames/catch_falling.tscn",
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

		# Validate required fields
		if instance.microgame_id.is_empty() or instance.microgame_name.is_empty():
			push_warning("Microgame missing required fields: %s" % scene_path)
			instance.queue_free()
			continue

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
		if temp_instance.get_max_tier() >= tier:
			eligible_scenes.append(scene)
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
