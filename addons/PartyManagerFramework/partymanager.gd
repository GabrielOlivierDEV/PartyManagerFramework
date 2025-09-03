@tool
@icon("res://addons/PartyManagerFramework/icon.svg")
extends Node

# Maximum number of members allowed in the party
@export var MAX_PARTY_MEMBERS := 4

# Array holding all characters currently in the party (followers)
var party_members: Array[CharacterBody2D] = []

# Array holding the currently playable character (only one expected)
var current_character: Array[CharacterBody2D] = []

# --- Adds a character to the party ---
func add_to_party(character: CharacterBody2D) -> void:
	# Ignore if already in the party
	if character in party_members:
		return

	# Do not allow adding more than max limit
	if party_members.size() >= MAX_PARTY_MEMBERS:
		print("Max party! It was not possible to add: ", character.name)
		return

	# Add character and set properties
	party_members.append(character)
	character.is_on_party = true
	character.party_position = party_members.size() - 1
	character.place_in_party_position()

	print("NPC added to the party: ", character.name, ", position: ", character.party_position)

# --- Removes a character from the party ---
func remove_from_party(character: CharacterBody2D) -> void:
	# Ignore if not in the party
	if character not in party_members:
		return

	# Remove character and reset state
	party_members.erase(character)
	character.is_on_party = false
	character.party_position = -1

	# Reassign positions for remaining party members
	reorganize_party()

	print("NPC removed from party: ", character.name)

# --- Switch control to another character ---
func play_as(character: CharacterBody2D) -> void:
	# Ignore if already playing as this character
	if current_character.has(character):
		print("Already playing as: ", character.name)
		return

	var old_char: CharacterBody2D = null
	var old_index := -1

	# If a character is currently being controlled
	if current_character.size() > 0:
		old_char = current_character[0]
		old_char.playable = false
		old_char.should_follow = true
		old_char.is_on_party = true

		# If the new character is already in the party
		if character in party_members:
			old_index = party_members.find(character)
			var temp = character
			var player_was_in_party := old_char in party_members

			# Swap positions in party
			if player_was_in_party:
				var player_index = party_members.find(old_char)
				party_members[old_index] = old_char
				party_members[player_index] = character
			else:
				# Insert new playable character at start
				party_members[old_index] = old_char
				party_members.insert(0, character)

			character.is_on_party = false
		else:
			# If new character isn't in party, insert it and push the old one in
			party_members.insert(0, character)
			party_members.append(old_char)
			character.is_on_party = false

		# Reassign positions to everyone
		reorganize_party()

		# Remove old character from player group
		if old_char.is_inside_tree():
			old_char.remove_from_group("player")
			old_char.add_to_group("npcs")

	else:
		# First time controlling a character
		if character in party_members:
			party_members.erase(character)
		character.is_on_party = false

	# Make new character playable
	character.playable = true
	character.should_follow = false
	add_to_party(character)

	# Update groups
	if character.is_inside_tree():
		character.remove_from_group("npcs")
		character.add_to_group("player")

	# Set current playable character
	current_character.clear()
	current_character.append(character)

	print("Now playing as: ", character.name)
	print("NPC groups: ", character.get_groups())

# --- Updates party positions based on list order ---
func reorganize_party() -> void:
	for i in range(party_members.size()):
		var member = party_members[i]
		member.party_position = i
		member.place_in_party_position()
