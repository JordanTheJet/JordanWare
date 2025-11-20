# Testing Guide - WarioWare Microgame Platform

This guide explains how to run tests, write new tests, and maintain the testing infrastructure.

---

## Quick Start

### Running All Tests

```bash
cd /Users/jordantian/JordanWare/godot-project

# Run all tests
addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --add test \
  --continue
```

### Running Specific Test Suite

```bash
# Run only game engine tests
addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --add test/test_game_engine.gd
```

### Running Single Test

```bash
# Run one specific test method
addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --add test/test_game_engine.gd:test_initial_state
```

---

## Test File Structure

```
test/
├── test_game_engine.gd        # Tests for game state management
├── test_microgame_manager.gd  # Tests for microgame loading/selection
├── test_microgame_base.gd     # Tests for microgame lifecycle
├── test_click_circle.gd       # Tests for click_circle microgame
├── test_dodge_block.gd        # Tests for dodge_block microgame
├── test_mash_key.gd           # Tests for mash_key microgame
└── test_ui_controller.gd      # Tests for UI updates
```

---

## Writing New Tests

### Basic Test Template

```gdscript
extends GdUnitTestSuite

## Tests for MyAwesomeSystem
## Brief description of what this test suite covers

const MySystem = preload("res://scripts/my_system.gd")

var system: Node

func before_test() -> void:
    # Create instance before each test
    system = auto_free(MySystem.new())
    add_child(system)


func after_test() -> void:
    # Cleanup handled by auto_free
    pass


func test_something_works() -> void:
    # SETUP: Prepare test conditions
    system.some_property = 42

    # EXECUTE: Perform action
    system.do_something()

    # VERIFY: Check results
    assert_int(system.result).is_equal(84)
```

### GdUnit4 API Reference

#### Assertions

```gdscript
# Integer assertions
assert_int(value).is_equal(42)
assert_int(value).is_greater(10)
assert_int(value).is_less(100)
assert_int(value).is_between(10, 100)

# Float assertions
assert_float(value).is_equal(3.14)
assert_float(value).is_equal_approx(3.14, 0.01)
assert_float(value).is_greater(0.0)

# Boolean assertions
assert_bool(value).is_true()
assert_bool(value).is_false()

# String assertions
assert_str(text).is_equal("Hello")
assert_str(text).contains("ello")
assert_str(text).is_not_empty()

# Array assertions
assert_array(list).has_size(5)
assert_array(list).contains([1, 2, 3])
assert_array(list).is_not_empty()

# Object assertions
assert_object(obj).is_null()
assert_object(obj).is_not_null()
assert_object(obj).is_instanceof(Node)

# Vector assertions
assert_vector(vec).is_equal(Vector2(10, 20))

# Dictionary assertions
assert_dict(dict).contains_keys(["key1", "key2"])
assert_dict(dict).is_not_empty()
```

#### Signal Testing

```gdscript
func test_signal_emission() -> void:
    # Monitor signals from object
    var monitor = monitor_signals(my_object)

    # Trigger action
    my_object.do_something()

    # Verify signal was emitted
    assert_signal(monitor).is_emitted("my_signal")


func test_signal_with_args() -> void:
    var monitor = monitor_signals(my_object)

    my_object.trigger_event()

    # Check signal with specific arguments
    assert_signal(monitor).is_emitted("event", [42, "test"])


func test_signal_not_emitted() -> void:
    var monitor = monitor_signals(my_object)

    # Don't trigger anything

    # Verify signal was NOT emitted
    assert_signal(monitor).is_not_emitted("my_signal")
```

#### Async Testing

```gdscript
func test_async_operation() -> void:
    # Wait for signal
    await await_signal_on(my_object, "ready", [], 1000)

    # Continue testing after signal
    assert_bool(my_object.is_ready).is_true()


func test_with_timer() -> void:
    my_object.start_countdown()

    # Wait 1 second
    await await_signal_on(get_tree(), "process_frame", [], 1000)

    # Check state after delay
    assert_int(my_object.countdown).is_less(10)
```

---

## Common Testing Patterns

### Testing Node Lifecycle

```gdscript
func test_node_initialization() -> void:
    # Node is created in before_test()
    # Wait for _ready() to complete
    await await_signal_on(my_node.get_tree(), "process_frame", [], 1000)

    # Now test initialized state
    assert_bool(my_node.is_initialized).is_true()
```

### Testing Input Events

```gdscript
func test_key_press() -> void:
    var event = InputEventKey.new()
    event.keycode = KEY_SPACE
    event.pressed = true

    my_game._input(event)

    assert_bool(my_game.key_pressed).is_true()
```

### Testing Collisions

```gdscript
func test_collision_detection() -> void:
    var monitor = monitor_signals(player)

    # Manually trigger collision
    player._on_area_entered(enemy)

    assert_signal(monitor).is_emitted("hit")
```

### Mocking Dependencies

```gdscript
func test_with_mock_dependency() -> void:
    # Create mock object
    var mock_manager = auto_free(Node.new())
    mock_manager.name = "MockManager"

    # Inject mock
    game_engine.manager = mock_manager

    # Test behavior
    game_engine.do_something()

    # Verify mock was used correctly
```

---

## Debugging Failed Tests

### Enable Verbose Output

```bash
addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --add test \
  --verbose
```

### Run Single Failing Test

```bash
# Isolate the failing test
addons/gdUnit4/runtest.sh \
  --godot_binary /Applications/Godot.app/Contents/MacOS/Godot \
  --add test/test_game_engine.gd:test_that_fails
```

### Add Debug Prints

```gdscript
func test_something() -> void:
    print("DEBUG: value = ", my_object.value)

    my_object.do_something()

    print("DEBUG: after do_something, value = ", my_object.value)

    assert_int(my_object.value).is_equal(42)
```

### Check Object State

```gdscript
func test_with_state_dump() -> void:
    # Dump object properties
    print("Object properties:")
    for property in my_object.get_property_list():
        print("  %s = %s" % [property.name, my_object.get(property.name)])

    # Continue test
```

---

## Best Practices

### 1. Test Naming Convention

```gdscript
# Good: Descriptive, explains what is being tested
func test_player_takes_damage_when_hit_by_enemy() -> void:

# Bad: Vague, unclear purpose
func test_1() -> void:
```

### 2. Arrange-Act-Assert Pattern

```gdscript
func test_score_increments_on_win() -> void:
    # ARRANGE: Set up test conditions
    game.score = 10

    # ACT: Perform the action
    game._on_microgame_won()

    # ASSERT: Verify the result
    assert_int(game.score).is_equal(11)
```

### 3. One Assertion Per Test (When Possible)

```gdscript
# Good: Focused test
func test_score_increments() -> void:
    game._on_microgame_won()
    assert_int(game.score).is_equal(1)

func test_consecutive_wins_increments() -> void:
    game._on_microgame_won()
    assert_int(game.consecutive_wins).is_equal(1)

# Acceptable: Related assertions
func test_winning_updates_both_scores() -> void:
    game._on_microgame_won()
    assert_int(game.score).is_equal(1)
    assert_int(game.consecutive_wins).is_equal(1)
```

### 4. Clean Up Resources

```gdscript
func test_with_manual_cleanup() -> void:
    var temp_node = Node.new()
    add_child(temp_node)

    # Do test...

    # Clean up
    temp_node.queue_free()
```

### 5. Test Edge Cases

```gdscript
func test_division_by_zero() -> void:
    # Test boundary condition
    var result = calculator.divide(10, 0)
    assert_float(result).is_equal(0.0)  # Or handle error

func test_empty_array() -> void:
    var result = processor.process([])
    assert_array(result).is_empty()

func test_negative_input() -> void:
    var result = abs_value(-42)
    assert_int(result).is_equal(42)
```

---

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Download Godot
        run: |
          wget https://downloads.tuxfamily.org/godotengine/4.5.1/Godot_v4.5.1-stable_linux.x86_64.zip
          unzip Godot_v4.5.1-stable_linux.x86_64.zip
          chmod +x Godot_v4.5.1-stable_linux.x86_64

      - name: Run Tests
        run: |
          cd godot-project
          chmod +x addons/gdUnit4/runtest.sh
          addons/gdUnit4/runtest.sh \
            --godot_binary ../Godot_v4.5.1-stable_linux.x86_64 \
            --add test \
            --continue

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: godot-project/.godot/gdunit4/reports/
```

### GitLab CI Example

Create `.gitlab-ci.yml`:

```yaml
test:
  image: barichello/godot-ci:4.5.1
  stage: test
  script:
    - cd godot-project
    - chmod +x addons/gdUnit4/runtest.sh
    - addons/gdUnit4/runtest.sh --godot_binary /usr/local/bin/godot --add test --continue
  artifacts:
    when: always
    paths:
      - godot-project/.godot/gdunit4/reports/
```

---

## Troubleshooting

### "GdUnitTestCIRunner not found"

**Problem:** GdUnit4 plugin not properly enabled.

**Solution:**
```bash
# Ensure plugin is enabled in project.godot
[editor_plugins]
enabled=PackedStringArray("res://addons/gdUnit4/plugin.cfg")
```

### "Parse Error" in Test Files

**Problem:** Test code uses wrong GdUnit4 API.

**Solution:** Check API compatibility:
- `await_signal_on(obj, "signal", [], timeout)` - Note the `[]` for args
- `monitor_signals(obj)` - Plural, not singular
- `assert_vector(vec)` - Not `assert_vector2`
- `is_emitted("signal_name")` - Requires signal name

### Tests Hang or Timeout

**Problem:** Async operation not completing.

**Solution:**
```gdscript
# Increase timeout (default 2000ms)
await await_signal_on(obj, "signal", [], 5000)  # 5 seconds

# Or add timeout check
var result = await await_signal_on(obj, "signal", [], 1000)
if result == null:
    assert_bool(false).is_true("Signal timeout")
```

### "Cannot access object" Errors

**Problem:** Node not in scene tree.

**Solution:**
```gdscript
func before_test() -> void:
    my_node = auto_free(MyNode.new())
    add_child(my_node)  # IMPORTANT: Add to tree

    # Wait for _ready()
    await await_signal_on(my_node.get_tree(), "process_frame", [], 1000)
```

---

## Resources

- **GdUnit4 Documentation:** https://github.com/MikeSchulze/gdUnit4
- **GdUnit4 API Reference:** https://mikeschulze.github.io/gdUnit4/
- **Godot Testing Best Practices:** https://docs.godotengine.org/en/stable/tutorials/scripting/unit_testing.html

---

## Maintenance

### Updating GdUnit4

```bash
cd godot-project
rm -rf addons/gdUnit4
git clone https://github.com/MikeSchulze/gdUnit4.git temp_gdunit4
cp -r temp_gdunit4/addons/gdUnit4 addons/
rm -rf temp_gdunit4
```

### Adding New Test Suites

1. Create file in `test/` directory: `test_my_feature.gd`
2. Extend `GdUnitTestSuite`
3. Write test methods starting with `test_`
4. Run tests to verify

### Checking Test Coverage

Currently manual - review which files have corresponding test files.

**Tested:**
- ✅ game_engine.gd
- ✅ microgame_manager.gd
- ✅ microgame_base.gd
- ✅ ui_controller.gd
- ✅ click_circle.gd
- ✅ dodge_block.gd
- ✅ mash_key.gd

**Not Tested:**
- ⬜ dont_click.gd
- ⬜ drag_target.gd
- ⬜ catch_falling.gd

---

**Last Updated:** November 19, 2025
