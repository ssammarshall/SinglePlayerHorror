class_name MovementHandler
extends Node3D


enum TransitionType {
	STANDARD,
	SLIDE,
	VAULT
}


@export_group("Raycasts")
@export var crouching_ray_cast: RayCast3D
@export var ground_ray_cast: RayCast3D
@export var vaulting_raycast: RayCast3D # Set collision_mask = 3 only.
@export var vault_raycast_length: float = 1.0
@export var step_raycast: RayCast3D
@export var step_raycast_length: float = 0.35
@export var step_height_raycast: RayCast3D
@export var wall_raycast: RayCast3D
@export_group("Statistics")
@export var max_speed := 2.5
@export var acceleration := 2.5
@export_range(0.01, 1, 0.01) var friction := 0.5
@export var sprint_multiplier := 2.0
@export var crouch_multiplier := 0.5
@export var slide_multiplier := 7.5
@export var vault_multiplier := 3.0
@export var jump_strength := 0.55
@export var height := 2.0
@export var rotation_speed := 1.0


var actor: Actor
var can_stand_up: bool:
	get(): return not crouching_ray_cast.is_colliding()
var current_transition_type: TransitionType:
	set(new_type):
		current_transition_type = new_type
		match current_transition_type:
			TransitionType.SLIDE:
				transition_speed = slide_multiplier
			TransitionType.VAULT:
				transition_speed = vault_multiplier
			_:
				transition_speed = max_speed
var is_on_ground: bool:
	get(): return ground_ray_cast.is_colliding()
var is_in_transition := false
var is_y_rotation_locked := false
var linear_velocity: Vector3
var previous_position: Vector3
var previous_y_rotation := 0.0
var restricted_movement_area: RestrictedMovementArea:
	set(area):
		restricted_movement_area = area
		if restricted_movement_area: is_in_transition = true
var sprint_held := false
var stuck_count := 0 # How many ticks the actor has been in same position.
var stuck_count_max := 40 # How many ticks before the actor is considered "stuck".
var target_marker: Marker3D
var target_position: Vector3:
	set(pos):
		target_position = pos
		if target_position: is_in_transition = true
var transition_speed := 3.0
var world_raycasts: Array[RayCast3D] # Raycasts with collision_masks for physcial objects.


func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("sprint"): sprint_held = true
	else: sprint_held = false
	
	match actor.current_state:
		Actor.State.STANDING:
			pass
		Actor.State.CROUCHING:
			if sprint_held and can_stand_up: actor.toggle_crouch()
		Actor.State.DRIVING:
			actor.global_position = target_marker.global_position # Stay in seat.
		Actor.State.TRANSITIONING:
			pass
	
	var movement_direction := actor.movement_direction
	if not movement_direction == Vector3.ZERO:
		if not actor.current_state == Actor.State.TRANSITIONING: step_check() # While actor has a movement_direction, check for steps.
	
	previous_position = actor.global_position
	apply_movement_direction(movement_direction)


func _ready() -> void:
	await owner.ready
	
	actor = owner as Actor
	assert(actor != null)
	
	actor.crouch_pressed.connect(Callable(on_crouch_pressed))
	actor.enter_vehicle.connect(Callable(on_enter_vehicle))
	actor.exit_vehicle.connect(Callable(on_exit_vehicle))
	actor.jump_pressed.connect(Callable(on_jump_pressed))
	actor.movement_restricted.connect(Callable(on_movement_restricted))
	
	vaulting_raycast.set_collision_mask_value(GameObjects.physics_layers.WORLD, false)
	vaulting_raycast.set_collision_mask_value(GameObjects.physics_layers.VAULT_OBJECT, true)
	
	# Group raycasts that all need to interact with the world and the entities in it.
	world_raycasts.append(crouching_ray_cast)
	world_raycasts.append(ground_ray_cast)
	world_raycasts.append(step_raycast)
	world_raycasts.append(step_height_raycast)
	world_raycasts.append(wall_raycast)
	for raycast in world_raycasts:
		raycast.set_collision_mask_value(GameObjects.physics_layers.WORLD, true)
		raycast.set_collision_mask_value(GameObjects.physics_layers.VEHICLE, true)


func apply_movement_direction(direction: Vector3) -> void:
	var velocity := direction.normalized() * acceleration * 500
	if not is_on_ground:
		actor.apply_central_force(velocity)
		return
	
	match actor.current_state:
		Actor.State.STANDING:
			if sprint_held: velocity *= sprint_multiplier
		Actor.State.CROUCHING:
			velocity *= crouch_multiplier
	
	actor.apply_central_force(velocity)


# Called by parent actor during _integrate_forces(state) to handle maximum speed,
# coming to a complete stop and handling actor transition state.
func handle_physics_state(state: PhysicsDirectBodyState3D) -> void:
	var current_max_speed := max_speed # Calc maximum speed determined by current Actor.State.
	match actor.current_state:
		Actor.State.STANDING:
			if sprint_held: current_max_speed *= sprint_multiplier
		Actor.State.CROUCHING:
			current_max_speed *= crouch_multiplier
		Actor.State.TRANSITIONING:
			handle_physics_state_transition(state)
			#return # Do not do anything else while in Actor.State.TRANSITIONING.
	
	var movement_direction := actor.movement_direction
	
	if is_on_ground:
		var collision := ground_ray_cast.get_collider()
		if collision is Vehicle:
			var vehicle := collision as Vehicle
			# If inside/on a vehicle, match vehicle velocity if in motion.
			if vehicle.linear_velocity.length() > 1.0:
				if sprint_held: movement_direction *= sprint_multiplier
				state.linear_velocity = vehicle.linear_velocity + movement_direction
				return
	
	if not is_y_rotation_locked:
		state.angular_velocity.y = actor.rotation_y_direction * rotation_speed
		actor.rotation_y_direction = 0.0
	else: state.angular_velocity.y = 0.0
	
	linear_velocity = state.linear_velocity
	# Prevent Actor from exceeding current_maximum_speed.
	if linear_velocity.length() > current_max_speed:
		state.linear_velocity.x = lerpf(linear_velocity.x, linear_velocity.normalized().x * current_max_speed, acceleration / 5)
		state.linear_velocity.z = lerpf(linear_velocity.z, linear_velocity.normalized().z * current_max_speed, acceleration / 5)
	# Artificially stop Actor movement without using physics.
	if movement_direction == Vector3.ZERO:
		state.linear_velocity.x = lerpf(linear_velocity.x, 0.0, friction)
		state.linear_velocity.z = lerpf(linear_velocity.z, 0.0, friction)


# Dedicated function for handling the transition logic for the actor's physics state.
func handle_physics_state_transition(state: PhysicsDirectBodyState3D) -> void:
	# Determine direction towards target position.
	var target_direction := target_position - actor.global_position
	if target_direction.length() > 1: target_direction = target_direction.normalized()
	
	# Determine how the actor will move based off of whether or not it is currently
	# in transition, close enough to the target position and whether or not the actor
	# has a desired movement direction.
	var is_close_enough := (is_in_transition and actor.global_position.distance_squared_to(target_position) < 0.05)
	if is_close_enough:
		target_position = actor.global_position
		state.linear_velocity = Vector3.ZERO
		is_in_transition = false
	elif is_in_transition: # If in transition to target position.
		#var is_stuck := stuck_check()
		#if is_stuck:
			#print("stuck")
			#actor.stop_transition()
			#return
		state.linear_velocity = target_direction * transition_speed # Keep moving towards target position.
	elif actor.movement_direction != Vector3.ZERO: # If not in transition and actor wants to move.
		if restricted_movement_area: # Determine next target position.
			target_direction = restricted_movement_area.get_direction(actor.movement_direction)
			target_position = actor.global_position + target_direction
		else: 
			actor.stop_transition() # If not in restricted movement area and is not transitioning, stop transitioning.
	elif not restricted_movement_area:
		actor.stop_transition() # If not in restricted movement area and is not transitioning, stop transitioning.
	else: # Still in restricted movement area.
		actor.global_position = target_position # Stay on target position.


func on_crouch_pressed() -> void:
	match actor.current_state:
		Actor.State.STANDING:
			if sprint_held: # Start sliding.
				target_position = actor.global_position + (linear_velocity / 2)
				actor.slide()
				return
		Actor.State.CROUCHING:
			if not can_stand_up: return # Avoid clipping into objects above actor.
		Actor.State.TRANSITIONING:
			return # Ignore when transitioning.
	actor.toggle_crouch()


func on_enter_vehicle(vehicle: Vehicle) -> void:
	if vehicle.has_driver: return
	
	vehicle.enter()
	target_marker = vehicle.driver_position_marker
	actor.start_drive()


func on_exit_vehicle(vehicle: Vehicle) -> void:
	vehicle.exit()
	target_position = vehicle.driver_exit_position_marker.global_position
	actor.start_transition(TransitionType.STANDARD)


func on_jump_pressed() -> void:
	if vaulting_raycast.is_colliding() and actor.movement_direction:
		var collision := vaulting_raycast.get_collider()
		var vault_object := collision as VaultObject
		if not vault_object or not vault_object.enabled:
			if is_on_ground: actor.jump(jump_strength)
			return
		var direction := vault_object.get_vault_direction(actor.global_position)
		target_position = actor.global_position + direction
		actor.vault()
	elif is_on_ground: actor.jump(jump_strength)


func on_movement_restricted(is_restricted: bool, area: RestrictedMovementArea) -> void:
	if is_restricted and area == restricted_movement_area: return # Already in this area.
	
	if is_restricted and area != null: # If a new area is restricting the actor.
		restricted_movement_area = area
		target_position = area.find_closest_marker(actor.global_position).global_position
		actor.start_transition(TransitionType.STANDARD)
	elif not is_restricted and area == restricted_movement_area:
		actor.stop_transition() # Not in restricted zone, stop transition.
		restricted_movement_area = null # If current restricted area is releasing the actor.
	elif not is_restricted: pass # Another restricted area is releasing the actor after the actor has already moved into a new area. Ignore.


func step_check() -> void:
	if not is_on_ground: return
	if wall_raycast.is_colliding(): return # Too high to be considered a step.
	if not step_height_raycast.is_colliding(): return
	
	var collision: Object = step_height_raycast.get_collider()
	if collision is PhysicsInteractable: return # Prevent items/interactables in the world causing weird steps.
	print("step") # TODO this is detecting vehicle ground voer and over causing bouncing
	var ground_height: float = actor.global_position.y - (height / 2)
	var step_height: float = abs(step_height_raycast.get_collision_point().y) - abs(ground_height)
	actor.global_position.y += abs(step_height) + 0.05


#func stuck_check() -> bool:
	#if actor.global_position.distance_squared_to(previous_position) < 0.02: stuck_count += 1
	#
	#if stuck_count >= stuck_count_max:
		#stuck_count = 0
		#return true
	#
	#return false
