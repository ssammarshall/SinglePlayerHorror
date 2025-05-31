class_name Inventory extends Control

@export var inventory_slots: Array[InventorySlot]

func add_to_inventory(item: Item) -> void:
	for slot in inventory_slots:
		if not slot.filled:
			var item_data: ItemData = item.item_data
			slot.fill(item_data)
			print(item.name + " picked up.")
			item.queue_free()
			return
	
	print("No slots in inventory. Cannot pickup " + item.name)

func toggle() -> void:
	visible = not visible
	if visible:
		SignalBus.lock_camera.emit(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	else:
		SignalBus.lock_camera.emit(false)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
