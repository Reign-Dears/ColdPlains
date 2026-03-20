extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
var SPEED = 3.0
var can_move = false
var stored_damage : Array
var seconds_stored = 1
var damage_taken = 0
const JUMP_VELOCITY = 4.5
@export var dps_label : Label3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func update_target_location (target_location):
	nav_agent.set_target_position(target_location)

func _physics_process(delta):
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	look_at(next_location) # Enemy will turn to face player
	
	# Vector Maths
	var new_veloicty = (next_location-current_location).normalized() * SPEED

	velocity = new_veloicty
	
	stored_damage.push_front(float(damage_taken))
	while stored_damage.size() > seconds_stored / delta:
		stored_damage.pop_back()
	
	damage_taken = 0
	
	dps_label.text = str(round(get_stored_damage() * 100) / 100)
	
	if can_move:
		move_and_slide()



func get_stored_damage():
	var storage : float
	for i in stored_damage.size():
		storage += stored_damage[i]
	return storage
