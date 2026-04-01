extends Node

enum physics_layers {
	NONE, # Cannot set collision layer/mask to 0.
	WORLD,
	ITEM,
	PHYSICS_INTERACTABLE,
	TOGGLE_INTERACTABLE,
	DISPLAY_INTERACTABLE,
	ACTOR,
	VEHICLE,
	VAULT_OBJECT,
	MAP_BLOCK
}


enum render_layers {
	NONE, # Cannot set collision layer/mask to 0.
	WORLD,
	LIGHT_DETECTION,
	MAP
}


# Set collision masks of a CollisionObject3D to the game's currently used physics layers.
func set_default_collision_masks(collision_object: CollisionObject3D) -> void:
	collision_object.set_collision_mask_value(physics_layers.WORLD, true)
	#collision_object.set_collision_mask_value(physics_layers.ITEM, true)
	collision_object.set_collision_mask_value(physics_layers.PHYSICS_INTERACTABLE, true)
	collision_object.set_collision_mask_value(physics_layers.TOGGLE_INTERACTABLE, true)
	collision_object.set_collision_mask_value(physics_layers.DISPLAY_INTERACTABLE, true)
	collision_object.set_collision_mask_value(physics_layers.ACTOR, true)
	collision_object.set_collision_mask_value(physics_layers.VEHICLE, true)
