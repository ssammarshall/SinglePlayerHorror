class_name CameraRig extends Node3D

@export_group("Transformation")
@export var rotation_x_max := 55.0
@export var rotation_x_min := -65.0
@export var bob_amplitude := 0.01
var bob_time := 0.0
var forward: Vector3:
	get():
		return -camera.global_transform.basis.z

var player: Player
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null)
	
	player.crouch_signal.connect(Callable(_on_crouch_signal))

func _physics_process(delta: float) -> void:
	_camera_bob(delta)

func _camera_bob(delta: float) -> void:
	var length: float = player.linear_velocity.length()
	bob_time += length * delta * 2
	spring_arm.position.y += sin(bob_time) * bob_amplitude * length / 50
	#spring_arm.position.y = lerp(spring_arm.position.y, sin(bob_time) * bob_amplitude, delta * length)

func tilt_camera(x_rot: float) -> void:
	camera.rotation.x -= x_rot
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(rotation_x_min), deg_to_rad(rotation_x_max))

func _on_crouch_signal(value: bool) -> void:
	if value:
		anim_player.play("crouch")
	else:
		anim_player.play("stand")
