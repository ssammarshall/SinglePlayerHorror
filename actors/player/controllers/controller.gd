@abstract
class_name Controller
extends RefCounted


var mouse_sensitivity := 1.0
var movement_input := Vector2.ZERO


func get_movement_input() -> Vector2:
	return Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("backward") - Input.get_action_strength("forward")
	)


func handle_input(_player: Player, _event: InputEvent) -> void:
	pass


func physics_update(_player: Player, _delta: float) -> void:
	movement_input = get_movement_input()


func update(_player: Player, _delta: float) -> void:
	pass
