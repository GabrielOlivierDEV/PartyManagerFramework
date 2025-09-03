@tool
@icon("res://addons/PartyManagerFramework/icon.svg")
extends Node

@export var Max_Party_Members := 4

func _ready() -> void:
	PartyManager.MAX_PARTY_MEMBERS = Max_Party_Members
