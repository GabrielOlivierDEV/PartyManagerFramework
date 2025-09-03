@tool
extends EditorPlugin

const PARTYMANAGER_NAME := "PartyManager"
const PARTYMANAGER_PATH := "res://addons/PartyManagerFramework/partymanager.gd"

func _enable_plugin() -> void:
	_add_autoload(PARTYMANAGER_NAME, PARTYMANAGER_PATH)
	add_custom_type("PartyManager", "Node", preload("res://addons/PartyManagerFramework/partymanager_helper.gd"), preload("res://addons/PartyManagerFramework/icon.svg"))

func _disable_plugin() -> void:
	remove_custom_type("PartyManager")
	_remove_autoload(PARTYMANAGER_NAME)

func _add_autoload(name: String, path: String) -> void:
	if not ProjectSettings.has_setting("autoload/" + name):
		add_autoload_singleton(name, path)

func _remove_autoload(name: String) -> void:
	if ProjectSettings.has_setting("autoload/" + name):
		remove_autoload_singleton(name)
