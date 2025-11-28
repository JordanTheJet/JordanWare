extends Node

## QA Test Runner - Automated testing for all 30 new microgames
## This script systematically tests each game across all difficulty tiers
## and records results for comprehensive QA reporting

## List of 30 NEW games to test
const NEW_GAMES = [
	# Quick Variations (6)
	"avoid_catching",
	"collect_color",
	"dodge_vertical",
	"click_wrong_button",
	"drag_avoid",
	"match_sound",
	# Ultra-Simple (8)
	"stop_at_color",
	"press_when_full",
	"same_or_different",
	"click_odd_one",
	"bigger_or_smaller",
	"stop_on_target",
	"keep_cursor_in",
	"count_objects",  # Note: This was existing, not new
	# Inversions & Twists (5)
	"break_sequence",
	"backwards_trace",
	"unorder_items",
	"move_slider_away",
	"wrong_color_match",
	# Micro-Puzzles (6)
	"complete_pattern",
	"balance_scale",
	"connect_path",
	"mirror_match",
	"three_in_row",
	"crack_code",
	# Timing Challenges (5)
	"double_tap",
	"hold_button",
	"rapid_click",
	"rhythm_hold",
	"charge_release"
]

var test_results: Dictionary = {}
var current_test_index: int = 0
var current_tier: int = 1
var test_container: Node2D
var test_phase: String = "init"  # init, testing, complete

signal test_completed(results: Dictionary)

func _ready() -> void:
	# Create container for test instances
	test_container = Node2D.new()
	test_container.name = "TestContainer"
	add_child(test_container)

	print("=== QA Test Runner Initialized ===")
	print("Total games to test: %d" % NEW_GAMES.size())
	print("Tiers to test per game: 1, 2, 3")
	print("Total test cases: %d" % (NEW_GAMES.size() * 3))

func start_tests() -> void:
	print("\n=== STARTING AUTOMATED QA TESTS ===\n")
	current_test_index = 0
	test_phase = "testing"
	_test_next_game()

func _test_next_game() -> void:
	if current_test_index >= NEW_GAMES.size():
		_finish_tests()
		return

	var game_id = NEW_GAMES[current_test_index]
	print("\n--- Testing: %s ---" % game_id)

	# Test all 3 tiers
	for tier in [1, 2, 3]:
		await _test_game_tier(game_id, tier)

	current_test_index += 1
	_test_next_game()

func _test_game_tier(game_id: String, tier: int) -> void:
	print("  Tier %d: " % tier)

	var result = {
		"game_id": game_id,
		"tier": tier,
		"loaded": false,
		"errors": [],
		"warnings": [],
		"pass": false
	}

	# Try to load the game scene
	var scene_path = "res://scenes/microgames/%s.tscn" % game_id
	if not ResourceLoader.exists(scene_path):
		result.errors.append("Scene file not found: %s" % scene_path)
		_record_result(result)
		print("    [FAIL] Scene not found")
		return

	var scene = load(scene_path) as PackedScene
	if scene == null:
		result.errors.append("Failed to load scene")
		_record_result(result)
		print("    [FAIL] Scene load failed")
		return

	var instance = scene.instantiate() as MicrogameBase
	if instance == null:
		result.errors.append("Instance is not MicrogameBase")
		_record_result(result)
		print("    [FAIL] Not a MicrogameBase")
		return

	# Add to test container
	test_container.add_child(instance)
	result.loaded = true

	# Validate basic properties
	if instance.microgame_id.is_empty():
		result.errors.append("microgame_id is empty")
	if instance.microgame_name.is_empty():
		result.errors.append("microgame_name is empty")
	if instance.instructions.is_empty():
		result.warnings.append("instructions is empty")
	if instance.difficulty_tiers.is_empty():
		result.errors.append("No difficulty tiers defined")

	# Check if tier is supported
	var max_tier = instance.get_max_tier()
	if max_tier < tier:
		result.warnings.append("Tier %d not supported (max: %d)" % [tier, max_tier])

	# Try to start the game
	instance.start_game(tier)

	# Wait a frame for initialization
	await get_tree().process_frame

	# Check if game started properly
	if not instance.is_active:
		result.errors.append("Game did not activate")

	# Basic runtime checks
	if instance.time_remaining <= 0:
		result.warnings.append("time_remaining is <= 0")

	# Determine pass/fail
	result.pass = result.errors.is_empty() and result.loaded

	# Cleanup
	instance.queue_free()

	_record_result(result)

	if result.pass:
		print("    [PASS]")
	else:
		print("    [FAIL] Errors: %s" % str(result.errors))

	# Small delay between tests
	await get_tree().create_timer(0.1).timeout

func _record_result(result: Dictionary) -> void:
	var key = "%s_t%d" % [result.game_id, result.tier]
	test_results[key] = result

func _finish_tests() -> void:
	test_phase = "complete"
	print("\n=== QA TESTS COMPLETED ===\n")
	_print_summary()
	test_completed.emit(test_results)

func _print_summary() -> void:
	var total = test_results.size()
	var passed = 0
	var failed = 0
	var total_errors = 0
	var total_warnings = 0

	for key in test_results:
		var result = test_results[key]
		if result.pass:
			passed += 1
		else:
			failed += 1
		total_errors += result.errors.size()
		total_warnings += result.warnings.size()

	print("SUMMARY:")
	print("  Total test cases: %d" % total)
	print("  Passed: %d (%.1f%%)" % [passed, (float(passed) / total) * 100.0])
	print("  Failed: %d (%.1f%%)" % [failed, (float(failed) / total) * 100.0])
	print("  Total errors: %d" % total_errors)
	print("  Total warnings: %d" % total_warnings)

	print("\nFailed tests:")
	for key in test_results:
		var result = test_results[key]
		if not result.pass:
			print("  - %s (Tier %d): %s" % [result.game_id, result.tier, str(result.errors)])

func get_results() -> Dictionary:
	return test_results
