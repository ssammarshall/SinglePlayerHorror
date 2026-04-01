class_name TouchScreenDisplay
extends Display


@export var target: Node3D


var is_enabled := false
var is_on := true


func _ready() -> void:
	super._ready()


# Turn on or off the power for the display.
func activate(power: bool) -> void:
	is_on = power


# Enable or disable the display allowing for player interaction.
func interact(enabled: bool) -> void:
	is_enabled = enabled
