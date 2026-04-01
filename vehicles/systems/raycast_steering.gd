class_name RayCastSteering
extends Node
# In charge of vehicle turning and steering.


@export_group("Variables")
@export var turn_sensitivity: float = 4.5
@export var max_turn_degrees: float = 40.0


var vehicle: Vehicle
var wheels: Array[RayCastWheel]
var previous_turn_direction: float = 0.0


func _physics_process(delta: float) -> void:
	for wheel in wheels:
		handle_wheel_turning(wheel, delta)
		handle_wheel_traction(wheel)
	previous_turn_direction = vehicle.turn_direction


func _ready() -> void:
	await get_parent().ready
	vehicle = get_parent() as Vehicle
	assert(vehicle != null)
	
	for wheel in vehicle.wheels: wheels.append(wheel)


func handle_wheel_traction(wheel: RayCastWheel) -> void:
	if not wheel.is_colliding(): return
	
	var right_side_direction := wheel.global_basis.x
	var point_velocity := wheel.get_point_velocity(wheel.mesh.global_position)
	var side_velocity := right_side_direction.dot(point_velocity)
	
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var wheel_weight: float = vehicle.mass * gravity / vehicle.num_of_wheels * 50
	
	var traction_force: Vector3 = -right_side_direction * side_velocity * wheel.traction * wheel_weight / 15
	
	# Wheel friction.
	var forward_direction := -wheel.global_basis.z
	var forward_velocity := -forward_direction.dot(point_velocity)
	var friction_force := forward_direction * forward_velocity * wheel.traction * wheel_weight / 5000
	
	var force_position_offset := wheel.mesh.global_position - vehicle.global_position
	vehicle.apply_force(traction_force, force_position_offset)
	vehicle.apply_force(friction_force, force_position_offset)


func handle_wheel_turning(wheel: RayCastWheel, delta: float) -> void:
	if not wheel.use_as_steering: return
	var rotation := wheel.rotation.y
	
	# If going in the opposite direction, quickly straighten wheel out.
	if vehicle.turn_direction != previous_turn_direction:
		if absf(rotation) < 0.1: wheel.rotation.y = 0.0
		else: wheel.rotation.y = lerpf(rotation, 0.0, turn_sensitivity * 5 * delta)
	
	# Straighten out if moving forward but no turn_direction.
	if not vehicle.turn_direction and vehicle.linear_velocity.length() > 0.05:
		if absf(rotation) < 0.02: wheel.rotation.y = 0.0
		else: wheel.rotation.y = lerpf(rotation, 0.0, turn_sensitivity * delta)
	
	# Decrease turn sensitivity as vehicle moves faster.
	var current_turn_sensitivty := turn_sensitivity
	if vehicle.linear_velocity.length() > 0: current_turn_sensitivty *= 1 / vehicle.linear_velocity.length()
	
	wheel.rotation.y = clampf(wheel.rotation.y + vehicle.turn_direction * current_turn_sensitivty * delta, deg_to_rad(-max_turn_degrees), deg_to_rad(max_turn_degrees))
