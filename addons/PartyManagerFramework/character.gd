extends CharacterBody2D

# --- Config Constants ---
const BASE_FOLLOW_STOP_DISTANCE := 40.0 # Base distance to stop following the target
const FOLLOW_SPACING_PER_MEMBER := 10.0 # Extra distance added per party member
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
@export var animated_sprite: AnimatedSprite2D

# --- State Variables ---
@export var update_animation := false # Whether to update the sprite animation based on movement
@export var playable := false # If true, this character is controlled by the player
var is_on_party := false # Whether the character is currently in the party
var party_position: int = 0 # Position in the party queue (0 = leader)
var should_follow := false # Whether the character should move towards the leader
var target_velocity: Vector2 = Vector2.ZERO # Velocity target used for interpolation

# --- Called when the node is ready ---
func _ready() -> void:
	if playable:
		PartyManager.play_as(self)
	
	if is_on_party:
		place_in_party_position()

# --- Called every physics frame ---
func _physics_process(_delta: float) -> void:
	# If this character is playable
	if playable:
		# Process player-controlled movement
		_move(_delta)

	# If not playable, process follower logic (only if in party)
	elif is_on_party:
		_process_follower_logic(_delta)

	# Apply physics and animation regardless of control type
	move_and_slide()
	_update_animation()

# --- Handles follower behavior ---
func _process_follower_logic(_delta: float) -> void:
	if not is_on_party or party_position < 0:
		return

	var target_node: CharacterBody2D = null

	# Get the character to follow: either the leader or the one ahead in the party
	if party_position == 1:
		if PartyManager.current_character.size() > 0:
			target_node = PartyManager.current_character[0]
	else:
		if party_position - 1 < PartyManager.party_members.size():
			target_node = PartyManager.party_members[party_position - 1]

	if not target_node:
		return

	var target_direction = target_node.velocity.normalized()
	if target_direction == Vector2.ZERO:
		target_direction = Vector2.DOWN

	var stop_distance := BASE_FOLLOW_STOP_DISTANCE + (party_position * FOLLOW_SPACING_PER_MEMBER)
	var follow_distance := stop_distance * 0.5
	var teleport_distance := BASE_TELEPORT_DISTANCE + (party_position * TELEPORT_SPACING_PER_MEMBER)

	var target_position = target_node.global_position - (target_direction * stop_distance)
	var distance = global_position.distance_to(target_position)

	# Check if the follower should move
	should_follow = distance > follow_distance

	# Stop movement if close enough
	if distance <= stop_distance:
		_reset_following()

	# Instantly teleport if too far
	if distance > teleport_distance:
		place_in_party_position()
		return

	# Calculate movement direction and speed
	if should_follow:
		var direction = (target_position - global_position).normalized()
		var target_speed = target_node.velocity.length()
		target_velocity = direction * target_speed
	else:
		target_velocity = Vector2.ZERO

	# Smooth velocity transition (acceleration or friction)
	if velocity.distance_to(target_velocity) < VELOCITY_TOLERANCE:
		velocity = target_velocity
	elif velocity.length() < target_velocity.length():
		velocity = velocity.lerp(target_velocity, clamp(_acceleration * _delta, 0, 1))
	else:
		velocity = velocity.lerp(target_velocity, clamp(_friction * _delta, 0, 1))

# --- Handles player input and movement ---
func _move(delta: float) -> void:
	var input_direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()

	# Use speed cap when shift is held
	var max_speed = _speed_cap if Input.is_action_pressed("run") else _move_speed

	if input_direction != Vector2.ZERO:
		target_velocity = input_direction * max_speed
		velocity = velocity.lerp(target_velocity, clamp(_acceleration * delta, 0.0, 1.0))
	else:
		# Apply friction when no input
		velocity = velocity.lerp(Vector2.ZERO, clamp(_friction * delta, 0.0, 1.0))

# --- Updates sprite animation based on movement ---
func _update_animation() -> void:
	if not update_animation:
		return
		
	if not animated_sprite:
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

	if party_position == 0:
		if PartyManager.current_character.size() > 0:
			target_node = PartyManager.current_character[0]
	else:
		if party_position - 1 < PartyManager.party_members.size():
			target_node = PartyManager.party_members[party_position - 1]

	if not target_node:
		return

	var stop_distance := BASE_FOLLOW_STOP_DISTANCE + (party_position * FOLLOW_SPACING_PER_MEMBER)
	var target_direction = target_node.velocity.normalized()
	if target_direction == Vector2.ZERO:
		target_direction = Vector2.DOWN

	var offset_position = target_node.global_position - (target_direction * stop_distance)
	global_position = offset_position

# --- Stop following logic ---
func _reset_following() -> void:
	should_follow = false
