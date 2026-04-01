class_name Lock
extends ToggleInteractable


@export var key_id: int = 12345


func is_key_side(user_pos: Vector3) -> bool:
	# The side with the lock lever that can be freely toggled.
	var lever_side := global_position - global_transform.basis.z
	var distance_to_lever := lever_side - user_pos
	# The side with the key hole that requires a key to open if locked.
	var key_hole_side := global_position + global_transform.basis.z
	var distance_to_key_hole := key_hole_side - user_pos
	
	if distance_to_lever.length() < distance_to_key_hole.length(): # Lever side.
		return false
	else: # Key hole side.
		return true
	
