class_name Player extends Actor

signal camera_rotate_x(float)
signal camera_rotate_y(float)

@export_group("Input")
@export var mouse_sens := 0.01
@export var throw_strength := 15.0
var velocity := Vector3.ZERO

@onready var camera_rig: CameraRig = $CameraRig
@onready var flashlight: Flashlight = $CameraRig/Base/SpringArm3D/Camera3D/Flashlight
@onready var interaction_handler: InteractionHandler = $CameraRig/Base/SpringArm3D/Camera3D/InteractionHandler

@onready var inventory: Inventory = $ui/inventory
@onready var light_detection_handler: LightDetectionHandler = $LightDetectionHandler

var mouse_dir := Vector2.ZERO:
	set(dir):
		mouse_dir = dir
		interaction_handler.mouse_dir = dir
var lock_camera := false
var detection_level: float:
	get():
		return light_detection_handler.light_level

func _ready() -> void:
	super._ready()
	
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
			crouch_pressed.emit()
			return
		
		if event.is_action_pressed("jump"):
			jump_pressed.emit()
			return
		
		if event.is_action_pressed("inventory"):
			inventory.toggle()
			return
	
	if event is InputEventMouseMotion:
		mouse_dir = event.relative
		if lock_camera: return
		camera_rotate_y.emit(-mouse_dir.x * mouse_sens)
		camera_rotate_x.emit(mouse_dir.y * mouse_sens)
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

func _physics_process(_delta: float) -> void:
	movement_direction = get_movement_direction()

# Get input direction from Player and set Actor movement_direction
func get_movement_direction() -> Vector3:
	var input := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("backward") - Input.get_action_strength("forward")
	)
	
	if input == Vector2.ZERO:
		return Vector3.ZERO
	
	var movement_dir: Vector3 = camera_rig.global_transform.basis.x * input.x
	movement_dir += camera_rig.global_transform.basis.z * input.y
	
	return movement_dir.normalized() * acceleration * 500

func _on_body_entered(_body: Node3D) -> void:
	pass

func _on_lock_camera(lock: bool) -> void:
	lock_camera = lock
