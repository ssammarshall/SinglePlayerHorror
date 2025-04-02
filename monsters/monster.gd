class_name Monster extends CharacterBody3D

@export var nav_agent: NavigationAgent3D
@export var wait_timer: Timer
@export var patrol_path: Array[Marker3D] = []
var patrol_path_index := 0

@export var target: Player:
	set(t):
		target = t
@export var raycast_to_target: RayCast3D
var target_last_known_pos := Vector3.ZERO

@export_group("Statistics")
@export var speed := 5.5
@export var light_detection_minimum := 0.04
@export var max_sight_range := 20.0

@onready var target_detection: TargetDetection = $TargetDetection

enum State {
	Wait,
	Patrol,
	Investigate,
	Hunt,
	Stalk,
	Chase
}
var state := State.Patrol

var movement_dir := Vector3.ZERO

func _ready() -> void:
	nav_agent.target_position = patrol_path[0].global_position
	target_detection.target = target

func _physics_process(delta: float) -> void:
	velocity.y -= 9.8 * delta # Gravity
	
	match state:
		State.Wait:
			if wait_timer.is_stopped():
				wait_timer.start()
			return
		State.Patrol:
			if nav_agent.is_navigation_finished():
				state = State.Wait
				return
			
		State.Hunt:
			if not target_last_known_pos == Vector3.ZERO: nav_agent.target_position = target_last_known_pos
		State.Stalk:
			pass
		State.Chase:
			nav_agent.target_position = target.global_position
	var target_pos := nav_agent.get_next_path_position()
	movement_dir = global_position.direction_to(target_pos)
	movement_dir.y = 0
	velocity = lerp(velocity, movement_dir * speed, speed / 1.5  * delta)
	
	if movement_dir.length_squared() > 0.1:
		look_at(global_position + movement_dir)
	
	move_and_slide()


func _on_hearing_body_entered(body: Node3D) -> void:
	if body is Player:
		return


func _on_hearing_body_exited(body: Node3D) -> void:
	if body == target:
		return


func _on_vision_body_entered(body: Node3D) -> void:
	if body is Player:
		var player := body as Player
		if player.detection_level > light_detection_minimum:
			state = State.Chase
			print("its coming to kill you")


func _on_vision_body_exited(body: Node3D) -> void:
	if body == target:
		target_last_known_pos = body.global_position


func _on_wait_timer_timeout() -> void:
	if not nav_agent.is_navigation_finished(): return
	
	patrol_path_index += 1
	if patrol_path_index >= patrol_path.size(): patrol_path_index = 0
	nav_agent.target_position = patrol_path[patrol_path_index].global_position
	state = State.Patrol
