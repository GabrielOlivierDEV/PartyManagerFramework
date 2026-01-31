@tool
@icon("res://addons/PartyManagerFramework/icon.svg")
extends Node

# Maximum number of members allowed in the party
@export var MAX_PARTY_MEMBERS := 4

# --- Constants ---
const NO_PARTY_POSITION := -1 # Marker used when a character is not in the party
const PLAYING_AS_MSG := "Now playing as: "
const NPC_ADDED_MSG := "NPC added to the party: "
const NPC_REMOVED_MSG := "NPC removed from party: "
const MAX_PARTY_MSG := "Max party! It was not possible to add: "
const PARTY_CLOSED_MSG := "Party closed. No active player or NPC followers remain."
const POSITION_MSG := ", position: "

# Array holding all characters currently in the party (followers)
var party_members: Array[Character] = []

# Array holding the currently playable character (only one expected)
var current_character: Array[Character] = []

# -------------------------------------------------------------------
# --- Adds a character to the party ---
# -------------------------------------------------------------------
func add_to_party(character: CharacterBody2D) -> void:
	# Ignore if already in the party
	if character in party_members:
		return

	# Do not allow adding more than max limit
	if party_members.size() >= MAX_PARTY_MEMBERS:
		print(MAX_PARTY_MSG, character.name)
		return

	# Add character and set properties
	party_members.append(character)
	character.is_on_party = true
	character.party_position = party_members.size() - 1
	character.place_in_party_position()

	print(NPC_ADDED_MSG, character.name, POSITION_MSG, character.party_position)

# -------------------------------------------------------------------
# --- Removes a character from the party ---
# -------------------------------------------------------------------
func remove_from_party(character: CharacterBody2D) -> void:
	# Ignore if not in the party
	if character not in party_members:
		return

	# Remove character and reset state
	party_members.erase(character)
	character.is_on_party = false
	character.party_position = NO_PARTY_POSITION

	# Reassign positions for remaining party members
	reorganize_party()

	print(NPC_REMOVED_MSG, character.name)

# -------------------------------------------------------------------
# --- Switch control to another character ---
# -------------------------------------------------------------------
func play_as(character: CharacterBody2D) -> void:
	# --- Variables to track old character state ---
	var old_char: CharacterBody2D = null
	var old_was_in_party := false

	# --- Already controlling this character ---
	if current_character.has(character):
		return

	# --- If someone is currently playable ---
	if current_character.size() > 0:
		old_char = current_character[0]
		old_was_in_party = old_char in party_members

		# Old character becomes follower
		old_char.playable = false
		old_char.should_follow = true
		old_char.is_on_party = true

		# If the new character is already in party, remove it
		if character in party_members:
			party_members.erase(character)

		# Ensure old char is in party
		if not old_was_in_party:
			party_members.append(old_char)

	else:
		# First playable character EVER
		if character in party_members:
			party_members.erase(character)

	# New active character
	character.is_on_party = false
	character.playable = true
	character.should_follow = false

	party_members.insert(0, character)

	# --- Update party order and positions ---
	reorganize_party()

	# --- Update groups ---
	if old_char and old_char.is_inside_tree():
		old_char.remove_from_group("player")
		old_char.add_to_group("npcs")

	if character.is_inside_tree():
		character.remove_from_group("npcs")
		character.add_to_group("player")

	# --- Update current character list ---
	current_character.clear()
	current_character.append(character)

	print(PLAYING_AS_MSG, character.name)

# -------------------------------------------------------------------
# --- Updates party positions ---
# -------------------------------------------------------------------
func reorganize_party() -> void:
	for i in range(party_members.size()):
		var member = party_members[i]
		member.party_position = i
		member.place_in_party_position()

# -------------------------------------------------------------------
# --- Close the entire party ---
# -------------------------------------------------------------------
func close_party() -> void:
	# --- Clean current_character safely ---
	if current_character.size() > 0:
		var player_char := current_character[0]

		# Reset state
		player_char.playable = false
		player_char.should_follow = false
		player_char.is_on_party = false

		# Update groups
		if player_char.is_inside_tree():
			player_char.remove_from_group("player")
			player_char.add_to_group("npcs")

	### Avoid ghost references
	current_character.clear()

	# --- Safely reset party members ---
	for member in party_members:
		member.is_on_party = false
		member.playable = false
		member.should_follow = false
		member.party_position = NO_PARTY_POSITION

		# Update groups
		if member.is_inside_tree():
			member.remove_from_group("player")
			member.add_to_group("npcs")

	### Ensure no nodes remain referenced
	party_members.clear()

	print(PARTY_CLOSED_MSG)

# -------------------------------------------------------------------
# --- Scene change cleanup ---
# -------------------------------------------------------------------
func change_scene():
	### Guarantee no references to nodes remain
	current_character.clear()
	party_members.clear()

# -------------------------------------------------------------------
# --- Query functions ---
# -------------------------------------------------------------------
func is_in_party(character_id: String) -> bool:
	# Check if a character with the given ID is in the party
	for member in party_members:
		if member.character_id == character_id:
			return true
	return false

func get_current_player() -> String:
	# Return the currently playable character, if any
	if current_character.size() > 0:
		return current_character[0].name
	return ""

func get_party_members() -> Array[String]:
	# Return a list of names of all party members
	var names: Array[String] = []
	for member in party_members:
		names.append(member.name)
	return names

func get_party_size() -> int:
	# Return the current number of party members
	return party_members.size()