class_name Dashboard
extends Sprite3D


var vehicle: Vehicle


@onready var speed_label: Label = $SubViewport/SpeedLabel


func _process(_delta: float) -> void:
	set_speed_display(vehicle.current_speed)


func _ready() -> void:
	await get_parent().ready
	vehicle = get_parent() as Vehicle
	assert(vehicle != null)


func set_speed_display(speed: float) -> void:
	var speed_text := str(snappedf(speed, 0.1)) + " kph"
	var vehicle_state := "P"
	match vehicle.current_state:
		Vehicle.State.DRIVE:
			vehicle_state = "D"
		Vehicle.State.NEUTRAL:
			vehicle_state = "N"
		Vehicle.State.REVERSE:
			vehicle_state = "R"
		
	
	speed_label.text = speed_text + " " + vehicle_state
