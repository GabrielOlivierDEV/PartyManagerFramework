@tool
@icon("res://addons/PartyManagerFramework/icon.svg")
extends Node

@export var MAX_PARTY_MEMBERS := 4

func _ready() -> void:
	PartyManager.MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS
