class_name InteractionDisplay extends Control

@export var dot: TextureRect
@export var circle: TextureRect
@export var locked: TextureRect
@export var unlocked: TextureRect
@export var light_on: TextureRect
@export var light_off: TextureRect
@export var lock_door: TextureRect
@export var unlock_door: TextureRect
@export var no_key: TextureRect

enum CURRENT_DISPLAY {
	NONE,
	INTERACT,
	LOCK,
	LIGHT,
	USE_KEY
}
var current_display := CURRENT_DISPLAY.NONE:
	set(next_display):
		if current_display == next_display: return
		match current_display:
			CURRENT_DISPLAY.INTERACT:
				dot.hide()
				circle.hide()
			CURRENT_DISPLAY.LOCK:
				locked.hide()
				unlocked.hide()
			CURRENT_DISPLAY.LIGHT:
				light_on.hide()
				light_off.hide()
			CURRENT_DISPLAY.USE_KEY:
				lock_door.hide()
				unlock_door.hide()
				no_key.hide()
		current_display = next_display

var interact_timer := Timer.new()

func _ready() -> void:
	add_child(interact_timer)
	interact_timer.autostart = false
	interact_timer.one_shot = true
	interact_timer.timeout.connect(Callable(_on_interact_timer_timeout))

func interact_display(value: bool) -> void:
	if value:
		current_display = CURRENT_DISPLAY.INTERACT
		if dot.visible == true or circle.visible == true: return
		dot.show()
		interact_timer.start(0.1)
	else:
		dot.hide()
		circle.hide()
		current_display = CURRENT_DISPLAY.NONE

func lock_display(is_locked: bool) -> void:
	if is_locked: # Door is locked.
		locked.show()
		unlocked.hide()
	else:
		locked.hide()
		unlocked.show()
	current_display = CURRENT_DISPLAY.LOCK

func light_display(is_on: bool) -> void:
	if is_on:
		light_on.show()
		light_off.hide()
	else:
		light_on.hide()
		light_off.show()
	current_display = CURRENT_DISPLAY.LIGHT

func use_key_display(has_key: bool, is_locked: bool) -> void:
	if not has_key: no_key.show()
	elif is_locked:
		lock_door.hide()
		unlock_door.show()
	else:
		lock_door.show()
		unlock_door.hide()
	current_display = CURRENT_DISPLAY.USE_KEY

func _on_interact_timer_timeout() -> void:
	if dot.visible == false: return
	
	dot.visible = false
	circle.visible = true
