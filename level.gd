# level.gd - FIXED VERSION
extends Node2D

# References to child nodes
@onready var rock = $Rock
@onready var points_label: Label = $PointsLabel

# Game state variables
var points := 0
var game_is_over := false

func _ready() -> void:
	# Add this level to a group so rocks can find it
	add_to_group("level")
	
	# Initialize points display
	update_points_label()
	
	# Wait one frame to ensure all nodes are ready
	await get_tree().process_frame
	
	# Connect to all existing rocks in the scene
	connect_all_rocks()
	
	# Make sure the main rock is properly set up
	setup_main_rock()
	
	print("Level initialized with ", get_tree().get_nodes_in_group("rocks").size(), " rocks")

func connect_all_rocks() -> void:
	# Find and connect to all rocks in the scene
	var rocks = get_tree().get_nodes_in_group("rocks")
	
	for r in rocks:
		if r and is_instance_valid(r):
			# Check if rock has the signal and we're not already connected
			if r.has_signal("change_point"):
				# Disconnect first to avoid duplicate connections
				if r.is_connected("change_point", _on_change_point):
					r.disconnect("change_point", _on_change_point)
				
				# Now connect
				r.connect("change_point", _on_change_point)
				print("Connected to rock: ", r.name)
			else:
				print("Warning: Rock ", r.name, " doesn't have change_point signal!")

func setup_main_rock() -> void:
	# Ensure the main rock is properly configured
	if rock and is_instance_valid(rock):
		# Add to rocks group if not already there
		if not rock.is_in_group("rocks"):
			rock.add_to_group("rocks")
		
		# Connect signal if not already connected
		if rock.has_signal("change_point"):
			if rock.is_connected("change_point", _on_change_point):
				rock.disconnect("change_point", _on_change_point)
			rock.connect("change_point", _on_change_point)
			print("Main rock connected!")
		else:
			print("Warning: Main rock doesn't have change_point signal!")
	else:
		print("Warning: Main rock not found or invalid!")

func _on_change_point() -> void:
	# Only add points if game is not over
	if not game_is_over:
		points += 1
		update_points_label()
		print("Points earned: ", points)
		
		# Optional: Increase difficulty every 5 points
		if points % 5 == 0:
			increase_difficulty()

func increase_difficulty() -> void:
	# Make rocks faster every 5 points
	var rocks = get_tree().get_nodes_in_group("rocks")
	for rock_node in rocks:
		if rock_node and is_instance_valid(rock_node) and rock_node.has_method("increase_speed"):
			rock_node.increase_speed(20.0)
	print("Difficulty increased! Rocks are now faster.")

func update_points_label() -> void:
	# Safely update the points display
	if points_label and is_instance_valid(points_label):
		points_label.text = "Points: %d" % points
	else:
		print("Warning: Points label not found or invalid!")

func game_over() -> void:
	# Prevent multiple game over calls
	if game_is_over:
		return
		
	game_is_over = true
	print("=== GAME OVER ===")
	print("Final Score: ", points)
	
	# Stop all rocks
	var rocks = get_tree().get_nodes_in_group("rocks")
	for rock_node in rocks:
		if rock_node and is_instance_valid(rock_node):
			rock_node.set_process(false)
	
	# Stop the floor movement
	var floor_node = get_node("Floor")
	if floor_node and is_instance_valid(floor_node):
		floor_node.set_process(false)
	
	# Show game over message on screen
	if points_label and is_instance_valid(points_label):
		points_label.text = "GAME OVER!\nScore: %d\nRestarting in 2s..." % points
	
	# Wait a moment before restarting
	await get_tree().create_timer(2.0).timeout
	
	# Make sure we're still valid before restarting
	if is_instance_valid(self):
		get_tree().reload_current_scene()

func _exit_tree() -> void:
	# Clean up connections when scene is destroyed
	var rocks = get_tree().get_nodes_in_group("rocks")
	for rock_node in rocks:
		if rock_node and is_instance_valid(rock_node) and rock_node.is_connected("change_point", _on_change_point):
			rock_node.disconnect("change_point", _on_change_point)
