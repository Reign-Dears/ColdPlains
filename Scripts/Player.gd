extends CharacterBody3D

signal health_changed(health_value)

@export var collision_shape : CollisionShape3D
@export var pistol : Node3D
@export var pistol_muzzle_flash : GPUParticles3D
@export var toygun : Node3D
@export var uzi : Node3D
@export var Uzi_muzzle_flash : GPUParticles3D
@export var rifle : Node3D
@export var rifle_muzzle_flash : GPUParticles3D
@export var camera : Camera3D
@export var anim_player : AnimationPlayer
@export var raycast : RayCast3D
@export var flashlight : Node3D
@export var enemy_raycast : RayCast3D
@export var particle_raycast : RayCast3D

@export var walk_speed: float = 5.0
@export var slide_speed: float = 20.0
@export var slide_duration: float = 0.5
@export var slide_friction: float = 0.95
@export var no_cooldown = false

var current_weapon = null
var hit_explosion_scene = preload("res://Shaders/hit_explosion.tscn")
var is_shooting: bool = false # Checks the shooting state
var can_shoot: bool = true

var is_sliding: bool = false
var slide_timer: float = 0.0
var is_dead: bool = false

var health = 100
var damage = 10

var SPEED = 10.0
var JUMP_VELOCITY = 10.0
const LOOK_SPEED = 5

var gravity = 20.0

var crouch_height = 0.5
var stand_height = 2.0
var is_crouched = false
var crouch_speed = 3
var crouch_jump_velocity = 3
const CROUCH_TRANSLATE = 0.7

# Debug mode toggle
var debug_mode = true
var debug_file: FileAccess
var frame_count = 0

func _enter_tree():
	print(name)
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): 
		return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	$CanvasLayer.visible = true
	
	if debug_mode:
		debug_file = FileAccess.open("user://player_movement_debug.txt", FileAccess.WRITE)
		if debug_file:
			debug_file.store_line("=== PLAYER MOVEMENT DEBUG LOG ===")
			debug_file.store_line("Timestamp: " + str(Time.get_ticks_msec()))
			debug_file.store_line("")
		print("=== PLAYER DEBUG MODE ENABLED ===")
		print("Initial SPEED: ", SPEED)
		print("Initial gravity: ", gravity)
		print("Jump velocity: ", JUMP_VELOCITY)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if debug_file and debug_mode:
		debug_file = null

func _unhandled_input(event):
	if not is_multiplayer_authority() or is_dead:
		return

	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	# Handle shooting input
	if Input.is_action_just_pressed("shoot"):
		is_shooting = true
		if current_weapon == uzi or current_weapon == rifle:
			anim_player.play("automatic_weapons_shoot")
			play_shoot_effects.rpc()
			perform_shooting_logic()
		else:  # pistol or toygun
			# Enforcing the shooting animation waiting mechanism
			if can_shoot or no_cooldown:
				can_shoot = false  # Set this to false to prevent immediate re-shot
				anim_player.play("shoot")
				play_shoot_effects.rpc()
				perform_shooting_logic()
			else:
				print("Cannot shoot yet; waiting for animation to finish.")

	elif Input.is_action_pressed("shoot") and is_shooting and (current_weapon == uzi or current_weapon == rifle):
		# Continue automatic fire while held
		if anim_player.current_animation != "automatic_weapons_shoot":
			anim_player.play("automatic_weapons_shoot")
		play_shoot_effects.rpc()
		perform_shooting_logic()

	if Input.is_action_just_pressed("capture_toggle") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif Input.is_action_just_pressed("capture_toggle"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	elif Input.is_action_just_released("shoot"):
		is_shooting = false

	
func _physics_process(delta):
	if not is_multiplayer_authority() or is_dead: 
		return
	
	frame_count += 1
	
	_handle_crouch(delta)
	
	# DEBUG: Print input
	var input_dir = Input.get_vector("left", "right", "up", "down")
	if debug_mode and input_dir != Vector2.ZERO:
		print("--- INPUT ---")
		print("Input direction: ", input_dir)
	
	# DEBUG: Print on_floor status
	if debug_mode and (Input.is_action_pressed("left") or Input.is_action_pressed("right") or Input.is_action_pressed("up") or Input.is_action_pressed("down")):
		print("On floor: ", is_on_floor())
	
	# GRAVITY
	if not is_on_floor():
		velocity.y -= gravity * delta
		if debug_mode:
			print("Falling - Velocity Y: ", velocity.y)
	
	# JUMP
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity += JUMP_VELOCITY * get_floor_normal()
		if debug_mode:
			print("JUMP! Velocity Y after jump: ", velocity.y)
		
	if Input.is_action_just_pressed("toggle_flashlight"):
		flashlight.visible = not flashlight.visible

	# SLIDE
	if Input.is_action_just_pressed("slide") and is_on_floor():
		var slide_input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (transform.basis * Vector3(slide_input_dir.x, 0, slide_input_dir.y)).normalized()
		if direction != Vector3.ZERO and not is_sliding:
			if debug_mode:
				print("--- SLIDE START ---")
				print("Slide direction: ", direction)
				print("Slide speed: ", slide_speed)
			start_slide(direction)

	# MOVEMENT LOGIC
	if is_sliding:
		slide_timer += delta
		velocity.x *= slide_friction
		velocity.z *= slide_friction
		if debug_mode:
			print("SLIDING - Timer: ", slide_timer, " / ", slide_duration)
			print("Slide velocity: X=", velocity.x, " Z=", velocity.z)
		if slide_timer >= slide_duration:
			is_sliding = false
			if debug_mode:
				print("--- SLIDE END ---")
	else:
		var move_input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (transform.basis * Vector3(move_input_dir.x, 0, move_input_dir.y)).normalized()
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			if debug_mode:
				print("--- MOVING ---")
				print("Direction: ", direction)
				print("SPEED: ", SPEED)
				print("Velocity X: ", velocity.x, " Z: ", velocity.z)
		else:
			var damping_value = 10
			velocity.x = move_toward(velocity.x, 0, SPEED / damping_value * abs(velocity.normalized().x))
			velocity.z = move_toward(velocity.z, 0, SPEED / damping_value * abs(velocity.normalized().z))
			if debug_mode and (velocity.x != 0 or velocity.z != 0):
				print("--- SLOWING DOWN (DAMPING) ---")
				print("Damped velocity X: ", velocity.x, " Z: ", velocity.z)

	var look_dir = Input.get_vector("look_left", "look_right", "look_up", "look_down")
	
	if look_dir != Vector2.ZERO:
		rotate_y(-look_dir.x * LOOK_SPEED * delta)
		camera.rotate_x(-look_dir.y * LOOK_SPEED * delta)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	if anim_player.current_animation == "shoot":
		pass
	elif Input.get_vector("left", "right", "up", "down") != Vector2.ZERO and is_on_floor():
		anim_player.play("move")
	else:
		anim_player.play("idle")
	
	if Input.is_action_just_pressed("swap_to_pistol"):
		switch_weapons(pistol)
	if Input.is_action_just_pressed("swap_to_toy_gun"):
		switch_weapons(toygun)
	if Input.is_action_just_pressed("swap_to_uzi"):
		switch_weapons(uzi)
	if Input.is_action_just_pressed("swap_to_rifle"):
		switch_weapons(rifle)

	if is_shooting and current_weapon == uzi:
		perform_shooting_logic()
		
	if is_shooting and current_weapon == rifle:
		perform_shooting_logic()

	# DEBUG: Final velocity before move_and_slide
	if debug_mode:
		print("Final velocity: X=", velocity.x, " Y=", velocity.y, " Z=", velocity.z)
		print("Player position: ", global_position)
		print("---")

	# DEBUG: Write to file every 10 frames
	if debug_mode and frame_count % 10 == 0 and debug_file:
		write_debug_data(delta, input_dir)

	move_and_slide()

func write_debug_data(delta: float, input_dir: Vector2):
	if not debug_file:
		return
	
	# DATA 1: Position
	var pos_x = snapped(global_position.x, 0.01)
	var pos_y = snapped(global_position.y, 0.01)
	var pos_z = snapped(global_position.z, 0.01)
	
	# DATA 2: Velocity
	var vel_x = snapped(velocity.x, 0.01)
	var vel_y = snapped(velocity.y, 0.01)
	var vel_z = snapped(velocity.z, 0.01)
	
	# DATA 3: Current Speed
	var current_speed = snapped(Vector3(velocity.x, 0, velocity.z).length(), 0.01)
	
	debug_file.store_line("[FRAME " + str(frame_count) + "]")
	debug_file.store_line("POSITION: X=" + str(pos_x) + " Y=" + str(pos_y) + " Z=" + str(pos_z))
	debug_file.store_line("VELOCITY: X=" + str(vel_x) + " Y=" + str(vel_y) + " Z=" + str(vel_z))
	debug_file.store_line("SPEED: " + str(current_speed) + " units/sec")
	debug_file.store_line("-" * 40)

func perform_shooting_logic():
	if raycast.is_colliding():
		var hit_player = raycast.get_collider()
		hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())
	if enemy_raycast.is_colliding():
		enemy_raycast.get_collider().damage_taken += damage
	if particle_raycast.is_colliding():
		var hit_explosion = hit_explosion_scene.instantiate()
		var pos = particle_raycast.get_collision_point()
		var norm = particle_raycast.get_collision_normal()
		hit_explosion.look_at_from_position(pos, norm + pos)
		hit_explosion.setup_particles(damage) #damage for this function should be replaced with damage from the current weapon
		get_parent().add_child(hit_explosion)

func switch_weapons(selected_weapon):
	#Hide all weapons
	pistol.hide()
	toygun.hide()
	uzi.hide()
	rifle.hide()
	# Show the selected weapon
	current_weapon = selected_weapon
	if current_weapon:
		current_weapon.show()
		
func _on_animation_player_animation_finished(anim_name):
	print("Animation finished: ", anim_name)  # Check this is called for the "shoot" animation
	if anim_name == "shoot":
		can_shoot = true  # Allow shooting again only when shoot animation finishes
		anim_player.play("idle")  # Transition to idle after shooting

func start_slide(direction: Vector3) -> void:
	is_sliding = true
	slide_timer = 0.0
	velocity.x = direction.x * slide_speed
	velocity.z = direction.z * slide_speed

@rpc("call_local")
func play_shoot_effects():
	if current_weapon == pistol:
		if pistol_muzzle_flash:
			pistol_muzzle_flash.restart()
			pistol_muzzle_flash.emitting = true
		else:
			print("Muzzle flash for pistol is null")
	elif current_weapon == uzi:
		if Uzi_muzzle_flash:
			Uzi_muzzle_flash.restart()
			Uzi_muzzle_flash.emitting = true
		else:
			print("Rifle muzzle flash is null")
	elif current_weapon == rifle:
		if rifle_muzzle_flash:
			rifle_muzzle_flash.restart()
			rifle_muzzle_flash.emitting = true
		else:
			print("Uzi muzzle flash is null")



@rpc("any_peer", "call_local")
func receive_damage():
	print("receive_damage() called on player:", name)
	if is_dead:
		print("Player is already dead, ignoring damage")
		return
	health -= damage
	print("Health reduced to:", health)
	health_changed.emit(health)
	print("health_changed signal emitted with value:", health)
	if health <= 0:
		print("Player dead, calling die()")
		is_dead = true
		rpc("die")

func _handle_crouch(delta) -> void:
	if is_crouched: 
		SPEED = crouch_speed 
		JUMP_VELOCITY = crouch_jump_velocity
	else: 
		SPEED = 10
		JUMP_VELOCITY = 10
	
	is_crouched = Input.is_action_pressed("crouch")
	if debug_mode and is_crouched:
		print("CROUCH: SPEED=", SPEED, " JUMP_VELOCITY=", JUMP_VELOCITY)
	
	camera.position = Vector3(0,(CROUCH_TRANSLATE if is_crouched else 1.513),0)
	$CollisionShape3D.shape.height = stand_height - CROUCH_TRANSLATE if is_crouched else stand_height
	$CollisionShape3D.position.y = $CollisionShape3D.shape.height / 2

@rpc("authority", "call_local")
func die():
	#if is_dead:
		#return
	velocity = Vector3.ZERO
	set_process(false)
	set_physics_process(false)
	hide()
	if is_multiplayer_authority():
		get_tree().call_group("ui","show_lose_screen")
