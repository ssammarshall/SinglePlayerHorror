class_name RayCastSuspension
extends Node
# In charge of vehicle suspension.


@export_group("Variables")
@export var ride_height: float = 0.5
@export var stiffness: float = 10000.0
@export var damping: float = 4500.0


var vehicle: Vehicle
var wheels: Array[RayCastWheel]


func _physics_process(_delta: float) -> void:
	for wheel in wheels:
		handle_wheel_suspension(wheel)


func _ready() -> void:
	await get_parent().ready
	vehicle = get_parent() as Vehicle
	assert(vehicle != null)
	
	for wheel in vehicle.wheels: wheels.append(wheel)


func handle_wheel_suspension(wheel: RayCastWheel) -> void:
	if not wheel.is_colliding(): return
	
	wheel.target_position.y = -(ride_height + wheel.radius + 0.15)
	
	var collision_point := wheel.get_collision_point()
	var up_direction := wheel.global_transform.basis.y
	var length := wheel.global_position.distance_to(collision_point) - wheel.radius
	var offset := ride_height - length
	
	wheel.set_height(-length)
	
	var point_velocity := wheel.get_point_velocity(collision_point)
	var relative_velocity := up_direction.dot(point_velocity)
	var damp_force := damping * relative_velocity
	
	var force := stiffness * offset
	var force_direction := (force - damp_force) * wheel.get_collision_normal()
	
	var force_position_offset := wheel.mesh.global_position - vehicle.global_position
	vehicle.apply_force(force_direction, force_position_offset)
