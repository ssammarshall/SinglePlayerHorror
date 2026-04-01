class_name RayCastWheel
extends RayCast3D


@export_group("Variables")
@export var use_as_steering: bool = false
@export var use_as_traction: bool = true
@export var radius: float = 0.4
@export var traction: float = 1.0


var vehicle: Vehicle


@onready var mesh: MeshInstance3D = $MeshInstance3D


func _physics_process(_delta: float) -> void:
	force_raycast_update()


func _ready() -> void:
	await get_parent().ready
	vehicle = get_parent() as Vehicle
	assert(vehicle != null)
	
	add_exception(vehicle)
	enabled = false


func get_point_velocity(point: Vector3) -> Vector3:
	return vehicle.linear_velocity + vehicle.angular_velocity.cross(point - vehicle.global_position)


func set_height(y: float) -> void:
	mesh.position.y = y
