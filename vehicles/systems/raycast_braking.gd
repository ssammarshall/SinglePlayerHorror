class_name RayCastBraking
extends Node
# In charge of vehicle brakes.


@export_group("Variables")
@export var brake_strength: float = 12.0


var vehicle: Vehicle
var wheels: Array[RayCastWheel]
var is_standard_braking := false


func _physics_process(_delta: float) -> void:
	var forward_speed := -vehicle.global_transform.basis.z.dot(vehicle.linear_velocity)
	
	# If no direction input from vehicle or vehicle is not moving, stop standard braking.
	if not vehicle.acceleration_direction or absf(forward_speed) < 0.1: is_standard_braking = false
	# If direction input is in opposite direction of current_speed, vehicle is standard braking.
	elif signf(vehicle.acceleration_direction) != signf(forward_speed): is_standard_braking = true
	else: is_standard_braking = false
	
	for wheel in wheels:
		var brake_multiplier := 1.0
		if vehicle.is_using_parking_brake: brake_multiplier = 1.5 # Stronger brakes when parked.
		elif not is_standard_braking: return # Do not apply brakes.
		
		handle_wheel_braking(wheel, brake_multiplier)


func _ready() -> void:
	await get_parent().ready
	vehicle = get_parent() as Vehicle
	assert(vehicle != null)
	
	for wheel in vehicle.wheels:
		wheels.append(wheel)


func handle_wheel_braking(wheel: RayCastWheel, multiplier: float = 1.0) -> void:
	if not wheel.is_colliding(): return
	
	var forward_direction := -wheel.global_basis.z
	var point_velocity := wheel.get_point_velocity(wheel.mesh.global_position)
	var forward_velocity := forward_direction.dot(point_velocity)
	
	if absf(forward_velocity) < 0.05: return
	
	var magnitude := brake_strength * signf(forward_velocity)
	var brake_force := -forward_direction * magnitude
	
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var wheel_weight: float = vehicle.mass * gravity / vehicle.num_of_wheels * 50
	brake_force *= wheel.traction * (wheel_weight / 1000) * multiplier
	
	var offset := wheel.mesh.global_position - vehicle.global_position
	vehicle.apply_force(brake_force, offset)
