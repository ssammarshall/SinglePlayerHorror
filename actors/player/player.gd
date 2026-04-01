class_name Player
extends Actor
# Actor with a camera rig, interaction handler and controllers to handle input.


signal camera_rotate_x(float)
signal camera_rotate_y(float)


var controller: Controller
var mouse_dir := Vector2.ZERO:
	set(dir):
		mouse_dir = dir
		interaction_handler.mouse_dir = dir


@onready var camera_rig: CameraRig = $CameraRig
@onready var interaction_handler: InteractionHandler = $CameraRig/Base/SpringArm3D/Camera3D/InteractionHandler
@onready var inventory_handler: InventoryHandler = $ui/InventoryHandler


func _input(event: InputEvent) -> void:
	controller.handle_input(self, event)


func _physics_process(delta: float) -> void:
	controller.physics_update(self, delta)


func _ready() -> void:
	super._ready()
	
	controller = PlayerController.new()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	exit_vehicle.connect(Callable(on_exit_vehicle))
	
	interaction_handler.add_exception(self)
	interaction_handler.enter_vehicle.connect(Callable(on_enter_vehicle))
	interaction_handler.focus_on_display.connect(Callable(on_focus_on_display))
	interaction_handler.lock_camera.connect(Callable(on_lock_camera))
	interaction_handler.pickup_item.connect(Callable(func(item: Item): inventory_handler.add_to_inventory(item)))
	
	inventory_handler.focus.connect(Callable(on_inventory_focus))
	inventory_handler.lock_camera.connect(Callable(on_lock_camera))


# Enables or disbales the interaction handler.
func enable_interactions(enable: bool) -> void:
	interaction_handler.is_disabled = not enable


func exit_focus() -> void:
	camera_rig.lock(false)
	camera_rig.set_mount(null)
	controller = PlayerController.new()
	enable_interactions(true)


func on_enter_vehicle(vehicle: Vehicle) -> void:
	enter_vehicle.emit(vehicle)
	controller = VehicleController.new(vehicle)


func on_exit_vehicle(_vehicle: Vehicle) -> void:
	controller = PlayerController.new()


func on_focus_on_display(display_interactable: DisplayInteractable) -> void:
	camera_rig.lock(true)
	var display_marker := display_interactable.focus_marker
	camera_rig.set_mount(display_marker)
	controller = DisplayController.new(display_interactable.display)
	enable_interactions(false)


# Called when the inventory handler emits focus signal.
func on_inventory_focus(is_focused: bool) -> void:
	enable_interactions(not is_focused)


# Lock camera rotation and prevent body from turning.
func on_lock_camera(lock: bool) -> void:
	camera_rig.lock(lock)
	movement_handler.is_y_rotation_locked = lock


func toggle_inventory() -> void:
	inventory_handler.toggle_view_inventory()
	
	if inventory_handler.visible: enable_interactions(false)
	else: enable_interactions(true)


func zoom(direction: int) -> void:
	if inventory_handler.is_holding_light: inventory_handler.focus_light(direction)
