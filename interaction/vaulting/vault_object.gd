class_name VaultObject
extends CSGBox3D
# Object that actors can vault over to cross.


@export var enabled := true
@export var side_1: Marker3D
@export var side_2: Marker3D
@export var vault_distance: float = 2.5


func _ready() -> void:
	use_collision = true
	
	set_collision_layer_value(GameObjects.physics_layers.VAULT_OBJECT, true)


func get_vault_direction(user_pos: Vector3) -> Vector3:
	var dir_1 := global_position - side_1.global_position
	var side_1_dist := side_1.global_position - user_pos
	
	var dir_2 := global_position - side_2.global_position
	var side_2_dist := side_2.global_position - user_pos
	
	var direction := dir_1 if side_1_dist.length() < side_2_dist.length() else dir_2
	
	return direction.normalized() * vault_distance
