# rock.gd - FIXED VERSION
extends Area2D

# Export variables (can be changed in the editor)
@export var move_speed := 150.0      # How fast the rock moves left
@export var reset_position_x := 800.0 # Where rock respawns on the right
@export var min_position_x := -50.0   # Where rock disappears on the left

# Signal emitted when player successfully avoids this rock
signal change_point

# Internal state
var has_been_avoided := false  # Prevents multiple point awards
var original_speed := 0.0      # Store original speed for resets
var is_active := true         # Whether rock is currently active

func _ready() -> void:
	# Store original speed
	original_speed = move_speed
	
	# Add this rock to the rocks group for easy identification
	add_to_group("rocks")
	
	# Connect the collision signal properly
	setup_collision_detection()
	
	# Initialize state
	reset_state()
	
	print("Rock initialized at position X: ", position.x, " with speed: ", move_speed)

func setup_collision_detection() -> void:
	# Modern Godot 4 way to connect signals
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		print("Rock collision signal connected")
	
	# Also connect body_exited for more precise collision detection
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func reset_state() -> void:
	# Reset all state variables
	has_been_avoided = false
	is_active = true
	set_process(true)  # Make sure rock can move

func _process(delta: float) -> void:
	# Only move if active
	if not is_active:
		return
	
	# Move rock continuously to the left
	position.x -= move_speed * delta
	
	# Check if rock has moved completely off-screen
	if position.x < min_position_x:
		handle_rock_avoided()

func handle_rock_avoided() -> void:
	# Award point only if it hasn't been awarded yet
	if not has_been_avoided:
		has_been_avoided = true
		
		# Emit signal safely - use call_deferred to avoid timing issues
		call_deferred("emit_point_signal")
		
		print("Rock avoided! Point will be awarded.")
	
	# Reset rock position and state
	reset_rock()

func emit_point_signal() -> void:
	# Safely emit the point signal
	if is_instance_valid(self):
		change_point.emit()

func reset_rock() -> void:
	# Move rock back to starting position
	position.x = reset_position_x
	
	# Reset state
	reset_state()
	
	print("Rock reset to position: ", position.x)
	
	# Optional: Randomize Y position for variety (uncomment if you want this)
	# position.y = randf_range(200, 400)

func _on_body_entered(body: Node2D) -> void:
	# Debug info
	print("Something entered rock area: ", body.name, " (Type: ", body.get_class(), ")")
	
	# Validate the body
	if not body or not is_instance_valid(body):
		print("Invalid body detected, ignoring")
		return
	
	# Check if it's the player
	if body.is_in_group("player"):
		handle_player_collision(body)

func _on_body_exited(body: Node2D) -> void:
	# Optional: Handle when something leaves the rock area
	if body and is_instance_valid(body) and body.is_in_group("player"):
		print("Player exited rock area safely")

func handle_player_collision(player: Node2D) -> void:
	# Prevent multiple collision calls
	if not is_active:
		return
		
	print("=== COLLISION DETECTED ===")
	print("Player hit rock at position: ", position)
	
	# Deactivate this rock
	is_active = false
	set_process(false)
	
	# Kill the player if they have a die method
	if player.has_method("die"):
		player.die()
	
	# Find and notify the level about game over
	call_deferred("trigger_game_over")

func trigger_game_over() -> void:
	# Use call_deferred to avoid issues during physics processing
	if not is_instance_valid(self):
		return
		
	# Try multiple methods to find the level node
	var level = find_level_node()
	
	if level and is_instance_valid(level) and level.has_method("game_over"):
		print("Calling game_over on level node: ", level.name)
		level.game_over()
	else:
		print("Level node not found or invalid")
		print("Falling back to direct scene reload")
		# Fallback: restart scene directly after a short delay
		var timer = get_tree().create_timer(1.0)
		if timer:
			await timer.timeout
			if is_instance_valid(self):
				get_tree().reload_current_scene()

func find_level_node() -> Node:
	# Method 1: Try to find level by group (most reliable)
	var level_nodes = get_tree().get_nodes_in_group("level")
	if level_nodes.size() > 0 and is_instance_valid(level_nodes[0]):
		print("Found level node via group: ", level_nodes[0].name)
		return level_nodes[0]
	
	# Method 2: Look for a node with game_over method in scene tree
	var root = get_tree().current_scene
	if root and is_instance_valid(root) and root.has_method("game_over"):
		print("Found level node as scene root: ", root.name)
		return root
	
	# Method 3: Search parent nodes
	var current = get_parent()
	while current and is_instance_valid(current):
		if current.has_method("game_over"):
			print("Found level node as parent: ", current.name)
			return current
		current = current.get_parent()
	
	print("No suitable level node found")
	return null

func increase_speed(speed_increase: float = 10.0) -> void:
	# Method to increase difficulty over time
	move_speed += speed_increase
	print("Rock speed increased to: ", move_speed)

func reset_speed() -> void:
	# Reset to original speed
	move_speed = original_speed
	print("Rock speed reset to: ", move_speed)

func pause_rock() -> void:
	# Method to pause rock movement
	is_active = false
	set_process(false)

func resume_rock() -> void:
	# Method to resume rock movement
	is_active = true
	set_process(true)

func _exit_tree() -> void:
	# Clean up when rock is destroyed
	print("Rock destroyed at position: ", position)
