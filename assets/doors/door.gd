class_name Door extends Node3D

@export var door_panel: DragInteractable
@export var door_frame: StaticBody3D
@export var hinge: HingeJoint3D
@export var lock: ToggleInteractable
@export var strike_plate: Area3D

@export_range(0.0, 90.0, 0.1) var upper_angular_limit := 90.0
@export_range(-90.0, 0.0, 0.1) var lower_angular_limit := -90.0

var is_closed := false
var is_locked := false

func _ready() -> void:
	door_panel.set_freeze_mode(RigidBody3D.FREEZE_MODE_KINEMATIC)
	lock.toggled.connect(Callable(_on_lock_toggled))

func _physics_process(_delta: float) -> void:
	if strike_plate.overlaps_body(door_panel): is_closed = true
	else: is_closed = false
	
	if door_panel.is_held: # Door can be moved when being interacted with.
		door_panel.freeze = false
	elif is_closed: # Door does not move if closed and has no current interactions.
		door_panel.freeze = true

func _on_lock_toggled(value: bool) -> void:
	is_locked = value
	
	if is_locked and is_closed:
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0.01)
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0.0)
	elif is_locked: # Door cannot close all the way if locked and already opened.
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(upper_angular_limit))
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0.05)
	else: # Unlocked.
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(upper_angular_limit))
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(lower_angular_limit))
