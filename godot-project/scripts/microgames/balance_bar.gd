extends MicrogameBase

## Balance Bar Microgame
## Objective: Keep the bar balanced by pressing left/right keys
## Difficulty: Faster tilt, longer duration at higher tiers

var balance: float = 0.0  # -1 (left) to 1 (right)
var tilt_speed: float = 0.5
var bar: Node2D
var indicator: ColorRect


func _define_difficulty_tiers() -> void:
	microgame_id = "balance_bar"
	microgame_name = "Balance Bar"
	instructions = "BALANCE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"tilt_speed": 0.4,
				"max_tilt": 0.8
			}
		},
		{
			"tier": 2,
			"time_limit": 5.0,
			"parameters": {
				"tilt_speed": 0.5,
				"max_tilt": 0.7
			}
		},
		{
			"tier": 3,
			"time_limit": 6.0,
			"parameters": {
				"tilt_speed": 0.6,
				"max_tilt": 0.6
			}
		},
		{
			"tier": 4,
			"time_limit": 7.0,
			"parameters": {
				"tilt_speed": 0.7,
				"max_tilt": 0.5
			}
		}
	]


func _setup_game() -> void:
	# Create instruction
	var instruction = Label.new()
	instruction.text = "BALANCE!"
	instruction.position = Vector2(540, 100)
	instruction.add_theme_font_size_override("font_size", 48)
	add_child(instruction)

	# Create bar pivot
	bar = Node2D.new()
	bar.position = Vector2(640, 360)
	add_child(bar)

	# Create bar visual
	var bar_rect = ColorRect.new()
	bar_rect.color = Color.GRAY
	bar_rect.size = Vector2(400, 20)
	bar_rect.position = Vector2(-200, -10)
	bar.add_child(bar_rect)

	# Create left weight
	var left_weight = ColorRect.new()
	left_weight.color = Color.DARK_BLUE
	left_weight.size = Vector2(40, 60)
	left_weight.position = Vector2(-220, -30)
	bar.add_child(left_weight)

	# Create right weight
	var right_weight = ColorRect.new()
	right_weight.color = Color.DARK_RED
	right_weight.size = Vector2(40, 60)
	right_weight.position = Vector2(180, -30)
	bar.add_child(right_weight)

	# Create center post
	var post = ColorRect.new()
	post.color = Color.WHITE
	post.size = Vector2(10, 100)
	post.position = Vector2(635, 360)
	add_child(post)

	# Create balance indicator
	indicator = ColorRect.new()
	indicator.color = Color.GREEN
	indicator.size = Vector2(20, 40)
	indicator.position = Vector2(630, 500)
	add_child(indicator)

	# Create safe zone indicator
	var safe_zone = ColorRect.new()
	safe_zone.color = Color(0, 1, 0, 0.3)
	safe_zone.size = Vector2(200, 60)
	safe_zone.position = Vector2(540, 490)
	add_child(safe_zone)


func _on_game_start() -> void:
	balance = randf_range(-0.3, 0.3)  # Start slightly off-balance
	tilt_speed = current_parameters.tilt_speed


# Override _process to make timeout = win (survival game)
func _process(delta: float) -> void:
	if not is_active or has_completed:
		return

	# Update timer
	time_remaining -= delta

	# Win if survived the duration
	if time_remaining <= 0:
		_win_game()
		return

	# Update game-specific logic
	_update_game(delta)


func _update_game(delta: float) -> void:
	# Natural tilt based on current balance
	var tilt_direction = sign(balance)
	balance += tilt_direction * tilt_speed * delta

	# Handle player input
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		balance -= 1.5 * delta
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		balance += 1.5 * delta

	# Clamp balance
	balance = clampf(balance, -1.0, 1.0)

	# Update bar rotation
	if bar:
		bar.rotation = balance * 0.5  # Max 28 degrees

	# Update indicator position
	if indicator:
		indicator.position.x = 630 + (balance * 100)

		# Color based on balance
		var max_tilt = current_parameters.max_tilt
		if abs(balance) > max_tilt:
			indicator.color = Color.RED
		else:
			indicator.color = Color.GREEN

	# Check fail condition
	var max_tilt = current_parameters.max_tilt
	if abs(balance) > max_tilt:
		_lose_game()
