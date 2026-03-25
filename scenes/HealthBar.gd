extends CanvasLayer

@onready var health_bar = $HealthBar


func _ready():
	connect_to_local_player()


func connect_to_local_player():
	# Loop through all players
	for player in get_tree().get_nodes_in_group("players"):
		
		# Only connect to YOUR player
		if player.is_multiplayer_authority():
			
			print("Connected to player:", player.name)  # debug
			
			player.health_changed.connect(_on_health_changed)
			
			# Set initial value
			health_bar.value = player.health


func _on_health_changed(new_health):
	print("Health updated:", new_health)  # debug
	health_bar.value = new_health
