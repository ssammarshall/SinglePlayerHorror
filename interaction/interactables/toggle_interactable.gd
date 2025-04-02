class_name ToggleInteractable extends Area3D

@export var anim_player: AnimationPlayer

signal toggled(value: bool)
@export var is_toggled := false:
	set(value):
		is_toggled = value
		toggled.emit(value)

func _ready() -> void:
	set_collision_layer_value(4, true) # interactable layer

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
