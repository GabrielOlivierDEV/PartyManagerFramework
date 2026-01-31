# Party Manager Framework
A modular Godot 4.4.x plugin that offers a **party and character control system** with **built-in character–NPC scripting**.

Designed for **RPG-style games** where you control one playable character and up to **4 dynamic NPC followers** (configurable via `MAX_PARTY_MEMBERS`), with smooth follower logic, party switching, and positional syncing. Perfect for games where party coordination, character switching, and AI follower behavior are key.

## How it works
The Party Manager Framework uses a combination of Godot's node system, groups, and custom scripts to manage party members and their behavior. Each character in the game is expected to have a script (like `character.gd`) that defines its movement, animation, and party-related properties.

When a character is added to the party, it is assigned a `party_position` which determines its order in the formation. The `place_in_party_position()` method calculates the correct position behind the leader or the previous member based on this order.

## API reference — functions, variables and behavior

### `PartyManager.play_as(character: CharacterBody2D)`

Switches player control to the selected character.

- If another character is already playable, they switch places.
- Updates `party_members` order.
- Changes character's group from `npcs` to `player`.
- Repositions all members with `place_in_party_position()`.
- Alternatively you can set your player node (with the `character.gd` script) as "playable" on the inspector!
![Alt text](read_me_assets/playable.png)

### `PartyManager.add_to_party(npc: CharacterBody2D)`

Adds an NPC to the party if there is room.

- Sets `is_on_party = true` and defines `party_position`.
- Calls `place_in_party_position()` to auto-position the NPC.
- Will not add the NPC if it’s already in the party.
- Limit: 4 members besides the player. (Customizable)

### `PartyManager.remove_from_party(npc: CharacterBody2D)`

Removes an NPC from the party.

- Sets `is_on_party = false` and `party_position = -1`.
- Reorganizes remaining members using `reorganize_party()`.

### `PartyManager.reorganize_party()`

Reassigns `party_position` to all party members and teleports them into correct formation using `place_in_party_position()`.

### `PartyManager.close_party()`

Removes all NPCs from the party.

### `PartyManager.change_scene()`

Clears party data (the default implementation clears both `party_members` and `current_character`).

Note: The code intentionally clears the party on scene change. If you want to preserve the party across scenes, you can change the plugin's behavior (for example, by modifying `change_scene()` to keep data in the autoload singleton) — but the default plugin clears the lists.

### `PartyManager.is_in_party(character_id: String)`

Returns `true` if a character with the given `character_id` is in the party.

### `PartyManager.get_current_player() -> String`

Returns the currently playable character in the party.

### `PartyManager.get_party_members() -> Array[String]`

Returns an array of character IDs for all current party members.

### `PartyManager.get_party_size() -> int`

Returns the current number of party members.

## Example Code

```gdscript
# -----------------------
# This is a demo scene to showcase the PartyManager functionality.
# It allows adding characters to the party and switching between them.
# ------------------------
@onready var blue = $Blue
@onready var purple = $Purple

# Flags to determine if the player wants to switch to a character after adding them to the party
var play_as_purple = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    PartyManager.play_as(blue)

# Functions to handle adding characters to the party and switching control
func _on_add_purple_to_party_body_entered(body: Node2D) -> void:
    if not body.is_in_group("player"):
        return
    PartyManager.add_to_party(purple) # Add purple to the party
    
    if not play_as_purple:
        return
        
    if purple.is_on_party:
        PartyManager.play_as(purple) # Switch control to purple if the player chose to
```

## Movement Logic

- NPCs follow the character ahead of them using dynamic positioning.
- Follow distance is calculated based on `party_position`.
- If too far, they teleport to the correct position.
- The member in position `1` always follows the currently playable character (`current_character[0]`).

## Requirements

- [Godot Engine 4.4.x](https://godotengine.org/)
 - Set up the keys "move_up", "move_down", "move_right", "move_left", and "run". (The plugin does this automatically for you if you don't have them configured.)
- Characters must:
  - Use `$AnimatedSprite2D` for animations
  - Animation must have "idle", "up", "down", "left" and "right"
  - Move using `velocity`
  - Inherit from `CharacterBody2D`

## Setup

1. **Plugin Installation**
   - Copy the `PartyManagerFramework` folder into your project under:  
	 `res://addons/PartyManagerFramework/`
   - In the Godot Editor, go to **Project > Project Settings > Plugins**.  
   - Find `PartyManagerFramework` in the list and set it to **Active**.
   - Reload current project.

2. **Character Setup**
   - Attach the `character.gd` script to any character nodes that should be managed by the party system.  
   - Alternatively, you can use your own custom script, as long as it follows the same structure of variables and functions.
   - If you have the animations (idle, up, down, left, right) done, you can enable "update animation" on the character node's inspector.

3. **Gameplay Usage**
   - Use the following main methods inside your gameplay logic or UI:
	 - `PartyManager.add_to_party(character)` → adds a character to the party. (Alternatively you can set your player node (with the `character.gd` script) as "is_on_party" on the inspector!)
	 - `PartyManager.play_as(character)` → sets the active playable character. (Alternatively you can set your player node (with the `character.gd` script) as "playable" on the inspector!)

4. **Advanced Configuration**
   - To change the maximum number of party members, edit the `MAX_PARTY_MEMBERS` exported variable in `res://addons/PartyManagerFramework/partymanager.gd` or add the `PartyManager` helper node (`partymanager_helper.gd`) to a scene and set the value in the inspector. The helper syncs the inspector value to the autoload at runtime.
   - The plugin also exposes runtime public arrays you can use from code:
     - `PartyManager.party_members` — Array[CharacterBody2D] for follower members.
     - `PartyManager.current_character` — Array[CharacterBody2D] holding the current playable character (index 0 if set).

   Example — read the currently playable character and the followers:
   ```gdscript
   var current_player = PartyManager.current_character.size() > 0 ? PartyManager.current_character[0] : null
   var members = PartyManager.party_members
   ```

5. **Done!**
   - The Party Manager Framework is now ready to use in your project!

## Video Demo
https://github.com/user-attachments/assets/041dbe64-e91f-4da0-ab55-8620c10ae647

You can find the demo scene inside the [demo folder](https://github.com/GabrielOlivierDEV/PartyManagerFramework/tree/main/demo) of this project.

---

## Character script (documented)

The `character.gd` script attached to each character node exposes several _exported_ and state variables you can tweak in the inspector and control at runtime.

- Exported/inspector-adjustable variables:
   - `_move_speed` — base movement speed.
   - `_speed_cap` — maximum speed while running.
   - `_acceleration` — acceleration factor used when interpolating velocity.
   - `_friction` — friction used when stopping.
   - `animated_sprite` — reference to an `AnimatedSprite2D` node if you want automatic animation switching.
   - `update_animation` — toggle automatic animation updates.

- Runtime / state variables (accessible from script):
   - `playable` — set to `true` for the currently player-controlled character.
   - `is_on_party` — set to `true` when the character is part of the party.
   - `party_position` — integer position in the party queue (0 = leader).

- Useful method:
   - `place_in_party_position()` — instantly teleports a character to its formation position behind the previous party member / leader.

These fields allow you to tweak follower speed, teleport distances and formation behavior without editing the follower logic.

## Plugin / Editor integration

- The plugin registers an autoload singleton named `PartyManager` at `res://addons/PartyManagerFramework/partymanager.gd` when enabled in the editor.
- It also registers a custom node type `PartyManager` (backed by `partymanager_helper.gd`) that allows editing `MAX_PARTY_MEMBERS` per-scene via the inspector.
- When active, the plugin will add default input actions if missing:
   - `move_up` (W, Arrow Up)
   - `move_down` (S, Arrow Down)
   - `move_left` (A, Arrow Left)
   - `move_right` (D, Arrow Right)
   - `run` (Shift)

These are added only if they aren't already present in your project settings.

## Groups and side-effects you should know

- The plugin uses Godot groups to manage playable and NPC characters.
   - When a character becomes playable, the system removes it from the `npcs` group and adds it to the `player` group.
   - When a character becomes a follower (is_on_party = true), it will typically be in the `npcs` group.

## Planned quality-of-life improvements (future)

The framework works as-is, but here are a few API improvements I'm planning to add in the future for better usability:

- Add accessor helpers to PartyManager API (example names):
   - `get_current_player() -> CharacterBody2D` — returns the current playable character or `null`.
   - `get_party_members() -> Array[CharacterBody2D]` — returns a copy or reference to party members.
   - `is_in_party(character: CharacterBody2D) -> bool` — quick membership check.

- Add signals for easy reaction to changes:
   - `signal party_changed()`
   - `signal current_player_changed(new_player, old_player)`

These can make integrations (UI, AI triggers, quests) much simpler.

## Note from the Author

This plugin was initially developed for a JRPG project that never fully came to life. While the code may be a bit amateur, I hope it can still be useful in your game development journey. If you find ways to improve it or want to add new features, feel free to submit your contributions here!

## License

**PartyManagerFramework** is an open-source project. You are free to use, modify, and distribute the code under the terms of the [MIT License](https://github.com/GabrielOlivierDEV/PartyManagerFramework/blob/main/LICENSE).

