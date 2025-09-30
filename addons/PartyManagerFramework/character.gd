extends CharacterBody2D

# --- Config Constants ---
const BASE_FOLLOW_STOP_DISTANCE := 80.0 # Base distance to stop following the target
const FOLLOW_SPACING_PER_MEMBER := 5.0 # Extra distance added per party member
const BASE_TELEPORT_DISTANCE := 300.0 # Distance at which the follower will teleport to its position
const TELEPORT_SPACING_PER_MEMBER := 50.0 # Extra teleport distance per party member
const VELOCITY_TOLERANCE := 10.0 # Margin to avoid small velocity changes
const ANIMATION_IDLE_THRESHOLD := 5.0 # Speed below which the idle animation is triggered

# --- Movement Variables ---
@export_category("Variables")
@export var _move_speed: float = 300.0 # Default walking speed
@export var _speed_cap: float = 600.0 # Max speed when holding shift
@export var _acceleration: float = 10.0 # Rate of speed increase
@export var _friction: float = 100.0 # Rate of speed decrease when no input

# --- Node References ---
@export var animated_sprite: AnimatedSprite2D # Reference to character's sprite

# --- State Variables ---
@export var update_animation := false # Whether to update the sprite animation based on movement
@export var playable := false # If true, this character is controlled by the player
@export var is_on_party := false # Whether the character is currently in the party
var party_position: int = 0 # Position in the party queue (0 = leader)
var should_follow := false # Whether the character should move towards the leader
var target_velocity: Vector2 = Vector2.ZERO # Velocity target used for interpolation

# --- Called when the node is ready ---
func _ready() -> void:
	# Register this character with PartyManager if needed
	if playable:
		PartyManager.play_as(self)
	if is_on_party:
		PartyManager.add_to_party(self)
		place_in_party_position()

# --- Called every physics frame ---
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

# --- Player movement handling ---
func _process_player_input(delta: float) -> void:
	# Get normalized input direction
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	
	# Determine speed based on run key
	var max_speed = _speed_cap if Input.is_action_pressed("run") else _move_speed
	
	# Calculate target velocity
	target_velocity = input_dir * max_speed if input_dir != Vector2.ZERO else Vector2.ZERO
	
	# Smoothly interpolate velocity with acceleration or friction
	var lerp_factor = clamp(_acceleration * delta, 0.0, 1.0) if input_dir != Vector2.ZERO else clamp(_friction * delta, 0.0, 1.0)
	velocity = velocity.lerp(target_velocity, lerp_factor)

# --- Follower behavior handling (smoothed follow with quicker stop) ---
func _process_follower_logic(delta: float) -> void:
	if party_position < 0:
		return
	
	# Get the node to follow (leader or previous party member)
	var target_node = _get_target_node()
	if not target_node:
		return
	
	# Determine movement direction
	var offset = target_node.global_position - global_position
	var dist = offset.length()
	var direction = offset.normalized() if dist > 0.0 else Vector2.DOWN
	
	# Calculate distances for stopping and teleport
	var stop_distance = BASE_FOLLOW_STOP_DISTANCE + (party_position * FOLLOW_SPACING_PER_MEMBER)
	var teleport_distance = BASE_TELEPORT_DISTANCE + (party_position * TELEPORT_SPACING_PER_MEMBER)
	
	# Stop following if close enough
	if dist <= stop_distance:
		velocity = Vector2.ZERO
		target_velocity = Vector2.ZERO  # Ensure immediate stop
		return
	# Instantly teleport if too far
	if dist > teleport_distance:
		place_in_party_position()
		return

	# Adpt speed based on distance
	# Closer = slower, Farther = faster (within limits)
	# This creates a natural acceleration/deceleration effect
	var min_speed = _move_speed * 0.8   # Min speed when close
	var max_speed = _speed_cap * 2.0    # Max speed when far
	var t = clamp((dist - stop_distance) / 200.0, 0.0, 1.0) # Normalize distance for interpolation
	var follow_speed = lerp(min_speed, max_speed, t)

	var desired_velocity = Vector2.ZERO
	if dist > stop_distance:
		desired_velocity = direction * follow_speed

	# Smoothly interpolate velocity with acceleration
	var lerp_factor = clamp(_acceleration * delta, 0.0, 1.0)
	target_velocity = target_velocity.lerp(desired_velocity, lerp_factor)
	velocity = target_velocity

# --- Get the node this follower should follow ---
func _get_target_node() -> CharacterBody2D:
	if party_position == 1 and PartyManager.current_character.size() > 0:
		return PartyManager.current_character[0]
	elif party_position - 1 < PartyManager.party_members.size():
		return PartyManager.party_members[party_position - 1]
	return null

# --- Update sprite animation based on movement ---
func _update_animation() -> void:
	if not update_animation or not animated_sprite:
		return
	
	# Idle state
	if velocity.length() < ANIMATION_IDLE_THRESHOLD:
		animated_sprite.pause()
		return
	
	# Choose animation direction based on velocity
	if abs(velocity.x) > abs(velocity.y):
		animated_sprite.play("right" if velocity.x > 0 else "left")
	else:
		animated_sprite.play("down" if velocity.y > 0 else "up")

# --- Instantly move character to correct party position ---
func place_in_party_position() -> void:
	var target_node: CharacterBody2D = null

	if not target_node:
		return

	if party_position == 0:
		if PartyManager.current_character.size() > 0:
			return
	else:
		if party_position - 1 < PartyManager.party_members.size():
			target_node = PartyManager.party_members[party_position - 1]

	var stop_distance := BASE_FOLLOW_STOP_DISTANCE + (party_position * FOLLOW_SPACING_PER_MEMBER)
	var target_direction = target_node.velocity.normalized()
	if target_direction == Vector2.ZERO:
		target_direction = Vector2.DOWN

	# Position directly behind the target at the appropriate distance
	var offset_position = target_node.global_position - (target_direction * stop_distance)
	global_position = offset_position
