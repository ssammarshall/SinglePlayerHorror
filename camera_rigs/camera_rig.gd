class_name CameraRig
extends Node


enum State {
	IDLE,
	FOLLOWING_PLAYER,
	MOUNTED
}


const BASE_ROTATE_LERP_SPEED := 10.0 # How quickly the base rotates to the target rotation.
const FOLLOW_LERP_SPEED := 15.0 # How quickly the camera follows the target.


@export_group("Transformation")
@export var rotation_x_max := 55.0
@export var rotation_x_min := -65.0
@export var bob_amplitude := 0.01


var bob_time := 0.0
var camera_mount_marker: Marker3D
var current_state := State.FOLLOWING_PLAYER
var forward: Vector3:
	get():
		return -camera.global_transform.basis.z
var global_transform: Transform3D:
	get():
		return base.global_transform
var is_locked: bool = false
var mount_tween: Tween
var mount_tween_speed := 0.35
var player: Player
var restrict_base_rotation_y := false:
	set(value):
		restrict_base_rotation_y = value
		if not restrict_base_rotation_y: spring_arm.rotation.y = 0
var rotation_y_max := INF
var rotation_y_min := INF


@onready var base: Node3D = $Base
@onready var spring_arm: SpringArm3D = $Base/SpringArm3D
@onready var camera: Camera3D = $Base/SpringArm3D/Camera3D
@onready var anim_player: AnimationPlayer = $Base/AnimationPlayer


func _physics_process(delta: float) -> void:
	match current_state:
		State.FOLLOWING_PLAYER:
			if not player: return
			match player.current_state:
				Actor.State.DRIVING:
					restrict_base_rotation_y = true
					var mesh_forward := player.mesh.global_rotation.y
					base.rotation.y = rotate_toward(base.rotation.y, mesh_forward, BASE_ROTATE_LERP_SPEED * delta)
				_:
					restrict_base_rotation_y = false
					base.rotation.y = player.global_rotation.y
			follow_player(delta)
		State.MOUNTED:
			base.global_transform = camera_mount_marker.global_transform


func _ready() -> void:
	await owner.ready
	
	player = owner as Player
	assert(player != null)
	
	base.global_position = player.global_position
	
	camera.set_cull_mask_value(GameObjects.render_layers.WORLD, true)
	camera.set_cull_mask_value(GameObjects.render_layers.LIGHT_DETECTION, false)
	camera.set_cull_mask_value(GameObjects.render_layers.MAP, false)
	
	player.state_changed.connect(Callable(on_player_state_changed))
	player.camera_rotate_x.connect(Callable(on_camera_rotate_x))
	player.camera_rotate_y.connect(Callable(on_camera_rotate_y))


# Bounce spring arm to simulate footsteps.
func camera_bob(delta: float) -> void:
	var length: float = player.linear_velocity.length()
	bob_time += length * delta * 2
	spring_arm.position.y += sin(bob_time) * bob_amplitude * length / 50
	spring_arm.position.y = lerpf(spring_arm.position.y, sin(bob_time) * bob_amplitude, delta * length)


# Update base global position to follow player global position.
func follow_player(delta: float) -> void:
	if not player: return
	
	var player_pos: Vector3 = player.global_position
	
	# Calculate current follow lerp speed
	var lerp_speed := FOLLOW_LERP_SPEED
	if player.current_state == Player.State.DRIVING: lerp_speed *= 2 # Increase follow speed to match higher vehicle velocity.
	
	base.global_position = lerp(base.global_position, player_pos, delta * lerp_speed)


func lock(value: bool) -> void:
	is_locked = value


# Rotate camera on x axis to look up and down.
func on_camera_rotate_x(rot: float) -> void:
	if is_locked: return
	camera.rotation.x -= rot
	camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(rotation_x_min), deg_to_rad(rotation_x_max))


# Rotate base on y axis to look left and right.
func on_camera_rotate_y(rot: float) -> void:
	if is_locked: return
	
	# If base rotation is restricted, rotate the spring arm instead of the base.
	if restrict_base_rotation_y:
		spring_arm.rotate_y(rot)
		spring_arm.rotation.y = clampf(spring_arm.rotation.y, -deg_to_rad(110), deg_to_rad(110))
		return
	
	base.rotate_y(rot)
	


# Play correct camera animation based on player's current and previous state.
func on_player_state_changed(new_state: Actor.State, prev_state: Actor.State) -> void:
	match new_state:
		Actor.State.STANDING:
			if prev_state == Actor.State.STANDING: pass # Camera does not need to move again.
			else: anim_player.play("stand")
		Actor.State.CROUCHING:
			if prev_state == Actor.State.CROUCHING: pass # Camera does not need to move again.
			else: anim_player.play("crouch")



func set_mount(marker: Marker3D) -> void:
	camera_mount_marker = marker
	current_state = State.IDLE # Allow mount tween to briefly take control of camera rig.
	
	# Mount.
	if camera_mount_marker:
		if mount_tween: mount_tween.kill()
		
		mount_tween = create_tween()
		mount_tween.tween_property(base, "global_position", camera_mount_marker.global_position, mount_tween_speed)
		mount_tween.parallel().tween_property(base, "global_rotation", camera_mount_marker.global_rotation, mount_tween_speed)
		mount_tween.parallel().tween_property(camera, "rotation", Vector3(0, 0, 0), mount_tween_speed)
		mount_tween.tween_callback(Callable(func(): current_state = State.MOUNTED))
		return
	
	# Dismount
	if mount_tween: mount_tween.kill()
	
	mount_tween = create_tween()
	mount_tween.tween_property(base, "global_position", player.global_position, mount_tween_speed)
	mount_tween.parallel().tween_property(base, "global_rotation", player.global_rotation, mount_tween_speed)
	mount_tween.tween_callback(Callable(func(): current_state = State.FOLLOWING_PLAYER))
