class_name Lock extends ToggleInteractable

@export var key_id: int = 12345

func is_key_side(user_pos: Vector3) -> bool:
	# The side with the lock handle that can be freely toggled.
	var handle_side := global_position - global_transform.basis.z
	var distance_to_handle := handle_side - user_pos
	# The side with the key hole that requires a key to open.
	var key_side := global_position + global_transform.basis.z
	var distance_to_key_hole := key_side - user_pos
	
	if distance_to_handle.length() < distance_to_key_hole.length(): # Handle side.
		return false
	else:
		return true
	
