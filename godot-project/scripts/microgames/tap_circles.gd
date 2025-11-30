extends MicrogameBase

## Tap Circles - Tap all circles

var circles: Array[Area2D] = []
var tapped_count: int = 0
var required_count: int = 0
var counter_label: Label

func _define_difficulty_tiers() -> void:
	microgame_id = "tap_circles"
	microgame_name = "Tap Circles"
	instructions = "TAP ALL CIRCLES!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"circle_count": 3,
				"circle_size": 80.0
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"circle_count": 5,
				"circle_size": 60.0
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"circle_count": 7,
				"circle_size": 50.0
			}
		}
	]

func _setup_game() -> void:
	# Counter label
	counter_label = Label.new()
	counter_label.position = Vector2(600, 20)
	counter_label.add_theme_font_size_override("font_size", 32)
	add_child(counter_label)

func _on_game_start() -> void:
	# Clear old circles
	for circle in circles:
		if is_instance_valid(circle):
			circle.queue_free()
	circles.clear()

	tapped_count = 0
	required_count = current_parameters.circle_count
	_update_counter()

	# Create circles at random positions
	var circle_size = current_parameters.circle_size
	var margin = circle_size / 2 + 20

	for i in required_count:
		var circle = Area2D.new()
		circle.position = Vector2(
			randf_range(margin, 1280 - margin),
			randf_range(margin + 100, 720 - margin)
		)
		add_child(circle)

		# Visual
		var visual = ColorRect.new()
		visual.size = Vector2(circle_size, circle_size)
		visual.position = Vector2(-circle_size/2, -circle_size/2)
		visual.color = Color.ORANGE
		circle.add_child(visual)

		# Collision
		var collision = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = circle_size / 2
		collision.shape = circle_shape
		circle.add_child(collision)

		circle.input_pickable = true
		circle.input_event.connect(_on_circle_clicked.bind(circle))

		circles.append(circle)

func _on_circle_clicked(_viewport: Node, event: InputEvent, _shape_idx: int, circle: Area2D) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_active or has_completed:
			return

		# Mark circle as tapped
		if circles.has(circle):
			tapped_count += 1
			_update_counter()

			# Change color to show it was tapped
			for child in circle.get_children():
				if child is ColorRect:
					child.color = Color.GREEN

			# Remove from array
			circles.erase(circle)

			# Check win condition
			if tapped_count >= required_count:
				_win_game()

func _update_counter() -> void:
	counter_label.text = "%d / %d" % [tapped_count, required_count]
