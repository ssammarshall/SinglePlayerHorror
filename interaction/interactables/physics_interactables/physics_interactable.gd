@abstract
class_name PhysicsInteractable
extends RigidBody3D
# Interactable object that can be moved and manipulated.


signal is_held_changed(held: bool)


var is_held := false


func _ready() -> void:
	# Monitor collisions.
	contact_monitor = true
	max_contacts_reported = 1
	
	# Collision layers.
	set_collision_layer_value(GameObjects.physics_layers.WORLD, false)
	set_collision_layer_value(GameObjects.physics_layers.PHYSICS_INTERACTABLE, true)
	
	# Collision masks.
	GameObjects.set_default_collision_masks(self)
	
	# Connect RigidBody3D signals.
	body_entered.connect(Callable(on_body_entered))


func hold(is_holding: bool) -> void:
	var emit := false
	if is_held != is_holding: emit = true
	is_held = is_holding
	if emit: is_held_changed.emit(is_held)


func manipulate(_direction: Vector3) -> void:
	pass


func on_body_entered(collision: Node3D) -> void:
	if linear_velocity.length() > 1.0: print(name + " bonked with " + collision.name + "!")
