class_name InteractionHandler
extends RayCast3D
# Raycast from a camera rig to interact with RigidBody3Ds and Area3Ds.


signal enter_vehicle(vehicle: Vehicle)
signal focus_on_display(display: DisplayInteractable)
signal lock_camera(lock: bool)
signal pickup_item(item: Item)


const MAX_GRAB_DISTANCE := 2.5


@export var interaction_display: InteractionDisplay
@export_group("Throwing")
@export var throw_strength := 15.0
@export var throw_charge_speed := 1.25
@export var max_throw_charge_multiplier := 2.0


var carriable_object: CarryInteractable:
	set(new_object):
		if carriable_object != null: carriable_object.is_held = false
		carriable_object = new_object
		if carriable_object != null:
			carriable_object.hold(true)
			object_marker.global_rotation = carriable_object.global_rotation
			is_handling_object = true
		else:
			object_marker.global_rotation = Vector3.ZERO
			is_handling_object = false
var current_throw_charge_amount := 0.0
var dragable_object: DragInteractable:
	set(new_object):
		if dragable_object != null: dragable_object.is_held = false
		dragable_object = new_object
		if dragable_object != null:
			dragable_object.hold(true)
			is_handling_object = true
		else: is_handling_object = false
var is_charging_throw := false
var is_disabled := false:
	set(value):
		is_disabled = value
		if is_disabled: interaction_display.interact_display(false)
var is_handling_object := false
var is_rotating_object := false # TODO
var item: Item:
	set(new_item):
		if item: item.highlight(false)
		if not new_item == null: new_item.highlight(true)
		item = new_item
var mouse_dir := Vector2.ZERO
var player: Player
var rotate_held := false


@onready var object_anchor: Node3D = $ObjectAnchor
@onready var object_marker: Marker3D = $ObjectAnchor/ObjectMarker


func _physics_process(delta: float) -> void:
	if is_disabled: return
	
	if Input.is_action_pressed("rotate"):
		rotate_held = true
		lock_camera.emit(true)
	elif rotate_held:
		rotate_held = false
		lock_camera.emit(false)
	
	if is_charging_throw: handle_charge_throwing(delta)
	if is_handling_object: handle_objects()
	else: handle_interaction_display()
	
	if rotate_held:
		var pitch := mouse_dir.y * delta
		var yaw := mouse_dir.x * delta
		mouse_dir = Vector2.ZERO
		
		object_anchor.rotate(Vector3.RIGHT, pitch)
		object_anchor.rotate(Vector3.UP, yaw)


func _ready() -> void:
	await owner.ready
	
	player = owner as Player
	assert(player != null)
	
	collision_mask = (1 << 32) - 1 # All 32 layers.


# If object is too far away from current position, release current object.
func distance_check(object: Node3D) -> void:
	var distance := (global_position - object.global_position).length()
	if distance > MAX_GRAB_DISTANCE: release()


# Increase charge timer by delta and move object anchor position
# to visually indicate current charge amount.
func handle_charge_throwing(delta: float) -> void:
	current_throw_charge_amount += throw_charge_speed * delta
	if current_throw_charge_amount > max_throw_charge_multiplier:
		current_throw_charge_amount = max_throw_charge_multiplier
	object_anchor.position.z += delta / 2
	object_anchor.position.z = clampf(object_anchor.position.z, -1.5, -1)


# Toggle current interaction display texture to represent current raycast collision.
func handle_interaction_display() -> void:
	if not is_colliding():
		interaction_display.interact_display(false)
		item = null
		return
	
	var collision := get_collider()
	if collision is Item:
		var this_item := collision as Item
		item = this_item
		interaction_display.interact_display(true)
		return
	elif collision is Lock:
		var lock := collision as Lock
		var is_key_side: bool = lock.is_key_side(global_position)
		var keys := player.inventory_handler.keys
		if is_key_side: interaction_display.use_key_display(keys.has(lock.key_id), lock.is_toggled)
		else: interaction_display.lock_display(lock.is_toggled)
	elif collision is ToggleInteractable:
		var light := collision as ToggleInteractable # TODO: Currently only toggle is light switch. probably should change later when more added.
		interaction_display.light_display(light.is_toggled)
	elif collision is CarryInteractable or collision is DragInteractable:
		interaction_display.interact_display(true)
	elif collision is DisplayInteractable:
		interaction_display.interact_display(true)
	elif collision is DriverSeat:
		interaction_display.interact_display(true)
	else: interaction_display.interact_display(false)
	
	item = null


# Manipulate current held object.
func handle_objects() -> void:
	if dragable_object:
		var cam_basis := player.camera_rig.global_transform.basis
		var move_direction := cam_basis.z * mouse_dir.y
		move_direction += cam_basis.x * mouse_dir.x
		var input_direction := player.movement_direction * cam_basis * 20
		dragable_object.manipulate(move_direction + input_direction)
		mouse_dir = Vector2.ZERO
		distance_check(dragable_object)
	elif carriable_object:
		var pos := object_marker.global_position
		carriable_object.manipulate(pos)
		carriable_object.global_rotation = object_marker.global_rotation
		distance_check(carriable_object)


# Determine current raycast collision and interact with it.
func interact() -> void:
	if is_disabled: return
	if not is_colliding(): return
	
	var collision: Object = get_collider()
	if collision is Item:
		pickup_item.emit(collision as Item)
	elif collision is DragInteractable:
		dragable_object = collision as DragInteractable
		interaction_display.interact_display(false)
		lock_camera.emit(true)
	elif collision is CarryInteractable:
		carriable_object = collision as CarryInteractable
		interaction_display.interact_display(false)
	elif collision is ToggleInteractable:
		var toggle_interactable := collision as ToggleInteractable
		toggle_interactable.toggle()
	elif collision is DisplayInteractable:
		var display_interactable := collision as DisplayInteractable
		focus_on_display.emit(display_interactable)
	elif collision is DriverSeat:
		var driver_seat := collision as DriverSeat
		enter_vehicle.emit(driver_seat.vehicle)


# Let go of current held object.
func release() -> void:
	if dragable_object:
		dragable_object = null
		lock_camera.emit(false)
	elif carriable_object:
		carriable_object.drop()
		carriable_object = null


# If not currently charging a throw, begin to charge throw;
# otherwise throw the object based off current charge amount.
func throw() -> void:
	if not is_charging_throw and is_handling_object:
		is_charging_throw = true
		return
	
	var direction := player.camera_rig.forward * throw_strength * (1 + current_throw_charge_amount)
	if dragable_object:
		dragable_object.apply_central_impulse(direction)
		release()
	elif carriable_object:
		carriable_object.throw(direction)
		carriable_object = null
	
	current_throw_charge_amount = 0.0
	object_anchor.position = target_position
	is_charging_throw = false
