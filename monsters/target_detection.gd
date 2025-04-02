class_name TargetDetection extends RayCast3D

@export var target: Node3D

@export var light_detection_minimum := 0.04
@export var max_sight_range := 20.0

@export var update_speed := 1.0
var update_timer := Timer.new()

@export var x_min := 1.0

func _ready() -> void:
	update_timer.wait_time = update_speed
	update_timer.autostart = true
	add_child(update_timer)
	update_timer.timeout.connect(Callable(_on_update_timer_timeout))

func _physics_process(_delta: float) -> void:
	if not target: return
	var direction_to_target := (global_position - target.global_position)
	print(-global_transform.basis.z.angle_to(direction_to_target)) # this

func _on_update_timer_timeout() -> void:
	pass
