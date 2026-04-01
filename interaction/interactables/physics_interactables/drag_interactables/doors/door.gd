class_name Door
extends Node3D


@export var door_panel: DragInteractable
@export var lock: Lock # Optional.
@export var strike_plate: Area3D


var is_closed := false
var is_locked := false


func _physics_process(_delta: float) -> void:
	if strike_plate.overlaps_body(door_panel): is_closed = true
	else: is_closed = false


func _ready() -> void:
	door_panel.is_held_changed.connect(Callable(on_door_held))
	door_panel.set_freeze_mode(RigidBody3D.FREEZE_MODE_KINEMATIC)
	
	if lock: lock.toggled.connect(Callable(on_lock_toggled))
	
	
	strike_plate.set_collision_mask_value(GameObjects.physics_layers.PHYSICS_INTERACTABLE, true)


func on_door_held(_held: bool) -> void:
	pass


func on_lock_toggled(locked: bool) -> void:
	is_locked = locked
