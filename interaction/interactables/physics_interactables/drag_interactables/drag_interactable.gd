class_name DragInteractable
extends PhysicsInteractable
# Object that can be pushed or pulled.


@export var drag_speed: float = 10.0
@export_group("Position Limits")
@export var limit_x := false
@export var limited_x_max_pos := 0.0
@export var limited_x_min_pos := 0.0
@export var limit_y := false
@export var limited_y_max_pos := 0.0
@export var limited_y_min_pos := 0.0
@export var limit_z := false
@export var limited_z_max_pos := 0.0
@export var limited_z_min_pos := 0.0


func _physics_process(_delta: float) -> void:
	if limit_x:
		if position.x > limited_x_max_pos: position.x = limited_x_max_pos
		elif position.x < limited_x_min_pos: position.x = limited_x_min_pos
	if limit_y:
		if position.y > limited_y_max_pos: position.y = limited_y_max_pos
		elif position.y < limited_y_min_pos: position.y = limited_y_min_pos
	if limit_z:
		if position.z > limited_z_max_pos: position.z = limited_z_max_pos
		elif position.z < limited_z_min_pos: position.z = limited_z_min_pos


func _ready() -> void:
	super._ready()


func manipulate(direction: Vector3) -> void:
	var force := direction.normalized() * drag_speed
	var apply := true
	
	if limit_x:
		if position.x > limited_x_max_pos:
			position.x = limited_x_max_pos
			apply = false
		elif position.x < limited_x_min_pos:
			position.x = limited_x_min_pos
			apply = false
	if limit_y:
		if position.y > limited_y_max_pos:
			position.y = limited_y_max_pos
			apply = false
		elif position.y < limited_y_min_pos:
			position.y = limited_y_min_pos
			apply = false
	if limit_z:
		if position.z > limited_z_max_pos:
			position.z = limited_z_max_pos
			apply = false
		elif position.z < limited_z_min_pos:
			position.z = limited_z_min_pos
			apply = false
	
	if apply:
		apply_central_force(force)
