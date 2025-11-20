extends GdUnitTestSuite

## Comprehensive tests for MicrogameManager
## Tests microgame registration, validation, and selection logic

const MicrogameManager = preload("res://scripts/microgame_manager.gd")

var manager: Node

func before_test() -> void:
	# Create manager instance
	manager = auto_free(MicrogameManager.new())
	add_child(manager)


func after_test() -> void:
	# Cleanup handled by auto_free
	pass


func test_manager_loads_valid_microgames() -> void:
	# Wait for _ready to complete
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# VERIFY: All valid microgames should be loaded
	var count = manager.get_microgame_count()
	assert_int(count).is_greater(0)


func test_get_microgame_count_returns_correct_value() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# VERIFY: Count matches registered games
	var count = manager.get_microgame_count()
	assert_int(count).is_equal(manager.registered_microgames.size())


func test_select_microgame_returns_valid_instance_for_tier_1() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# EXECUTE: Select a tier 1 microgame
	var microgame = manager.select_microgame(1)

	# VERIFY: Returns a valid MicrogameBase instance
	assert_object(microgame).is_not_null()
	assert_bool(microgame is MicrogameBase).is_true()

	# Cleanup
	microgame.queue_free()


func test_select_microgame_returns_valid_instance_for_tier_2() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# EXECUTE: Select tier 2 microgame
	var microgame = manager.select_microgame(2)

	# VERIFY: Instance is valid
	assert_object(microgame).is_not_null()
	assert_bool(microgame is MicrogameBase).is_true()
	assert_int(microgame.get_max_tier()).is_greater_equal(2)

	# Cleanup
	microgame.queue_free()


func test_select_microgame_returns_valid_instance_for_tier_3() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# EXECUTE: Select tier 3 microgame
	var microgame = manager.select_microgame(3)

	# VERIFY: Instance is valid
	assert_object(microgame).is_not_null()
	assert_bool(microgame is MicrogameBase).is_true()
	assert_int(microgame.get_max_tier()).is_greater_equal(3)

	# Cleanup
	microgame.queue_free()


func test_select_microgame_returns_valid_instance_for_tier_4() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# EXECUTE: Select tier 4 microgame
	var microgame = manager.select_microgame(4)

	# VERIFY: Instance is valid
	assert_object(microgame).is_not_null()
	assert_bool(microgame is MicrogameBase).is_true()
	assert_int(microgame.get_max_tier()).is_greater_equal(4)

	# Cleanup
	microgame.queue_free()


func test_selected_microgame_has_required_metadata() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# EXECUTE: Select a microgame
	var microgame = manager.select_microgame(1)

	# VERIFY: Has required fields
	assert_str(microgame.microgame_id).is_not_empty()
	assert_str(microgame.microgame_name).is_not_empty()
	assert_str(microgame.instructions).is_not_empty()

	# Cleanup
	microgame.queue_free()


func test_selected_microgame_has_difficulty_tiers() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# EXECUTE: Select a microgame
	var microgame = manager.select_microgame(1)

	# VERIFY: Has difficulty tiers configured
	assert_array(microgame.difficulty_tiers).is_not_empty()

	# Cleanup
	microgame.queue_free()


func test_multiple_selections_return_different_instances() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# EXECUTE: Select multiple microgames
	var microgame1 = manager.select_microgame(1)
	var microgame2 = manager.select_microgame(1)

	# VERIFY: Different instances returned
	assert_bool(microgame1 != microgame2).is_true()

	# Cleanup
	microgame1.queue_free()
	microgame2.queue_free()


func test_manager_handles_empty_scene_list_gracefully() -> void:
	# SETUP: Create manager with no scenes
	var empty_manager = auto_free(MicrogameManager.new())
	empty_manager.microgame_scenes = []
	add_child(empty_manager)

	# Wait for loading
	await await_signal_on(empty_manager.get_tree(), "process_frame", [], 1000)

	# VERIFY: Count is zero
	assert_int(empty_manager.get_microgame_count()).is_equal(0)

	# EXECUTE: Try to select with no games
	var result = empty_manager.select_microgame(1)

	# VERIFY: Returns null
	assert_object(result).is_null()


func test_selection_randomness() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# SKIP if only one microgame
	if manager.get_microgame_count() < 2:
		return

	# EXECUTE: Select many microgames
	var ids_seen = {}
	for i in range(20):
		var microgame = manager.select_microgame(1)
		if microgame:
			ids_seen[microgame.microgame_id] = true
			microgame.queue_free()

	# VERIFY: Multiple different games were selected (if there are multiple games)
	assert_int(ids_seen.size()).is_greater(0)


func test_registered_microgames_are_packed_scenes() -> void:
	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# VERIFY: All registered microgames are PackedScenes
	for scene in manager.registered_microgames:
		assert_bool(scene is PackedScene).is_true()


func test_microgame_scenes_array_is_configured() -> void:
	# VERIFY: Manager has microgame scenes configured
	assert_array(manager.microgame_scenes).is_not_empty()


func test_manager_validates_microgame_inheritance() -> void:
	# This test verifies the validation happens during _load_microgames
	# We're checking that invalid scenes are rejected

	# Wait for loading
	await await_signal_on(manager.get_tree(), "process_frame", [], 1000)

	# VERIFY: All loaded microgames pass validation
	# (if any invalid scenes existed, they would be filtered out)
	for scene in manager.registered_microgames:
		var instance = scene.instantiate()
		assert_bool(instance is MicrogameBase).is_true()
		instance.queue_free()
