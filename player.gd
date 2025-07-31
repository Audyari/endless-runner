extends CharacterBody2D

# Physics constants - more realistic values
const GRAVITY = 1600.0  # Increased for more natural fall
const MAX_FALL_SPEED = 800.0  # Terminal velocity
const SPEED = 250.0
const ACCELERATION = 1200.0  # How fast we reach max speed
const FRICTION = 1800.0  # Ground friction when stopping
const AIR_FRICTION = 200.0  # Air resistance
const JUMP_FORCE = -600.0 # -600 kalo lebih tinggi
const JUMP_CUT_MULTIPLIER = 0.5  # For variable jump height
const COYOTE_TIME = 0.1  # Grace period after leaving platform
const JUMP_BUFFER_TIME = 0.1  # Grace period for early jump input

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# State tracking variables
var coyote_timer = 0.0
var jump_buffer_timer = 0.0
var was_on_floor = false
var is_jumping = false

func _physics_process(delta: float) -> void:
	handle_coyote_time(delta)
	handle_jump_buffer(delta)
	apply_gravity(delta)
	handle_jump()
	handle_horizontal_movement(delta)
	
	# Apply movement
	move_and_slide()
	
	# Update animations and sprite direction
	update_sprite_direction()
	update_animations()
	
	# Update state tracking
	was_on_floor = is_on_floor()

func handle_coyote_time(delta: float) -> void:
	# Coyote time - allows jumping shortly after leaving ground
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

func handle_jump_buffer(delta: float) -> void:
	# Jump buffering - remembers jump input for a short time
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		# Apply gravity with terminal velocity
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
		
		# Variable jump height - cut jump short if button released
		if is_jumping and not Input.is_action_pressed("ui_accept") and velocity.y < 0:
			velocity.y *= JUMP_CUT_MULTIPLIER
			is_jumping = false

func handle_jump() -> void:
	# Check if we can jump (on ground or within coyote time) and want to jump
	var can_jump = (is_on_floor() or coyote_timer > 0)
	var wants_to_jump = jump_buffer_timer > 0
	
	if can_jump and wants_to_jump:
		velocity.y = JUMP_FORCE
		is_jumping = true
		jump_buffer_timer = 0.0  # Consume the jump buffer
		coyote_timer = 0.0  # Consume coyote time
	
	# Reset jumping state when landing
	if is_on_floor() and was_on_floor == false:
		is_jumping = false

func handle_horizontal_movement(delta: float) -> void:
	var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	
	if input_dir != 0:
		# Accelerate towards target speed
		var target_speed = input_dir * SPEED
		velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
	else:
		# Apply friction
		var friction_force = FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0, friction_force * delta)

func update_sprite_direction() -> void:
	# Only flip sprite when actually moving horizontally
	if abs(velocity.x) > 10:  # Small threshold to avoid jittering
		sprite.flip_h = velocity.x < 0

func update_animations() -> void:
	var new_animation = ""
	
	# Prioritize animations: falling > jumping > moving > idle
	if not is_on_floor():
		if velocity.y < -50:  # Going up fast enough to be considered jumping
			new_animation = "jump"
		else:  # Falling or at peak of jump
			new_animation = "fall" if sprite.sprite_frames.has_animation("fall") else "jump"
	elif abs(velocity.x) > 20:  # Moving threshold to avoid animation flickering
		new_animation = "move"
	else:
		new_animation = "stand"
	
	# Only change animation if it's different to avoid restart flicker
	if sprite.animation != new_animation:
		sprite.play(new_animation)
