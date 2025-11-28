extends MicrogameBase

## Hold mouse on target for required duration

var target: Area2D
var hold_duration: float = 2.0
var hold_time: float = 0.0
var is_holding: bool = false
var progress_bar: ColorRect
var progress_fill: ColorRect
var target_moves: bool = false

func _define_difficulty_tiers() -> void:
	microgame_id = "hold_button"
	microgame_name = "Hold Button"
	instructions = "HOLD IT!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"target_size": 150.0,
				"hold_duration": 2.0,
				"target_moves": false
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"target_size": 120.0,
				"hold_duration": 2.5,
				"target_moves": false
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"target_size": 100.0,
				"hold_duration": 2.5,
				"target_moves": true
			}
		}
	]

func _setup_game() -> void:
	pass

func _on_game_start() -> void:
	# Clear old target
	if is_instance_valid(target):
		target.queue_free()
	if is_instance_valid(progress_bar):
		progress_bar.queue_free()

	hold_time = 0.0
	is_holding = false
	hold_duration = current_parameters.hold_duration
	target_moves = current_parameters.target_moves

	var size = current_parameters.target_size

	# Create target
	target = Area2D.new()
	target.position = Vector2(640, 360)
	add_child(target)

	var visual = ColorRect.new()
	visual.size = Vector2(size, size)
	visual.position = Vector2(-size / 2, -size / 2)
	visual.color = Color.PURPLE
	target.add_child(visual)

	var label = Label.new()
	label.text = "HOLD"
	label.position = Vector2(-30, -15)
	label.add_theme_font_size_override("font_size", 24)
	target.add_child(label)

	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(size, size)
	collision.shape = rect_shape
	target.add_child(collision)

	# Create progress bar
	progress_bar = ColorRect.new()
	progress_bar.size = Vector2(200, 20)
	progress_bar.position = Vector2(540, 500)
	progress_bar.color = Color.DARK_GRAY
	add_child(progress_bar)

	progress_fill = ColorRect.new()
	progress_fill.size = Vector2(0, 20)
	progress_fill.position = Vector2(0, 0)
	progress_fill.color = Color.GREEN
	progress_bar.add_child(progress_fill)

func _update_game(delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()

	# Check if holding mouse button and over target
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _is_click_in_area(mouse_pos, target):
		is_holding = true
		hold_time += delta

		# Update progress bar
		var progress = clamp(hold_time / hold_duration, 0.0, 1.0)
		progress_fill.size.x = 200 * progress

		# Change target color
		var visual = target.get_child(0) as ColorRect
		visual.color = Color.YELLOW

		# Check if held long enough
		if hold_time >= hold_duration:
			_win_game()
	else:
		# Reset if mouse released or moved away
		if is_holding:
			hold_time = 0.0
			is_holding = false
			progress_fill.size.x = 0

			var visual = target.get_child(0) as ColorRect
			visual.color = Color.PURPLE

	# Move target if enabled
	if target_moves:
		var move_speed = 100.0
		var margin = current_parameters.target_size / 2 + 20
		target.position.x += sin(time_remaining * 2.0) * move_speed * delta
		target.position.y += cos(time_remaining * 3.0) * move_speed * delta

		# Keep in bounds
		target.position.x = clamp(target.position.x, margin, 1280 - margin)
		target.position.y = clamp(target.position.y, margin, 720 - margin)
