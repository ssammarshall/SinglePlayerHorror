class_name MapBlock
extends CSGBox3D
# Block to mimic the layout of a stage and provide data such as terrain type and
# navigation pathing, as well as provide visuals for smart map ui.


func _ready() -> void:
	var parent: Node3D = get_parent_node_3d()
	if parent is CSGBox3D:
		var box := parent as CSGBox3D
		size = box.size
	
	use_collision = true
	set_collision_layer_value(GameObjects.physics_layers.WORLD, false)
	set_collision_layer_value(GameObjects.physics_layers.MAP_BLOCK, true)
	set_collision_mask_value(GameObjects.physics_layers.WORLD, false)
	
	set_layer_mask_value(GameObjects.render_layers.WORLD, false)
	set_layer_mask_value(GameObjects.render_layers.MAP, true)
	print(get_layer_mask_value(GameObjects.render_layers.MAP))
