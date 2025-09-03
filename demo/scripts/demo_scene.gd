extends Control

# -----------------------
# This is a demo scene to showcase the PartyManager functionality.
# It allows adding characters to the party and switching between them.
# ------------------------
@onready var blue = $Blue
@onready var pink = $Pink
@onready var purple = $Purple
@onready var orange = $Orange

# Flags to determine if the player wants to switch to a character after adding them to the party
var play_as_purple = false
var play_as_pink = false
var play_as_orange = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PartyManager.play_as(blue)

# Functions to handle adding characters to the party and switching control
func _on_add_pink_to_party_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	PartyManager.add_to_party(pink) # Add pink to the party

	if not play_as_pink:
		return
	
	if pink.is_on_party:
		PartyManager.play_as(pink) # Switch control to pink if the player chose to

func _on_add_purple_to_party_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	PartyManager.add_to_party(purple) # Add purple to the party
	
	if not play_as_purple:
		return
		
	if purple.is_on_party:
		PartyManager.play_as(purple) # Switch control to pink if the player chose to


func _on_add_orange_to_party_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	PartyManager.add_to_party(orange) # Add orange to the party

	if not play_as_orange:
		return
	
	if orange.is_on_party:
		PartyManager.play_as(orange) # Switch control to pink if the player chose to

func _on_play_as_blue_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	PartyManager.play_as(blue) # Switch control to blue

func _on_add_purple_to_party_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	play_as_purple = true # Set flag to switch to purple after adding
	$Add_Purple_To_Party/Add.visible = false
	$Add_Purple_To_Party/Play.visible = true

func _on_add_pink_to_party_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	play_as_pink = true # Set flag to switch to pink after adding
	$Add_Pink_To_Party/Add.visible = false
	$Add_Pink_To_Party/Play.visible = true

func _on_add_orange_to_party_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	play_as_orange = true # Set flag to switch to orange after adding
	$Add_Orange_To_Party/Add.visible = false
	$Add_Orange_To_Party/Play.visible = true
