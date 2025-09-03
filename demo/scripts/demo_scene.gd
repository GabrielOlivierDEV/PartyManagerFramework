extends Node2D

@onready var blue = $Blue
@onready var pink = $Pink
@onready var purple = $Purple
@onready var orange = $Orange

func _ready() -> void:
	PartyManager.play_as(blue)

func _on_add_pink_to_party_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	PartyManager.add_to_party(pink)

func _on_add_purple_to_party_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	PartyManager.add_to_party(purple)


func _on_add_orange_to_party_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	PartyManager.add_to_party(orange)
