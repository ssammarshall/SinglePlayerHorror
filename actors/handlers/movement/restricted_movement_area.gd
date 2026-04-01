class_name RestrictedMovementArea
extends Area3D
# Area that restricts the movement of actors passing through it.
# Uses two Marker3D as checkpoints that actors can move between while in the area.
#
# IMPORTANT: Must have markers be on the edges of the collision shape to properly determine enter/exit points.


@export var marker_1: Marker3D
@export var marker_2: Marker3D


var distance := 10
var is_disabled := false
var steps: int = 4


func _ready() -> void:
	body_entered.connect(Callable(on_body_entered))
	body_exited.connect(Callable(on_body_exited))


# Find closest marker to given position.
func find_closest_marker(node_position: Vector3) -> Marker3D:
	var distance_1 := node_position.distance_squared_to(marker_1.global_position)
	var distance_2 := node_position.distance_squared_to(marker_2.global_position)
	
	return marker_1 if distance_1 < distance_2 else marker_2


func get_direction(movement_direction: Vector3) -> Vector3:
	# Compute direction vectors toward both markers.
	var to_prev := (marker_1.global_position - marker_2.global_position).normalized()
	var to_next := (marker_2.global_position - marker_1.global_position).normalized()

	# Compare angles with movement direction.
	var angle_prev := movement_direction.angle_to(to_prev)
	var angle_next := movement_direction.angle_to(to_next)
	
	if angle_prev < angle_next:
		print(marker_1.name)
		return to_prev * distance / steps
	else:
		print(marker_2.name)
		return to_next * distance / steps


func is_area_blocked(camera: Camera3D, mask: int = 1) -> bool:
	var raycast_result := Util.raycast(camera, marker_1.global_position, marker_2.global_position, mask)
	return raycast_result.has("collider")


func on_body_entered(body: Node3D) -> void:
	if is_disabled: return
	if body is not Player: return
	
	var player := body as Player
	player.movement_restricted.emit(true, self)


func on_body_exited(body: Node3D) -> void:
	if body is not Player: return
	
	var player := body as Player
	player.movement_restricted.emit(false, self)
