class_name InventoryHandler
extends Control
# Manages player inventory slots, items and equipment.


signal focus(is_focused: bool)
signal lock_camera(lock: bool)


@export var inventory_slots: Array[InventorySlot]
@export var mobile_phone: MobilePhone


var flashlight: Flashlight
var is_focused_on_phone := false:
	set(value):
		is_focused_on_phone = value
		focus.emit(is_focused_on_phone)
var is_holding_light: bool:
	get(): return is_phone_equipped or flashlight
var is_phone_equipped := false
var keys: Array[int]


@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	pass
	#print(owner.name) Player


func add_to_inventory(item: Item) -> void:
	for slot in inventory_slots:
		if not slot.filled:
			var item_data: ItemData = item.item_data
			slot.fill(item_data)
			print(item.name + " picked up.")
			item.queue_free()
			return
	
	print("No slots in inventory. Cannot pickup " + item.name)


func focus_light(direction: int) -> void:
	if is_phone_equipped: mobile_phone.focus_light(direction)
	elif flashlight: flashlight.focus(direction)


func focus_phone() -> void:
	if is_focused_on_phone: # If currently focused on phone, stop.
		animation_player.play_backwards("phone_focus")
		is_focused_on_phone = false
		return
	
	if not is_phone_equipped: # First take out phone.
		toggle_equip_phone()
		await animation_player.animation_finished
	
	animation_player.play("phone_focus")
	is_focused_on_phone = true


func toggle_equip_phone() -> void:
	if is_focused_on_phone: # If currently focused on phone, stop.
		animation_player.play_backwards("phone_focus")
		await animation_player.animation_finished
		is_focused_on_phone = false
		return
	
	if is_phone_equipped:
		if mobile_phone.is_light_on: mobile_phone.toggle_light()
		animation_player.play_backwards("phone_take_out")
		is_phone_equipped = false
	else:
		animation_player.play("phone_take_out")
		is_phone_equipped = true
	return


func toggle_light() -> void:
	if is_phone_equipped: mobile_phone.toggle_light()
	elif flashlight: flashlight.toggle()


func toggle_view_inventory() -> void:
	visible = not visible
	
	if visible:
		lock_camera.emit(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	else:
		lock_camera.emit(false)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
