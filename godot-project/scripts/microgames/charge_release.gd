extends MicrogameBase

## Hold to charge, release in green zone

var charge_bar: ColorRect
var charge_fill: ColorRect
var green_zone: ColorRect
var charge_amount: float = 0.0
var charge_speed: float = 0.5
var is_charging: bool = false
var has_released: bool = false

func _define_difficulty_tiers() -> void:
	microgame_id = "charge_release"
	microgame_name = "Charge Release"
	instructions = "CHARGE & RELEASE!"

	difficulty_tiers = [
		{
			"tier": 1,
			"time_limit": 4.0,
			"parameters": {
				"charge_speed": 0.4,
				"zone_start": 0.25,
				"zone_size": 0.50
			}
		},
		{
			"tier": 2,
			"time_limit": 3.5,
			"parameters": {
				"charge_speed": 0.5,
				"zone_start": 0.35,
				"zone_size": 0.30
			}
		},
		{
			"tier": 3,
			"time_limit": 3.0,
			"parameters": {
				"charge_speed": 0.6,
				"zone_start": 0.425,
				"zone_size": 0.15
			}
		}
	]

func _setup_game() -> void:
	# Create charge bar background
	charge_bar = ColorRect.new()
	charge_bar.size = Vector2(600, 80)
	charge_bar.position = Vector2(340, 320)
	charge_bar.color = Color.DARK_GRAY
	add_child(charge_bar)

	# Create charge fill
	charge_fill = ColorRect.new()
	charge_fill.size = Vector2(0, 80)
	charge_fill.position = Vector2(0, 0)
	charge_fill.color = Color.BLUE
	charge_bar.add_child(charge_fill)

	# Create green zone
	green_zone = ColorRect.new()
	green_zone.color = Color(0.0, 0.8, 0.0, 0.4)
	charge_bar.add_child(green_zone)

	# Add instruction label
	var label = Label.new()
	label.text = "Hold mouse to charge, release in green zone!"
	label.position = Vector2(280, 250)
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)

func _on_game_start() -> void:
	charge_amount = 0.0
	is_charging = false
	has_released = false
	charge_speed = current_parameters.charge_speed

	charge_fill.size.x = 0

	# Position green zone
	var zone_start = current_parameters.zone_start
	var zone_size = current_parameters.zone_size

	green_zone.position.x = 600 * zone_start
	green_zone.size = Vector2(600 * zone_size, 80)

func _update_game(delta: float) -> void:
	if has_released:
		return

	# Check if mouse button is held
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_charging = true
		charge_amount += charge_speed * delta

		# Loop back if over 100%
		if charge_amount > 1.0:
			charge_amount = 0.0

		# Update visual
		charge_fill.size.x = 600 * charge_amount

		# Change color based on zone
		if _is_in_green_zone():
			charge_fill.color = Color.GREEN
		else:
			charge_fill.color = Color.BLUE
	else:
		# Mouse released
		if is_charging:
			has_released = true

			if _is_in_green_zone():
				_win_game()
			else:
				_lose_game()

func _is_in_green_zone() -> bool:
	var zone_start = current_parameters.zone_start
	var zone_end = zone_start + current_parameters.zone_size

	return charge_amount >= zone_start and charge_amount <= zone_end
