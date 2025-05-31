class_name Actor extends RigidBody3D

# Collisions.
@export var standing_collision: CollisionShape3D
@export var crouching_collision: CollisionShape3D

# Raycasts.
@export var crouching_ray_cast: RayCast3D
@export var ground_ray_cast: RayCast3D

# Components.
@export var movement_handler: MovementHandler

@export var foot_marker: Marker3D

signal crouch_pressed
signal jump_pressed

@export_group("Statistics")
@export var max_speed := 3.0
@export var acceleration := 2.5
@export_range(0.01, 1, 0.01) var friction := 0.5
@export var sprint_multiplier := 1.8
@export var crouch_multiplier := 0.75
@export var jump_strength := 1.0
@export var height := 2.0

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

var movement_direction := Vector3.ZERO

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	pass

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	movement_handler.handle_physics_state(state)

func is_on_ground() -> bool:
	return ground_ray_cast.is_colliding()
