class_name TouchScreenConsole
extends DisplayInteractable


@export var overview_camera_rig: Node3D
@export var map_camera_rig: Node3D
@export var touch_screen_display: TouchScreenDisplay


func _physics_process(_delta: float) -> void:
	overview_camera_rig.global_position = global_position
	overview_camera_rig.global_rotation.y = global_rotation.y
	
	map_camera_rig.global_position = global_position
	map_camera_rig.global_rotation.y = global_rotation.y


func _ready() -> void:
	super._ready()
