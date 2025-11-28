extends MicrogameBase

## Drag to Target Microgame
## Objective: Drag the object to the target zone
## Difficulty: Smaller target, longer distance, moving target at higher tiers

var draggable: Area2D
var target: Area2D
var is_dragging: bool = false
var has_won: bool = false
var target_size: float = 0.0
var is_moving_target: bool = false
var target_velocity: Vector2 = Vector2.ZERO


func _define_difficulty_tiers() -> void:
	microgame_id = "drag_target"
	microgame_name = "Drag to Target"
	instructions = "DRAG!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"target_size": 150.0,
				"target_distance": 200.0,
				"moving": false
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"target_size": 100.0,
				"target_distance": 300.0,
				"moving": false
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"target_size": 70.0,
				"target_distance": 350.0,
				"moving": false
			}
		},
		{
			"tier": 4,
			"time_limit": 2.5,
			"parameters": {
				"target_size": 50.0,
				"target_distance": 250.0,
				"moving": true
			}
		}
	]


func _setup_game() -> void:
	# Create instruction
	var instruction = Label.new()
	instruction.text = "DRAG TO TARGET!"
	instruction.position = Vector2(480, 50)
	instruction.add_theme_font_size_override("font_size", 40)
	add_child(instruction)

	# Create target
	target = Area2D.new()
	target.position = Vector2(640, 360)

	var target_collision = CollisionShape2D.new()
	var target_shape = CircleShape2D.new()
	target_collision.shape = target_shape
	target.add_child(target_collision)

	var target_sprite = ColorRect.new()
	target_sprite.color = Color(0.18, 0.8, 0.44, 0.3)
	target.add_child(target_sprite)

	add_child(target)

	# Create draggable
	draggable = Area2D.new()
	draggable.input_pickable = true
	draggable.position = Vector2(400, 360)

	var drag_collision = CollisionShape2D.new()
	var drag_shape = CircleShape2D.new()
	drag_shape.radius = 30
	drag_collision.shape = drag_shape
	draggable.add_child(drag_collision)

	var drag_sprite = ColorRect.new()
	drag_sprite.color = Color.DODGER_BLUE
	drag_sprite.position = Vector2(-30, -30)
	drag_sprite.size = Vector2(60, 60)
	drag_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block Area2D input
	draggable.add_child(drag_sprite)

	draggable.input_event.connect(_on_draggable_input)
	draggable.area_entered.connect(_on_draggable_entered_target)

	add_child(draggable)


func _on_game_start() -> void:
	has_won = false
	is_dragging = false
	target_size = current_parameters.target_size
	is_moving_target = current_parameters.moving

	# Position target
	var distance = current_parameters.target_distance
	target.position = Vector2(640 + distance, 360)

	# Update target size
	var target_collision = target.get_child(0) as CollisionShape2D
	var target_shape = target_collision.shape as CircleShape2D
	target_shape.radius = target_size / 2.0

	var target_sprite = target.get_child(1) as ColorRect
	target_sprite.position = Vector2(-target_size / 2, -target_size / 2)
	target_sprite.size = Vector2(target_size, target_size)

	if is_moving_target:
		target_velocity = Vector2(150, 100)


func _update_game(delta: float) -> void:
	# Move target if applicable
	if is_moving_target:
		target.position += target_velocity * delta

		# Bounce
		if target.position.x < target_size / 2 or target.position.x > 1280 - target_size / 2:
			target_velocity.x *= -1
		if target.position.y < target_size / 2 or target.position.y > 720 - target_size / 2:
			target_velocity.y *= -1

	# Update dragging
	if is_dragging:
		var mouse_pos = get_viewport().get_mouse_position()
		draggable.position = mouse_pos


func _on_draggable_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = true
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = false


func _on_draggable_entered_target(_area: Area2D) -> void:
	if not has_won and is_active:
		has_won = true
		var target_sprite = target.get_child(1) as ColorRect
		target_sprite.color = Color(0.18, 0.8, 0.44, 0.8)
		_win_game()
