class_name ToggleInteractable
extends Area3D


signal toggled(value: bool)


@export var anim_player: AnimationPlayer
@export var is_toggled := false:
	set(value):
		is_toggled = value
		toggled.emit(value)


func _ready() -> void:
	# Collision layers.
	set_collision_layer_value(GameObjects.physics_layers.WORLD, false)
	set_collision_layer_value(GameObjects.physics_layers.TOGGLE_INTERACTABLE, true)
	
	# Collision masks.
	GameObjects.set_default_collision_masks(self)


func toggle() -> void:
	if not anim_player:
		is_toggled = !is_toggled
		return
	
	if is_toggled:
		anim_player.play("toggle_off")
		is_toggled = false
	else:
		anim_player.play("toggle_on")
		is_toggled = true
