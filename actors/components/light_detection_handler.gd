class_name LightDetectionHandler extends SubViewport

@export var follow_target: Node3D # When following player, assign camera_rig as follow_target for better detection.
@export var light_detector: Node3D
@export var dark_adaptation_light: OmniLight3D
@export var update_timer: Timer
@onready var color_rect: ColorRect = $"../ui/ColorRect"

var da_max_energy := 1.5
var da_speed := 1.0

var light_level := 0.0

func _ready() -> void:
	debug_draw = Viewport.DEBUG_DRAW_LIGHTING # Make SubViewport render lighting only.
	set_update_mode(UpdateMode.UPDATE_ALWAYS)
	update_timer.timeout.connect(Callable(_on_update_timer_timeout))

func _process(delta: float) -> void:
	light_detector.global_position = follow_target.global_position
	
	if light_level < 0.03:
		dark_adaptation_light.light_energy = lerpf(dark_adaptation_light.light_energy, da_max_energy, da_speed * delta)
	else:
		dark_adaptation_light.light_energy = lerpf(dark_adaptation_light.light_energy, 0.0, da_speed * delta)

func get_average_color(texture: ViewportTexture) -> Color:
	var image := texture.get_image() # Get the Image of the input texture.
	image.resize(1, 1, Image.INTERPOLATE_LANCZOS) # Resize the image to one pixel.
	return image.get_pixel(0, 0) # Read the color of that pixel.

func _on_update_timer_timeout() -> void:
	var texture := get_texture()
	var color := get_average_color(texture)
	light_level = color.get_luminance()
	color_rect.color = color
