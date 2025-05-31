class_name MovementHandler extends Node3D

const VAULT_LERP_SPEED: float = 3.0

var actor: Actor

# Raycasts.
@export var vaulting_raycast: RayCast3D # Set collision_mask = 3 only.
@export var vault_raycast_length: float = 1.0
@export var step_raycast: RayCast3D
@export var step_raycast_length: float = 0.75
@export var step_height_raycast: RayCast3D
@export var wall_raycast: RayCast3D

var vault_target_pos: Vector3

func _ready() -> void:
	await owner.ready
	
	actor = owner as Actor
	assert(actor != null)
	
	actor.jump_pressed.connect(Callable(_on_jump_pressed))
	actor.crouch_pressed.connect(Callable(_on_crouch_pressed))

func _physics_process(delta: float) -> void:
	var movement_direction := actor.movement_direction
	if not movement_direction == Vector3.ZERO:
		# Adjust raycasts to point in direction of movement_direction.
		vaulting_raycast.target_position = movement_direction.normalized() * vault_raycast_length
		step_raycast.target_position = movement_direction.normalized() * step_raycast_length
		wall_raycast.target_position = movement_direction.normalized() * step_raycast_length
		step_height_raycast.position = wall_raycast.target_position
		
		# While actor has a movement_direction, check for steps.
		if step_height_raycast.is_colliding():
			var step_height: float = abs(step_height_raycast.get_collision_point().y) - abs(actor.foot_marker.global_position.y)
			actor.global_position.y += abs(step_height)
	
	match actor.current_state:
		Actor.State.Vaulting:
			if actor.global_position.distance_squared_to(vault_target_pos) < 0.3:
				actor.current_state = actor.prev_state
			else: actor.global_position = lerp(actor.global_position, vault_target_pos, VAULT_LERP_SPEED * delta)
	apply_movement_direction()

func apply_movement_direction() -> void:
	var velocity := actor.movement_direction
	if not actor.is_on_ground():
		actor.apply_central_force(velocity)
		return
	
	match actor.current_state:
		Actor.State.Standing:
			if Input.is_action_pressed("sprint"): velocity *= actor.sprint_multiplier
		Actor.State.Crouching:
			velocity *= actor.crouch_multiplier
	
	actor.apply_central_force(velocity)

func handle_physics_state(state: PhysicsDirectBodyState3D) -> void:
	# Calc maximum speed determined by current Actor.STATE.
	var current_max_speed := actor.max_speed
	match actor.current_state:
		Actor.State.Standing:
			if Input.is_action_pressed("sprint"): current_max_speed *= actor.sprint_multiplier
		Actor.State.Crouching:
			current_max_speed *= actor.crouch_multiplier
	
	# Prevent Actor from exceeding current_maximum_speed.
	if state.linear_velocity.length() > current_max_speed:
		state.linear_velocity = lerp(state.linear_velocity, state.linear_velocity.normalized() * current_max_speed, actor.acceleration / 10)
	
	# Artificially stop Actor movement without using physics.
	if actor.movement_direction == Vector3.ZERO:
		state.linear_velocity.x = 0
		state.linear_velocity.z = 0
		state.linear_velocity.x = lerp(state.linear_velocity.x, 0.0, actor.friction)
		state.linear_velocity.z = lerp(state.linear_velocity.z, 0.0, actor.friction)

func handle_jump() -> void:
	if not actor.is_on_ground(): return
	elif actor.current_state == Actor.State.Crouching:
		actor.crouch_pressed.emit() # no crouch jumping; return to standing if possible.
		return 
	
	actor.apply_central_impulse(actor.linear_velocity + Vector3.UP * actor.jump_strength * 500)

func handle_vault(direction: Vector3) -> void:
	match actor.current_state:
		Actor.State.Standing:
			actor.standing_collision.disabled = true
			actor.prev_state = Actor.State.Standing
		Actor.State.Crouching:
			actor.crouching_collision.disabled = true
			actor.prev_state = Actor.State.Crouching
	
	actor.freeze = true
	vault_target_pos = global_position + direction
	actor.current_state = Actor.State.Vaulting

func _on_crouch_pressed() -> void:
	match actor.current_state:
		Actor.State.Standing:
			actor.current_state = Actor.State.Crouching
		Actor.State.Crouching:
			if actor.crouching_ray_cast.is_colliding(): return
			actor.current_state = Actor.State.Standing

func _on_jump_pressed() -> void:
	if vaulting_raycast.is_colliding():
		var collision := vaulting_raycast.get_collider()
		var vault_object := collision as VaultObject
		if not vault_object.enabled:
			handle_jump()
			return
		var direction := vault_object.get_vault_direction(global_position)
		handle_vault(direction)
	else: handle_jump()
