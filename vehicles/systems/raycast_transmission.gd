class_name RayCastTransmission
extends Node
# In charge of vehicle accelerating and braking.


@export var acceleration_curve: Curve
@export_group("Variables")
@export var acceleration: float = 15.0
@export var max_speed: float = 30.0


var vehicle: Vehicle
var wheels: Array[RayCastWheel]


func _physics_process(delta: float) -> void:
	if vehicle.acceleration_direction:
		match vehicle.current_state:
			Vehicle.State.PARK:
				return
			Vehicle.State.DRIVE:
				if vehicle.acceleration_direction > 0: return # Applying brakes, not gas.
			Vehicle.State.NEUTRAL:
				return
			Vehicle.State.REVERSE:
				if vehicle.acceleration_direction < 0: return # Applying brakes, not gas.
	
	for wheel in wheels:
		handle_wheel_acceleration(wheel, delta)


func _ready() -> void:
	await get_parent().ready
	vehicle = get_parent() as Vehicle
	assert(vehicle != null)
	
	for wheel in vehicle.wheels: wheels.append(wheel)


func handle_wheel_acceleration(wheel: RayCastWheel, delta: float) -> void:
	# Rotate wheel mesh with wheel velocity.
	var forward_direction := -wheel.global_basis.z
	var wheel_velocity := forward_direction.dot(vehicle.linear_velocity)
	wheel.mesh.rotate_x(-wheel_velocity * delta / wheel.radius)
	
	if not wheel.is_colliding(): return # Wheel must be on ground to accelerate.
	
	var collision_point := wheel.mesh.global_position
	var position_offset := collision_point - vehicle.global_position
	
	# Calculate acceleration curve based on current speed ratio.
	var speed_ratio := wheel_velocity / max_speed
	var current_acceleration := acceleration_curve.sample_baked(speed_ratio) * acceleration * 100
	
	var acceleration_direction := Vector3.ZERO
	if vehicle.acceleration_direction:
		acceleration_direction = forward_direction * current_acceleration * vehicle.acceleration_direction
		if not wheel.use_as_traction: acceleration_direction *= 0.5 # Only wheels used as traction can apply acceleration. This small boost helps improve vehicle speeds during turns.
		elif vehicle.acceleration_direction > 0: acceleration_direction *= 0.5
	elif vehicle.current_speed > 1.0:
		var rolling_resistance := -signf(wheel_velocity) * absf(wheel_velocity)
		acceleration_direction = forward_direction * rolling_resistance
	
	# Accelerate in given direction.
	vehicle.apply_force(acceleration_direction, position_offset)
