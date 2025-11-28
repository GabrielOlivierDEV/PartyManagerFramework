@tool
extends EditorPlugin

const PARTYMANAGER_NAME := "PartyManager"
const PARTYMANAGER_PATH := "res://addons/PartyManagerFramework/partymanager.gd"
const DEFAULT_DEADZONE := 0.5

func _enable_plugin() -> void:
	_add_autoload(PARTYMANAGER_NAME, PARTYMANAGER_PATH)
	add_custom_type("PartyManager", "Node", preload("res://addons/PartyManagerFramework/partymanager_helper.gd"), preload("res://addons/PartyManagerFramework/icon.svg"))
	add_default_input_actions()

func _disable_plugin() -> void:
	remove_custom_type("PartyManager")
	_remove_autoload(PARTYMANAGER_NAME)

func _add_autoload(name: String, path: String) -> void:
	if not ProjectSettings.has_setting("autoload/" + name):
		add_autoload_singleton(name, path)

func _remove_autoload(name: String) -> void:
	if ProjectSettings.has_setting("autoload/" + name):
		remove_autoload_singleton(name)

func add_default_input_actions() -> void:
	# UP (W + ArrowUp)
	_add_action_if_not_exists("move_up", [
		_create_key_event(KEY_W),
		_create_key_event(KEY_UP)
	])

	# DOWN (S + ArrowDown)
	_add_action_if_not_exists("move_down", [
		_create_key_event(KEY_S),
		_create_key_event(KEY_DOWN)
	])

	# LEFT (A + ArrowLeft)
	_add_action_if_not_exists("move_left", [
		_create_key_event(KEY_A),
		_create_key_event(KEY_LEFT)
	])

	# RIGHT (D + ArrowRight)
	_add_action_if_not_exists("move_right", [
		_create_key_event(KEY_D),
		_create_key_event(KEY_RIGHT)
	])

	# RUN (Shift)
	_add_action_if_not_exists("run", [
		_create_key_event(KEY_SHIFT)
	])

	ProjectSettings.save()

func _add_action_if_not_exists(action_name: String, events: Array) -> void:
	var path := "input/%s" % action_name
	if ProjectSettings.has_setting(path):
		return
	ProjectSettings.set_setting(path, {
		"deadzone": DEFAULT_DEADZONE,
		"events": events
	})


func _create_key_event(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	return ev
