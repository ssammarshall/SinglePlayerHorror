class_name InventorySlot extends TextureRect

var filled: bool = false

func fill(item_data: ItemData) -> void:
	texture = item_data.image
	filled = true
