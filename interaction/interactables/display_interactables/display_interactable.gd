class_name DisplayInteractable
extends Area3D


@export var display: Display
@export var focus_marker: Marker3D # Marker for a CameraRig to match position and rotation.


func _ready() -> void:
	# Collision layers.
	set_collision_layer_value(GameObjects.physics_layers.WORLD, false)
	set_collision_layer_value(GameObjects.physics_layers.DISPLAY_INTERACTABLE, true)
	
	# Collision masks.
	GameObjects.set_default_collision_masks(self)
