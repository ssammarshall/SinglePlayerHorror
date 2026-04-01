class_name CarryInteractable
extends PhysicsInteractable
# Object that can be picked up, dropped and thrown.


func _ready() -> void:
	super._ready()
	
	angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	angular_damp = 1.0


func drop() -> void:
	set_linear_velocity(linear_velocity / 2)
	is_held = false


func manipulate(direction: Vector3) -> void:
	if not is_held: return
	
	set_linear_velocity((direction - global_position) * 10)


func throw(direction: Vector3) -> void:
	apply_central_impulse(direction)
	is_held = false
