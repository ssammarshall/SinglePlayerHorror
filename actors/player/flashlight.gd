class_name Flashlight extends SpotLight3D

const FLASHLIGHT_FOCUS_SPEED := 3.0

@export_group("Light")
@export var range_max := 160.0
@export var range_min := 25.0

func _ready() -> void:
	spot_range = range_min

func toggle() -> void:
	visible = !visible

func focus(dir: int) -> void:
	if not (dir == 1 or dir == -1):
		printerr("flashlight.focus(dir: int): dir must equal 1 or -1")
		return
	
	var speed := FLASHLIGHT_FOCUS_SPEED * dir
	spot_range += speed
	if spot_range >= range_max or spot_range <= range_min:
		spot_range = clamp(spot_range, range_min, range_max)
		return
	
	spot_angle -= speed * 0.1
	spot_attenuation -= speed * 0.01
	light_energy += speed * 0.01
