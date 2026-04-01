class_name PlayerController
extends Controller


const FOCUS_PHONE_TIME_LIMIT := 0.75 # How long player has to hold down the phone button to focus into the phone.
const MESH_ROTATE_SPEED := 3.0


var focus_phone_time := 0.0 # How long the phone button has been held down.
var is_holding_focus_phone := false


# Calculate player movement direction based off movement input and camera rig basis.
func get_movement_direction(player: Player) -> Vector3:
	if movement_input == Vector2.ZERO:
		return Vector3.ZERO
	
	var movement_dir: Vector3 = player.camera_rig.global_transform.basis.x * movement_input.x
	movement_dir += player.camera_rig.global_transform.basis.z * movement_input.y
	
	return movement_dir


func handle_input(player: Player, event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("interact"):
			return
		
		if event.is_action_pressed("light"):
			player.inventory_handler.toggle_light()
			return
		
		if event.is_action_pressed("crouch"):
			player.crouch_pressed.emit()
			return
		
		if event.is_action_pressed("jump"):
			player.jump_pressed.emit()
			return
		
		if event.is_action_pressed("phone"):
			focus_phone_time = 0.0
			is_holding_focus_phone = true
			return
		elif event.is_action_released("phone"):
			if focus_phone_time < FOCUS_PHONE_TIME_LIMIT: player.inventory_handler.toggle_equip_phone()
			is_holding_focus_phone = false
			return
		
		if event.is_action_pressed("inventory"):
			player.toggle_inventory()
			return
	
	if event is InputEventMouseButton:
		if event.is_action_pressed("interact"):
			player.interaction_handler.interact()
			return
		elif event.is_action_released("interact"):
			player.interaction_handler.release()
			return
		
		if event.is_action_pressed("throw"):
			player.interaction_handler.throw()
			return
		elif event.is_action_released("throw"):
			player.interaction_handler.throw()
			return
		
		if event.is_action_released("zoom_in"):
			player.zoom(1)
			return
		elif event.is_action_released("zoom_out"):
			player.zoom(-1)
			return
	
	if event is InputEventMouseMotion:
		player.mouse_dir = event.relative
		player.rotation_y_direction = -player.mouse_dir.x * mouse_sensitivity
		player.camera_rotate_x.emit(player.mouse_dir.y * mouse_sensitivity / 100)


func physics_update(player: Player, delta: float) -> void:
	super.physics_update(player, delta)
	
	player.movement_direction = get_movement_direction(player)
	
	#rotate_mesh(player, player.movement_direction, delta) # TODO: can be used later for head mesh looking/rotating separate from body.
	
	if is_holding_focus_phone:
		if focus_phone_time >= FOCUS_PHONE_TIME_LIMIT:
			player.inventory_handler.focus_phone()
			is_holding_focus_phone = false
		else: focus_phone_time += delta
	


# Rotate player mesh to face a direction.
func rotate_mesh(player: Player, direction: Vector3, delta: float) -> void:
	if direction == Vector3.ZERO: return
	
	var new_rotation := Util.yaw_towards_direction(player.mesh, direction)
	player.mesh.rotation.y -= new_rotation * MESH_ROTATE_SPEED * delta
	
	# Turn body to follow camera when camera rig starts to turn too far away.
	var center_yaw: float = player.camera_rig.base.rotation.y
	var angle := deg_to_rad(60)
	if direction == Vector3.ZERO: angle += deg_to_rad(20)
	player.mesh.global_rotation.y = Util.clamp_yaw(player.mesh.global_rotation.y, center_yaw, angle)


func update(_player: Player, _delta: float) -> void:
	pass
