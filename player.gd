# player.gd - FIXED VERSION
extends CharacterBody2D

# Physics constants - tuned for good game feel
const GRAVITY = 1600.0          # How fast player falls
const MAX_FALL_SPEED = 800.0    # Terminal velocity to prevent infinite acceleration
const SPEED = 250.0             # Maximum horizontal movement speed
const ACCELERATION = 1200.0     # How quickly we reach max speed
const FRICTION = 1800.0         # Ground friction when stopping
const AIR_FRICTION = 200.0      # Air resistance when in air
const JUMP_FORCE = -600.0       # Jump strength (negative = upward)
const JUMP_CUT_MULTIPLIER = 0.5 # Reduces jump height when button released early
const COYOTE_TIME = 0.1         # Grace period to jump after leaving ground
const JUMP_BUFFER_TIME = 0.1    # Grace period for early jump input

# Input action names - configurable
const JUMP_ACTION = "ui_accept"
const LEFT_ACTION = "ui_left"
const RIGHT_ACTION = "ui_right"

# Node references
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Game state tracking
var coyote_timer = 0.0      # Tracks time since leaving ground
var jump_buffer_timer = 0.0 # Tracks time since jump was pressed
var was_on_floor = false    # Previous frame's ground state
var is_jumping = false      # Whether we're currently in a jump
var is_alive = true         # Player state

# Animation state
var current_animation = ""
var last_valid_animation = "stand"

func _ready() -> void:
	# Add player to group for easy identification by other objects
	add_to_group("player")
	
	# Validate that required nodes exist
	validate_setup()
	
	# Check input map
	validate_input_actions()
	
	print("Player initialized successfully!")

func validate_setup() -> void:
	if not sprite:
		print("ERROR: AnimatedSprite2D not found! Make sure it's a child of this player node.")
		return
	
	if not sprite.sprite_frames:
		print("WARNING: No SpriteFrames resource assigned to AnimatedSprite2D!")
		return
	
	# Check for required animations
	var required_animations = ["stand"]
	var optional_animations = ["move", "jump", "fall", "death"]
	
	for anim in required_animations:
		if not sprite.sprite_frames.has_animation(anim):
			print("ERROR: Missing required animation: ", anim)
	
	for anim in optional_animations:
		if not sprite.sprite_frames.has_animation(anim):
			print("INFO: Optional animation not found: ", anim)

func validate_input_actions() -> void:
	# Check if required input actions exist
	var required_actions = [JUMP_ACTION, LEFT_ACTION, RIGHT_ACTION]
	
	for action in required_actions:
		if not InputMap.has_action(action):
			print("ERROR: Input action '", action, "' not found in Input Map!")
			print("Please add it in Project Settings > Input Map")

func _physics_process(delta: float) -> void:
	# Only process movement if player is alive
	if not is_alive:
		return
	
	# Validate we're still in a valid state
	if not is_instance_valid(self):
		return
	
	# Handle all movement mechanics
	handle_coyote_time(delta)
	handle_jump_buffer(delta)
	apply_gravity(delta)
	handle_jump()
	handle_horizontal_movement(delta)
	
	# Apply calculated movement to the character
	move_and_slide()
	
	# pencegah karakter keluar layar
	var screen_rect = get_viewport_rect()
	global_position.x = clamp(global_position.x, 0, screen_rect.size.x)
	
	# Update visual representation
	update_sprite_direction()
	update_animations()
	
	# Update state for next frame
	was_on_floor = is_on_floor()

func handle_coyote_time(delta: float) -> void:
	# Coyote time allows jumping briefly after leaving a platform
	if is_on_floor():
		coyote_timer = COYOTE_TIME  # Reset timer when on ground
	else:
		coyote_timer = max(0.0, coyote_timer - delta)  # Count down when in air

func handle_jump_buffer(delta: float) -> void:
	# Jump buffering remembers jump input for a short time
	if InputMap.has_action(JUMP_ACTION) and Input.is_action_just_pressed(JUMP_ACTION):
		jump_buffer_timer = JUMP_BUFFER_TIME  # Player wants to jump
	else:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)  # Count down the buffer

func apply_gravity(delta: float) -> void:
	# Only apply gravity when not on ground
	if not is_on_floor():
		# Add gravity to vertical velocity
		velocity.y += GRAVITY * delta
		# Cap falling speed to prevent infinite acceleration
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
		
		# Variable jump height: if player releases jump button early,
		# reduce upward velocity for shorter jumps
		var jump_held = InputMap.has_action(JUMP_ACTION) and Input.is_action_pressed(JUMP_ACTION)
		if is_jumping and not jump_held and velocity.y < 0:
			velocity.y *= JUMP_CUT_MULTIPLIER
			is_jumping = false

func handle_jump() -> void:
	# Determine if player can and wants to jump
	var can_jump = (is_on_floor() or coyote_timer > 0)  # On ground or within coyote time
	var wants_to_jump = jump_buffer_timer > 0           # Recently pressed jump
	
	# Execute jump if conditions are met
	if can_jump and wants_to_jump:
		velocity.y = JUMP_FORCE     # Apply upward force
		is_jumping = true           # Track that we're jumping
		jump_buffer_timer = 0.0     # Consume the jump input
		coyote_timer = 0.0          # Consume coyote time
		print("Jump executed!")
	
	# Reset jumping state when landing
	if is_on_floor() and was_on_floor == false:
		is_jumping = false
		print("Player landed")

func handle_horizontal_movement(delta: float) -> void:
	var input_dir = 0.0
	
	# Get input direction safely
	if InputMap.has_action(RIGHT_ACTION) and InputMap.has_action(LEFT_ACTION):
		input_dir = Input.get_action_strength(RIGHT_ACTION) - Input.get_action_strength(LEFT_ACTION)
	
	if input_dir != 0:
		# Player is trying to move - accelerate towards target speed
		var target_speed = input_dir * SPEED
		velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
	else:
		# No input - apply friction to slow down
		var friction_force = FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0, friction_force * delta)

func update_sprite_direction() -> void:
	# Flip sprite based on movement direction
	if sprite and is_instance_valid(sprite) and abs(velocity.x) > 10:
		sprite.flip_h = velocity.x < 0   # Flip when moving left

func update_animations() -> void:
	# Safety checks - make sure sprite and animations exist
	if not sprite or not is_instance_valid(sprite) or not sprite.sprite_frames:
		return
	
	var new_animation = determine_animation()
	
	# Only change animation if it's different, exists, and is valid
	if new_animation != current_animation and sprite.sprite_frames.has_animation(new_animation):
		current_animation = new_animation
		last_valid_animation = new_animation
		sprite.play(new_animation)
	elif new_animation != current_animation and sprite.sprite_frames.has_animation(last_valid_animation):
		# Fallback to last valid animation
		current_animation = last_valid_animation
		sprite.play(last_valid_animation)

func determine_animation() -> String:
	# Choose animation based on player state (priority order matters!)
	if not is_on_floor():
		# In air - check if jumping up or falling down
		if velocity.y < -50:
			return "jump"  # Moving upward fast enough
		else:
			# Falling or at peak of jump
			return "fall" if sprite.sprite_frames.has_animation("fall") else "jump"
	elif abs(velocity.x) > 20:
		# On ground and moving horizontally
		return "move"
	else:
		# On ground and stationary
		return "stand"

func die() -> void:
	# Handle player death
	if not is_alive:
		return  # Already dead
		
	is_alive = false
	velocity = Vector2.ZERO  # Stop all movement
	print("Player died!")
	
	# Play death animation if available
	if sprite and is_instance_valid(sprite) and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		current_animation = "death"

func revive() -> void:
	# Method to revive player (useful for respawn systems)
	is_alive = true
	print("Player revived!")

func _exit_tree() -> void:
	# Clean up when player is destroyed
	print("Player destroyed")
