class_name Player extends RigidBody3D

const VAULT_LERP_SPEED: float = 3.0

signal crouch_signal(value: bool)

@export_group("Input")
@export var mouse_sens := 0.01

@export_group("Statistics")
@export var max_speed := 3.0
@export var acceleration := 2.5
@export_range(0.01, 1, 0.01) var friction := 0.5
@export var sprint_multiplier := 1.8
@export var crouch_multiplier := 0.75
@export var jump_strength := 1.0
@export var throw_strength := 15.0
var is_on_ground := false
var velocity := Vector3.ZERO

@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var ground_ray_cast: RayCast3D = $StandingCollision/GroundRayCast
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var crouching_ray_cast: RayCast3D = $CrouchingCollision/CrouchingRayCast
@onready var camera_rig: CameraRig = $CameraRig
@onready var flashlight: Flashlight = $CameraRig/SpringArm3D/Camera3D/Flashlight
@onready var interaction_handler: InteractionHandler = $CameraRig/SpringArm3D/Camera3D/InteractionHandler
@onready var inventory: Inventory = $ui/inventory
@onready var light_detection_handler: LightDetectionHandler = $LightDetectionHandler

# Raycasts.
@onready var vaulting_raycast: RayCast3D = $CameraRig/VaultingRaycast
@onready var step_raycast: RayCast3D = $CameraRig/StepRaycast
@onready var wall_raycast: RayCast3D = $CameraRig/WallRaycast

enum State {
	Standing,
	Crouching,
	Vaulting
}
var current_state := State.Standing:
	set(new_state):
		if current_state == new_state: return
		match current_state:
			State.Vaulting:
				freeze = false
		current_state = new_state
		match current_state:
			State.Standing:
				standing_collision.disabled = true
				crouching_collision.disabled = false
			State.Crouching:
				crouching_collision.disabled = true
				standing_collision.disabled = false
var prev_state: State
var vault_target_pos: Vector3

var input_dir := Vector3.ZERO
var has_movement_input := false
var mouse_dir := Vector2.ZERO:
	set(dir):
		mouse_dir = dir
		interaction_handler.mouse_dir = dir
var lock_camera := false
var detection_level: float:
	get():
		return light_detection_handler.light_level

func _ready() -> void:
	SignalBus.lock_camera.connect(Callable(_on_lock_camera))
	
	body_entered.connect(Callable(_on_body_entered))
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crouching_ray_cast.add_exception(self)
	interaction_handler.add_exception(self)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("interact"):
			return
		
		if event.is_action_pressed("flashlight"):
			flashlight.toggle()
			return
		
		if event.is_action_pressed("crouch"):
			crouch()
			return
		
		if event.is_action_pressed("jump"):
			if vaulting_raycast.is_colliding():
				var collision := vaulting_raycast.get_collider()
				var vault_object := collision as VaultObject
				if not vault_object.enabled:
					jump()
					return
				var direction := vault_object.get_vault_direction(global_position)
				vault(direction)
			else: jump()
			return
		
		if event.is_action_pressed("inventory"):
			inventory.toggle()
			return
	
	if event is InputEventMouseMotion:
		mouse_dir = event.relative
		if lock_camera: return
		camera_rig.rotate_y(-mouse_dir.x * mouse_sens)
		camera_rig.tilt_camera(mouse_dir.y * mouse_sens)
		return
	
	if event is InputEventMouseButton:
		if event.is_action_pressed("interact"):
			interaction_handler.interact()
			return
		elif event.is_action_released("interact"):
			interaction_handler.release()
			return
		
		if event.is_action_pressed("throw"):
			interaction_handler.throw()
			return
		elif event.is_action_released("throw"):
			interaction_handler.throw()
			return
		
		if event.is_action_released("zoom_in"):
			flashlight.focus(1)
			return
		elif event.is_action_released("zoom_out"):
			flashlight.focus(-1)
			return

func _physics_process(delta: float) -> void:
	if ground_ray_cast.is_colliding(): is_on_ground = true
	else: is_on_ground = false
	
	match current_state:
		State.Vaulting:
			if global_position.distance_squared_to(vault_target_pos) < 0.3:
				current_state = prev_state
			else: global_position = lerp(global_position, vault_target_pos, VAULT_LERP_SPEED * delta)
		_:
			input_dir = _get_movement_direction()
			_apply_movement_direction()
	
	

func _get_movement_direction() -> Vector3:
	var input := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("backward") - Input.get_action_strength("forward")
	)
	
	if input == Vector2.ZERO:
		has_movement_input = false
		return Vector3.ZERO
	else: has_movement_input = true
	
	var movement_dir: Vector3 = camera_rig.global_transform.basis.x * input.x
	movement_dir += camera_rig.global_transform.basis.z * input.y
	
	return movement_dir.normalized() * acceleration * 500

func _apply_movement_direction() -> void:
	if not is_on_ground: 
		print("not on ground")
		return
	elif not has_movement_input: # Stopping Player is handled in _integrate_forces().
		velocity = Vector3.ZERO
		return
	
	velocity = input_dir
	match current_state:
		State.Standing:
			if Input.is_action_pressed("sprint"): velocity *= sprint_multiplier
		State.Crouching:
			velocity *= crouch_multiplier
	
	# Climbing stairs/steps/ledges.
	if step_raycast.is_colliding() and not wall_raycast.is_colliding():
		print("there is a step")
		apply_central_impulse(Vector3.UP * 50)
		#velocity += Vector3.UP
	apply_central_force(velocity)


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_on_ground: return
	
	var current_max_speed := max_speed
	match current_state:
		State.Standing:
			if Input.is_action_pressed("sprint"): current_max_speed *= sprint_multiplier
		State.Crouching:
			current_max_speed *= crouch_multiplier
	if state.linear_velocity.length() > current_max_speed:
		state.linear_velocity = lerp(state.linear_velocity, state.linear_velocity.normalized() * current_max_speed, acceleration / 10)
	
	# Artificially stop Player movement without using physics.
	if not has_movement_input:
		state.linear_velocity.x = lerp(state.linear_velocity.x, 0.0, friction)
		state.linear_velocity.z = lerp(state.linear_velocity.z, 0.0, friction)

func crouch() -> void:
	match current_state:
		State.Standing:
			crouch_signal.emit(true)
			current_state = State.Crouching
		State.Crouching:
			if crouching_ray_cast.is_colliding(): return
			crouch_signal.emit(false)
			current_state = State.Standing

func jump() -> void:
	if not ground_ray_cast.is_colliding(): return
	elif current_state == State.Crouching:
		crouch() # no crouch jumping; return to standing if possible.
		return 
	
	apply_central_impulse(linear_velocity + Vector3.UP * jump_strength * 500)
	#velocity.y += jump_strength

func vault(direction: Vector3) -> void:
	match current_state:
		State.Standing:
			standing_collision.disabled = true
			prev_state = State.Standing
		State.Crouching:
			crouching_collision.disabled = true
			prev_state = State.Crouching
	
	freeze = true
	vault_target_pos = global_position + direction
	current_state = State.Vaulting

func _on_body_entered(_body: Node3D) -> void:
	pass

func _on_lock_camera(lock: bool) -> void:
	lock_camera = lock
