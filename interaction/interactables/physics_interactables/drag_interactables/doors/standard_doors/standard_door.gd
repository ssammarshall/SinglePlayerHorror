class_name StandardDoor
extends Door
# Door with a hinge connecting a door frame
# and a door panel that can be pushed/pulled.


@export var hinge: HingeJoint3D
@export_range(0.0, 90.0, 0.1) var upper_angular_limit := 90.0
@export_range(-90.0, 0.0, 0.1) var lower_angular_limit := -90.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if door_panel.is_held: # Door can be moved when being interacted with.
		door_panel.freeze = false
	elif is_closed: # Door does not move if closed and has no current interactions.
		door_panel.freeze = true


func _ready() -> void:
	super._ready()


func on_lock_toggled(locked: bool) -> void:
	super.on_lock_toggled(locked)
	
	if is_locked and is_closed: # Door cannot be opened when locked and closed.
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 0.01)
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0.0)
	elif is_locked: # Door cannot close all the way if locked and already opened.
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(upper_angular_limit))
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, 0.05)
	else: # Unlocked.
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, deg_to_rad(upper_angular_limit))
		hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, deg_to_rad(lower_angular_limit))
