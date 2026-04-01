class_name StopsMenu
extends ItemList
# Menu for listing, displaying and selecting all stops on a delivery vehicle's route.


const TEMP_STOPS: Array[String] = [
	"2135 S ELLIOT RD 4 pkgs",
	"2141 S ELLIOT RD 2 pkgs",
	"2144 S ELLIOT RD 3 pkgs",
	"2156 S ELLIOT RD 2 pkgs",
	"2160 S ELLIOT RD 1 pkg",
]


func _ready() -> void:
	populate_stops(TEMP_STOPS)


func populate_stops(stops: Array[String]) -> void:
	for stop in stops:
		add_item(stop)
