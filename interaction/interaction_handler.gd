class_name InteractionHandler extends RayCast3D

const MAX_GRAB_DISTANCE := 2.5

@export var player: Player
@export var interaction_display: InteractionDisplay
@export var marker: Marker3D

@export_group("Throwing")
@export var throw_charge_speed := 1.25
@export var max_throw_charge_multiplier := 2.0
var current_throw_charge_amount := 0.0
var is_charging_throw := false

var dragable_object: DragInteractable:
	set(new_object):
		if dragable_object != null: dragable_object.is_held = false
		dragable_object = new_object
		if dragable_object != null:
			dragable_object.is_held = true
			is_handling_object = true
		else: is_handling_object = false
var carriable_object: CarryInteractable:
	set(new_object):
		if carriable_object != null: carriable_object.is_held = false
		carriable_object = new_object
		if carriable_object != null:
			carriable_object.is_held = true
			is_handling_object = true
		else: is_handling_object = false
var is_handling_object := false
var item: Item:
	set(new_item):
		if item: item.highlight(false)
		if not new_item == null: new_item.highlight(true)
		item = new_item
var keys: Array[int]

var mouse_dir := Vector2.ZERO

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	_handle_charge_throwing(delta)
	if is_handling_object: _handle_objects()
	else: _handle_interaction_display()

func _handle_charge_throwing(delta: float) -> void:
	if is_charging_throw:
		current_throw_charge_amount += throw_charge_speed * delta
		if current_throw_charge_amount > max_throw_charge_multiplier:
			current_throw_charge_amount = max_throw_charge_multiplier
		marker.position.z += delta / 2
		marker.position.z = clampf(marker.position.z, -1.5, -1)

func _handle_objects() -> void:
	if dragable_object:
		var cam_basis := player.camera_rig.global_transform.basis
		var move_direction := cam_basis.z * mouse_dir.y
		move_direction += cam_basis.x * mouse_dir.x
		var player_input_direction := player.input_dir * cam_basis * 10
		dragable_object.manipulate(move_direction + player_input_direction)
		mouse_dir = Vector2.ZERO
		distance_check(dragable_object)
	elif carriable_object:
		var pos := marker.global_position
		carriable_object.manipulate(pos)
		distance_check(carriable_object)

func _handle_interaction_display() -> void:
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
		if is_key_side: interaction_display.use_key_display(keys.has(lock.key_id), lock.is_toggled)
		else: interaction_display.lock_display(lock.is_toggled)
	elif collision is ToggleInteractable:
		var light := collision as ToggleInteractable					# Currently only toggle is light switch. probably should change later when more added.
		interaction_display.light_display(light.is_toggled)
	elif collision is CarryInteractable or collision is DragInteractable:
		interaction_display.interact_display(true)
	else: interaction_display.interact_display(false)
	
	item = null

func distance_check(object: Node3D) -> void:
	var distance := (global_position - object.global_position).length()
	if distance > MAX_GRAB_DISTANCE: release()

func interact() -> void:
	if not is_colliding(): return
	
	var collision: Node3D = get_collider()
	if collision is Item:
		player.inventory.add_to_inventory(collision)
	elif collision is DragInteractable:
		dragable_object = collision
		interaction_display.interact_display(false)
		SignalBus.lock_camera.emit(true)
	elif collision is CarryInteractable:
		carriable_object = collision
		interaction_display.interact_display(false)
	elif collision is ToggleInteractable:
		collision.toggle()

func release() -> void:
	if dragable_object:
		dragable_object = null
		SignalBus.lock_camera.emit(false)
	elif carriable_object:
		carriable_object.drop()
		carriable_object = null

func throw() -> void:
	if not is_charging_throw and is_handling_object:
		is_charging_throw = true
		return
	
	#camera_rig.forward 
	var direction := player.camera_rig.forward * player.throw_strength * (1 + current_throw_charge_amount)
	if dragable_object:
		dragable_object.apply_central_impulse(direction)
		release()
	elif carriable_object:
		carriable_object.throw(direction)
		carriable_object = null
	
	current_throw_charge_amount = 0.0
	marker.position = target_position
	is_charging_throw = false
