class_name CameraRig extends Node

const FOLLOW_LERP_SPEED: float = 8.0

@export_group("Transformation")
@export var rotation_x_max := 55.0
@export var rotation_x_min := -65.0
@export var bob_amplitude := 0.01
var bob_time := 0.0
var forward: Vector3:
	get():
		return -camera.global_transform.basis.z

var player: Player
@onready var base: Node3D = $Base
@onready var spring_arm: SpringArm3D = $Base/SpringArm3D
@onready var camera: Camera3D = $Base/SpringArm3D/Camera3D
@onready var anim_player: AnimationPlayer = $Base/AnimationPlayer

var global_transform: Transform3D:
	get():
		return base.global_transform

func _ready() -> void:
	await owner.ready
	
	player = owner as Player
	assert(player != null)
	base.global_position = player.global_position
	
	player.crouch_pressed.connect(Callable(_on_crouch_pressed))
	player.camera_rotate_x.connect(Callable(_on_camera_rotate_x))
	player.camera_rotate_y.connect(Callable(_on_camera_rotate_y))

func _physics_process(delta: float) -> void:
	follow_player(delta)
	pass

func _camera_bob(delta: float) -> void:
	var length: float = player.linear_velocity.length()
	bob_time += length * delta * 2
	spring_arm.position.y += sin(bob_time) * bob_amplitude * length / 50
	spring_arm.position.y = lerp(spring_arm.position.y, sin(bob_time) * bob_amplitude, delta * length)

func follow_player(delta: float) -> void:
	var player_pos: Vector3 = player.global_position
	base.global_position = lerp(base.global_position, player_pos, delta * FOLLOW_LERP_SPEED)

func _on_crouch_pressed() -> void:
	await get_tree().process_frame
	match player.current_state:
		Actor.State.Standing:
			anim_player.play("stand")
		Actor.State.Crouching:
			anim_player.play("crouch")

func _on_camera_rotate_x(rot: float) -> void:
	camera.rotation.x -= rot
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(rotation_x_min), deg_to_rad(rotation_x_max))

func _on_camera_rotate_y(rot: float) -> void:
	base.rotate_y(rot)
