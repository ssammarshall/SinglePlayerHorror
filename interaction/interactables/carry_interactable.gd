class_name CarryInteractable extends RigidBody3D

var is_held := false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(Callable(_on_body_entered))
	
	set_collision_layer_value(4, true) # interactable layer

func manipulate(target: Vector3) -> void:
	if not is_held: return
	
	set_linear_velocity((target - global_position) * 10)

func drop() -> void:
	set_linear_velocity(linear_velocity / 2)
	is_held = false

func throw(direction: Vector3) -> void:
	apply_central_impulse(direction)
	is_held = false

func _on_body_entered(collision: Node3D) -> void:
	if linear_velocity.length() > 1.0: print(name + " bonked with " + collision.name + "!")
