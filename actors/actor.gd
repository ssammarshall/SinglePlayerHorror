class_name Actor
extends RigidBody3D
# CharacterBody3D recreated to allow correct collision interaction between
# actors and objects in the world. Uses different handlers for movement and detection.


signal crouch_pressed
signal enter_vehicle(vehicle: Vehicle)
signal exit_vehicle(vehicle: Vehicle)
signal jump_pressed
signal movement_restricted(is_restricted: bool, area: RestrictedMovementArea)
signal state_changed(new_state: State, prev_state: State)


enum State {
	STANDING,
	CROUCHING,
	DRIVING,
	TRANSITIONING
}


@export var mesh: Node3D
@export var standing_collision: CollisionShape3D
@export var crouching_collision: CollisionShape3D
@export var movement_handler: MovementHandler
@export var light_detection_handler: LightDetectionHandler


var current_state := State.STANDING:
	set(new_state):
		if current_state == new_state: return
		if current_state == State.STANDING or current_state == State.CROUCHING:
			prev_state = current_state # Only keep track of previous state if it was standing or crouching.
		current_state = new_state
		
		match current_state:
			State.STANDING:
				standing_collision.disabled = false
				crouching_collision.disabled = true
			State.CROUCHING:
				standing_collision.disabled = true
				crouching_collision.disabled = false
			State.DRIVING: # TODO: check if necessary
				standing_collision.disabled = true
				crouching_collision.disabled = true
			State.TRANSITIONING:
				rotation_y_direction = 0.0
		
		state_changed.emit(current_state, prev_state)
var detection_level: float:
	get():
		return light_detection_handler.light_level
var is_crouched: bool:
	get(): return current_state == State.CROUCHING
var movement_direction := Vector3.ZERO
var prev_state: State
var rotation_y_direction := 0.0


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	movement_handler.handle_physics_state(state)


func _physics_process(_delta: float) -> void:
	pass


func _ready() -> void:
	body_entered.connect(Callable(on_body_entered))
	
	# Collision layers.
	set_collision_layer_value(GameObjects.physics_layers.WORLD, false)
	set_collision_layer_value(GameObjects.physics_layers.ACTOR, true)
	
	# Collision masks.
	GameObjects.set_default_collision_masks(self)
	
	# This is a dumb fix to certain collisions not allowing the actor to walk over them without crouching first.
	# I have no idea why this is the case.
	#current_state = State.CROUCHING
	#current_state = State.STANDING


func jump(strength: float) -> void:
	if is_crouched: return # no crouch jumping; return to standing if possible. # TODO return to standing.
	
	apply_central_impulse(linear_velocity + Vector3.UP * strength * 500)


func on_body_entered(_body: Node3D) -> void:
	pass


# Return to previous state.
func revert_state() -> void:
	current_state = prev_state


func slide() -> void:
	match current_state:
		State.STANDING:
			standing_collision.disabled = true
			crouching_collision.disabled = false
	
	toggle_crouch()
	start_transition(MovementHandler.TransitionType.SLIDE)


func start_drive() -> void:
	current_state = State.DRIVING


func start_transition(transition_type: MovementHandler.TransitionType) -> void:
	current_state = State.TRANSITIONING
	movement_handler.current_transition_type = transition_type


func stop_transition() -> void:
	revert_state()


func toggle_crouch() -> void:
	match current_state:
		State.CROUCHING:
			current_state = State.STANDING
		_:
			current_state = State.CROUCHING


func vault() -> void:
	match current_state:
		State.STANDING:
			standing_collision.disabled = true
		State.CROUCHING:
			crouching_collision.disabled = true
	
	start_transition(MovementHandler.TransitionType.VAULT)
