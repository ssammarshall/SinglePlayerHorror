extends Node3D


@export var camera: Camera3D


func _ready() -> void:
	camera.set_cull_mask_value(GameObjects.render_layers.WORLD, false)
	camera.set_cull_mask_value(GameObjects.render_layers.LIGHT_DETECTION, false)
	camera.set_cull_mask_value(GameObjects.render_layers.MAP, true)
	print(camera.get_cull_mask_value(GameObjects.render_layers.MAP))
