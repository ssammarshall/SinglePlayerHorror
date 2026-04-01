class_name VehicleController
extends Controller


var vehicle: Vehicle


func _init(_vehicle: Vehicle) -> void:
	vehicle = _vehicle


func handle_input(player: Player, event: InputEvent) -> void:
	if not vehicle:
		push_error("VehicleController called handle_input without a vehicle assigned.")
		return
	
	if event is InputEventKey:
		if event.is_action_pressed("light"):
			vehicle.toggle_headlights()
			return
		
		if event.is_action_pressed("park"):
			if vehicle.current_speed > 0.1: return # Going too fast.
			
			if not vehicle.current_state == Vehicle.State.PARK: vehicle.park()
			else: player.exit_vehicle.emit(vehicle)
			return
		
		if event.is_action_pressed("shift_gear_down"):
			if vehicle.current_speed > 0.1: return # Going too fast.
			vehicle.shift_gear_down()
			return
		
		if event.is_action_pressed("shift_gear_up"):
			if vehicle.current_speed > 0.1: return # Going too fast.
			vehicle.shift_gear_up()
			return
	
	if event is InputEventMouseMotion:
		player.mouse_dir = event.relative
		player.camera_rotate_y.emit(-player.mouse_dir.x * mouse_sensitivity / 100)
		player.camera_rotate_x.emit(player.mouse_dir.y * mouse_sensitivity / 100)


func physics_update(player: Player, delta: float) -> void:
	super.physics_update(player, delta)
	
	if not vehicle:
		push_error("VehicleController called physics_update without a vehicle assigned.")
		return
	
	vehicle.acceleration_direction = movement_input.y
	vehicle.turn_direction = -movement_input.x
	
	var vehicle_velocity := vehicle.linear_velocity
	vehicle_velocity.y = 0.0
	
	# Rotate player mesh.
	player.mesh.global_rotation.y = vehicle.global_rotation.y
	player.mesh.global_rotation_degrees.y += 180 # TODO test_van is facing backwards. normal van facing correct directin can delete this line


func update(_player: Player, _delta: float) -> void:
	if not vehicle:
		push_error("VehicleController called update without a vehicle assigned.")
		return
