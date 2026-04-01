class_name Vehicle
extends RigidBody3D
# Currently a RayCastVehicle.


enum State {
	PARK,
	DRIVE,
	NEUTRAL,
	REVERSE
}


const PARK_BRAKE_STRENGTH := 1.0


@export var door: SlidingDoor
@export var door_marker: Marker3D
@export var driver_position_marker: Marker3D
@export var driver_exit_position_marker: Marker3D
@export var entrance: RestrictedMovementArea
@export var headlights: Array[SpotLight3D]
@export var wheels: Array[RayCastWheel] # If creating new type of wheel, best to change this to Array[Node3D].


var acceleration_direction := 0.0
var current_speed: float:
	get(): return linear_velocity.project(global_transform.basis.z).length()
var current_state := State.PARK
var has_driver := false
var is_on_ground := false
var is_using_parking_brake: bool:
	get(): return current_state == State.PARK
var num_of_wheels:
	get(): return wheels.size()
var turn_direction: float = 0.0


func _physics_process(_delta: float) -> void:
	handle_doors()
	
	for wheel in wheels:
		if wheel.is_colliding(): is_on_ground = true
		else: is_on_ground = false
	
	# Help prevent vehicle from flipping over.
	if is_on_ground: center_of_mass = Vector3.ZERO
	else: center_of_mass = Vector3.DOWN


func _ready() -> void:
	# Collision layers.
	set_collision_layer_value(GameObjects.physics_layers.WORLD, false)
	set_collision_layer_value(GameObjects.physics_layers.VEHICLE, true)
	
	# Collision masks.
	set_collision_mask_value(GameObjects.physics_layers.WORLD, true)
	set_collision_mask_value(GameObjects.physics_layers.VEHICLE, true)
	
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM


func enter() -> void:
	if has_driver: return
	has_driver = true


func exit() -> void:
	if not has_driver: return
	has_driver = false
	acceleration_direction = 0.0


func handle_doors() -> void:
	if not door.current_state != SlidingDoor.State.LOCKED_OPEN: # If door not completely open then entrance is disabled.
		entrance.is_disabled = true
		return
	
	if entrance.is_area_blocked(get_viewport().get_camera_3d(), GameObjects.physics_layers.VEHICLE):
		entrance.is_disabled = true
		return
	
	entrance.is_disabled = false


func park() -> void:
	current_state = State.PARK


func shift_gear_down() -> void:
	current_state = State.REVERSE


func shift_gear_up() -> void:
	current_state = State.DRIVE


func toggle_headlights() -> void:
	for light in headlights:
		light.visible = not light.visible
