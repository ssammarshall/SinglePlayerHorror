class_name MobilePhone
extends Node3D


var is_light_on: bool:
	get(): return flashlight.visible


@onready var flashlight: Flashlight = $Flashlight


func focus_light(direction: int) -> void:
	flashlight.focus(direction)


func toggle_light() -> void:
	flashlight.toggle()
