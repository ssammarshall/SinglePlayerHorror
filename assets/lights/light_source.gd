class_name LightSource extends Node3D

@export var light: SpotLight3D
@export var light_bulb: MeshInstance3D
@export var light_switch: ToggleInteractable

@export_group("Variables")
@export var light_intensity: float = 1
@export var light_range: float = 15
@export var angle: float = 55

func _ready() -> void:
	light.set_layer_mask_value(20, true) # light detection layer.
	light_switch.toggled.connect(Callable(_on_light_switch_toggled))

func _physics_process(_delta: float) -> void:
	light.light_energy = light_intensity
	light.spot_range = light_range
	light.spot_angle = angle

func _on_light_switch_toggled(value: bool) -> void:
	light.visible = value
