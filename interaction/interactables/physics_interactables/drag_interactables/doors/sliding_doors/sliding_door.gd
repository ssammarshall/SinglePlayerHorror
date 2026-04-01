class_name SlidingDoor
extends Door


enum State {
	CLOSED,
	LOCKED_OPEN,
	OPEN,
}


@export var slide_joint: Generic6DOFJoint3D
@export var sliding_lock: Area3D


var current_state := State.CLOSED:
	set(new_state):
		current_state = new_state
		match current_state:
			State.CLOSED:
				slide_joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR, true)
				slide_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_MOTOR_FORCE_LIMIT, 5000)
				slide_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, upper_limit)
				slide_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, upper_limit)
			State.LOCKED_OPEN:
				slide_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, lower_limit)
				slide_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lower_limit)
			State.OPEN:
				slide_joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_MOTOR, false)
				slide_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, upper_limit)
				slide_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lower_limit)
var lower_limit := 0.0
var is_fully_open := false
var is_using_sliding_lock := false
var upper_limit := 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if not door_panel.is_held: update_current_state()


func _ready() -> void:
	super._ready()
	
	if sliding_lock:
		sliding_lock.set_collision_mask_value(GameObjects.physics_layers.PHYSICS_INTERACTABLE, true)
		is_using_sliding_lock = true
	
	lower_limit = slide_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT)
	upper_limit = slide_joint.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT)


func on_door_held(held: bool) -> void:
	if held: current_state = State.OPEN
	else: update_current_state()


func update_current_state() -> void:
	var new_state: State
	if strike_plate.overlaps_body(door_panel): # If door is closed and not being held, keep the door closed.
		new_state = State.CLOSED
	elif is_using_sliding_lock and sliding_lock.overlaps_body(door_panel): # If using a sliding lock to lock door when fully open.
		new_state = State.LOCKED_OPEN
	else: # Door is open and forces can be applied freely.
		new_state = State.OPEN
	
	if new_state != current_state: current_state = new_state
