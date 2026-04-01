class_name Display
extends Sprite3D


@export var cursor: Control
@export var sub_viewport: SubViewport


var display_size: Vector2


func _ready() -> void:
	display_size = sub_viewport.size


func move_cursor(direction: Vector2) -> void:
	cursor.position += direction
	cursor.position.x = clampf(cursor.position.x, 0.0, display_size.x - cursor.size.x)
	cursor.position.y = clampf(cursor.position.y, 0.0, display_size.y - cursor.size.y)
