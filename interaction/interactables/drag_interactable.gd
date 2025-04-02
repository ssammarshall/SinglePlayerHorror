class_name DragInteractable extends RigidBody3D

@export var drag_speed: float = 10.0

@export_group("Constraints")
@export var lock_x := false
@export var locked_x_pos := 0.0
@export var lock_y := false
@export var locked_y_pos := 0.0
@export var lock_z := false
@export var locked_z_pos := 0.0

var is_held := false

func _ready() -> void:
	set_collision_layer_value(4, true) # interactable layer
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(Callable(_on_body_entered))

func _physics_process(_delta: float) -> void:
	if lock_z and position.z >= locked_z_pos: position.z = locked_z_pos # TODO: add other constraint properties.

func _on_body_entered(collision: Node) -> void:
	if linear_velocity.length() > 1.0: print(name + " bonked with " + collision.name + "!")

func manipulate(direction: Vector3) -> void:
	var force := direction.normalized() * drag_speed
	var apply := true
	
	# TODO: add other constraint properties.
	
	if lock_z:
		if position.z >= locked_z_pos:
			position.z = locked_z_pos
			apply = false
	
	if apply: apply_central_force(force)
