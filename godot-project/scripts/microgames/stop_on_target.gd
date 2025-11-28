extends MicrogameBase

## Click when the sweeping line is in the green zone

var sweep_line: ColorRect
var green_zone: ColorRect
var sweep_angle: float = 0.0
var sweep_speed: float = 180.0  # degrees per second
var zone_start: float = 0.0
var zone_size: float = 90.0
var center_pos: Vector2 = Vector2(640, 360)
var radius: float = 200.0

func _define_difficulty_tiers() -> void:
	microgame_id = "stop_on_target"
	microgame_name = "Stop on Target"
	instructions = "STOP IN ZONE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"sweep_speed": 120.0,  # degrees per second
				"zone_percentage": 0.4  # 40% of circle
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"sweep_speed": 180.0,
				"zone_percentage": 0.25
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"sweep_speed": 240.0,
				"zone_percentage": 0.15
			}
		}
	]

func _setup_game() -> void:
	# Create circular background
	var background = ColorRect.new()
	background.size = Vector2(radius * 2, radius * 2)
	background.position = center_pos - Vector2(radius, radius)
	background.color = Color(0.2, 0.2, 0.2)
	add_child(background)

	# Create green zone (simplified as rectangle for now)
	green_zone = ColorRect.new()
	green_zone.color = Color.GREEN
	add_child(green_zone)

	# Create sweep line
	sweep_line = ColorRect.new()
	sweep_line.size = Vector2(5, radius)
	sweep_line.position = center_pos
	sweep_line.color = Color.WHITE
	add_child(sweep_line)

func _on_game_start() -> void:
	sweep_angle = 0.0
	sweep_speed = current_parameters.sweep_speed

	# Set zone size and random position
	zone_size = 360.0 * current_parameters.zone_percentage
	zone_start = randf_range(0.0, 360.0 - zone_size)

	# Update green zone visualization (simplified)
	var zone_mid = zone_start + zone_size / 2
	var zone_rad = deg_to_rad(zone_mid)
	green_zone.size = Vector2(radius * 0.8, 40)
	green_zone.position = center_pos + Vector2(cos(zone_rad), sin(zone_rad)) * radius * 0.5 - green_zone.size / 2

func _update_game(delta: float) -> void:
	# Update sweep angle
	sweep_angle += sweep_speed * delta
	if sweep_angle >= 360.0:
		sweep_angle -= 360.0

	# Update sweep line rotation
	sweep_line.rotation = deg_to_rad(sweep_angle)

func _input(event: InputEvent) -> void:
	if not is_active or has_completed:
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Check if sweep line is in green zone
			var in_zone = false
			if zone_start <= sweep_angle and sweep_angle <= zone_start + zone_size:
				in_zone = true

			if in_zone:
				_win_game()
			else:
				_lose_game()
