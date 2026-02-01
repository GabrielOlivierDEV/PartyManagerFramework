extends CharacterBody2D
class_name Character

# --- Config Constants ---
const BASE_FOLLOW_STOP_DISTANCE := 80.0       # Base distance to stop following the target
const FOLLOW_SPACING_PER_MEMBER := 5.0        # Extra distance added per party member
const BASE_TELEPORT_DISTANCE := 300.0         # Distance at which the follower will teleport
const TELEPORT_SPACING_PER_MEMBER := 50.0     # Extra teleport distance per party member
const VELOCITY_TOLERANCE := 10.0              # Margin to avoid small velocity changes
const ANIMATION_IDLE_THRESHOLD := 5.0         # Speed below which idle animation is triggered
const LEADER_POSITION := 0                    # Party index for the leader
const FIRST_FOLLOWER_POSITION := 1            # Party index for the first follower
const NO_PARTY_POSITION := -1                 # Marks that this character is not in the party

const MIN_SPEED_RATIO := 0.8                  # Minimum fraction of _move_speed
const MAX_SPEED_MULTIPLIER := 2.0             # Maximum multiplier of _speed_cap
const INTERPOLATION_DISTANCE := 200.0         # Range used for speed interpolation

@export var character_id : String

# --- Movement Variables ---
@export_category("Movement Variables")
@export var _move_speed: float = 300.0        # Default walking speed
@export var _speed_cap: float = 600.0         # Max speed when holding shift
@export var _acceleration: float = 10.0       # Rate of speed increase
@export var _friction: float = 100.0          # Rate of speed decrease when no input

# --- Node References ---
@export_category("Node References")
@export var animated_sprite: AnimatedSprite2D # Reference to character's sprite
@export var camera_2d: Camera2D               # Reference to character's Camera 2D node 

# --- State Variables ---
@export_category("State Variables")
@export var update_animation := false         # Whether to update the sprite animation based on movement
@export var use_camera_2d := false            # Toggle to enable the use of the Camera 2D node
@export var playable := false                 # Position in the party queue (0 = leader)
@export var is_on_party := false              # Whether the character is currently in the party

var party_position: int = LEADER_POSITION     # Position in the party queue (0 = leader)
var should_follow := false                    # Whether the character should move towards the leader
var target_velocity: Vector2 = Vector2.ZERO   # Velocity target used for interpolation

# ====================================================================
#   READY
# ====================================================================
func _ready() -> void:
	# Register this character with PartyManager if needed
	if playable:
		PartyManager.play_as(self)

	# Add to party if marked as such
	if is_on_party:
		PartyManager.add_to_party(self)
		place_in_party_position()

# =======================================================
# PHYSICS PROCESS
# =======================================================
func _physics_process(delta: float) -> void:
	if playable:
		# Process player-controlled movement
		_process_player_input(delta)

	elif is_on_party:
		# Process follower movement
		_process_follower_logic(delta)

	# Apply physics and animation regardless of control type
	move_and_slide()
	_update_animation()

# =======================================================
# PLAYER MOVEMENT
# =======================================================
func _process_player_input(delta: float) -> void:
	# Get input direction
	var input_dir: Vector2 = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	# Camera toggle
	if camera_2d:
		camera_2d.enabled = use_camera_2d

	# Determine target velocity based on input
	var max_speed: float = _speed_cap if Input.is_action_pressed("run") else _move_speed
	target_velocity = input_dir * max_speed if input_dir != Vector2.ZERO else Vector2.ZERO

	# Smoothly interpolate current velocity towards target velocity
	var factor: float = _acceleration if input_dir != Vector2.ZERO else _friction
	var lerp_factor: float = clamp(factor * delta, 0.0, 1.0)

	velocity = velocity.lerp(target_velocity, lerp_factor)

# =======================================================
# FOLLOWER LOGIC
# =======================================================
func _process_follower_logic(delta: float) -> void:
	# Disable camera for followers
	if camera_2d:
		camera_2d.enabled = false

	# If no party position assigned, do nothing
	if party_position == NO_PARTY_POSITION:
		return

	# Get the node to follow (leader or previous party member)
	var target_node: Character = _get_target_node()
	if not target_node:
		return

	# Calculate distance to target
	var offset: Vector2 = target_node.global_position - global_position
	var dist: float = offset.length()

	# Teleport check
	var teleport_distance: float = BASE_TELEPORT_DISTANCE + party_position * TELEPORT_SPACING_PER_MEMBER
	if dist > teleport_distance:
		place_in_party_position()
		return

	# Stop-distance
	var stop_distance: float = BASE_FOLLOW_STOP_DISTANCE + party_position * FOLLOW_SPACING_PER_MEMBER
	if dist <= stop_distance:
		velocity = Vector2.ZERO
		target_velocity = Vector2.ZERO
		return

	
	# Adpt speed based on distance
	# Closer = slower, Farther = faster (within limits)
	# This creates a natural acceleration/deceleration effect
	var direction: Vector2 = offset.normalized()
	var min_speed: float = _move_speed * MIN_SPEED_RATIO
	var max_speed: float = _speed_cap * MAX_SPEED_MULTIPLIER

	var t: float = clamp(
		(dist - stop_distance) / INTERPOLATION_DISTANCE,
		0.0,
		1.0
	)

	var follow_speed: float = lerp(min_speed, max_speed, t)
	var desired_velocity: Vector2 = direction * follow_speed
	var lerp_factor: float = clamp(_acceleration * delta, 0.0, 1.0)

	# Apply velocity with tolerance to avoid jitter
	target_velocity = target_velocity.lerp(desired_velocity, lerp_factor)
	velocity = target_velocity

# =======================================================
# TARGET NODE
# =======================================================
func _get_target_node() -> Character:
	# Leader follows no one
	if party_position == FIRST_FOLLOWER_POSITION and PartyManager.current_character.size() > 0:
		return PartyManager.current_character[0]

	# Other members follow the one before them
	var index := party_position - 1
	if index >= 0 and index < PartyManager.party_members.size():
		return PartyManager.party_members[index]

	return null

# =======================================================
# ANIMATION UPDATE
# =======================================================
func _update_animation() -> void:
	# Skip if not updating animation
	if not update_animation or not animated_sprite:
		return

	# Idle state
	if velocity.length() < ANIMATION_IDLE_THRESHOLD:
		animated_sprite.pause()
		return

	# Directional animation
	if abs(velocity.x) > abs(velocity.y):
		animated_sprite.play("right" if velocity.x > 0 else "left")
	else:
		animated_sprite.play("down" if velocity.y > 0 else "up")

# =======================================================
# PARTY POSITIONING
# =======================================================
func place_in_party_position() -> void:
	# Get the target node to follow
	var target_node: Character = null

	# Leader follows no one
	if party_position != LEADER_POSITION and party_position - 1 < PartyManager.party_members.size():
		target_node = PartyManager.party_members[party_position - 1]

	if not target_node:
		return

	# Calculate stop distance based on party position
	var stop_distance := BASE_FOLLOW_STOP_DISTANCE + party_position * FOLLOW_SPACING_PER_MEMBER
	var dir := target_node.velocity.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN

	global_position = target_node.global_position - dir * stop_distance
