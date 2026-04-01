class_name DisplayController
extends Controller


var display: Display


func _init(_display) -> void:
	display = _display


func handle_input(player: Player, event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("back"):
			player.exit_focus()
		
		if event.is_action_pressed("exit"):
			player.exit_focus()
	
	if event is InputEventMouseMotion:
		display.move_cursor(event.relative)


func physics_update(player: Player, delta: float) -> void:
	super.physics_update(player, delta)


func update(_player: Player, _delta: float) -> void:
	pass
