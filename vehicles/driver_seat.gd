class_name DriverSeat
extends Area3D


var vehicle: Vehicle


func _ready() -> void:
	await get_parent().ready
	vehicle = get_parent() as Vehicle
	assert(vehicle != null)
