class_name Item extends RigidBody3D

@export var item_data: ItemData
@export var highlight_mesh: MeshInstance3D

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	set_collision_layer_value(2, true)
	highlight(false)

func highlight(value: bool) -> void:
	highlight_mesh.visible = value
