class_name Item
extends RigidBody3D
# Objects that can be added to inventory to be used by an actor.


@export var item_data: ItemData
@export var highlight_mesh: MeshInstance3D


@onready var collision_shape: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	# Collision layers.
	set_collision_layer_value(GameObjects.physics_layers.WORLD, false)
	set_collision_layer_value(GameObjects.physics_layers.ITEM, true)
	
	# Collision masks.
	GameObjects.set_default_collision_masks(self)
	
	highlight(false)


func highlight(value: bool) -> void:
	highlight_mesh.visible = value
