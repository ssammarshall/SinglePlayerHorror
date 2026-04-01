@tool
class_name Flashlight
extends SpotLight3D
# Light used by player.


const FLASHLIGHT_FOCUS_SPEED := 5.0


@export_group("Light")
@export var range_max := 160.0
@export var range_min := 25.0
@export var strength := 6.0


func _process(_delta: float) -> void:
	light_energy = strength


func _ready() -> void:
	spot_range = range_min


# Focus in beam of light or expand it.
func focus(direction: int) -> void:
	var speed := FLASHLIGHT_FOCUS_SPEED * direction
	spot_range += speed
	if spot_range >= range_max or spot_range <= range_min:
		spot_range = clamp(spot_range, range_min, range_max)
		return
	
	spot_angle -= speed * 0.1
	spot_attenuation -= speed * 0.01
	strength += speed * 0.01


# Toggle visibility/power.
func toggle() -> void:
	visible = not visible
