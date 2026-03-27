extends Node3D

@export var smoke_timer : Timer
@export var hole : Decal
@export var impact : GPUParticles3D
@export var explosion : GPUParticles3D
@export var sphere : GPUParticles3D
@export var smoke : GPUParticles3D

func _on_timer_timeout() -> void:
	queue_free()


func _on_smoke_timer_timeout() -> void:
	smoke.emitting = false


func _ready() -> void:
	impact.emitting = true
	explosion.emitting = true
	sphere.emitting = true
	smoke.emitting = true
	hole.rotate_y(randf() * 2 * PI)
	hole.rotate_x(randf_range(-1, 1) * PI / 4)
	hole.rotate_z(randf_range(-1, 1) * PI / 4)



func _process(delta: float) -> void:
	if smoke_timer:
		var lifetime_rat = smoke_timer.time_left / smoke_timer.wait_time
		if smoke:
			smoke.amount_ratio = (lifetime_rat ** 4) * 0.9 + lifetime_rat ** 0.2 * 0.1
		if hole:
			hole.albedo_mix = lifetime_rat ** 0.75
			var lifetime_ratmod = (lifetime_rat ** 3) * 0.9 + lifetime_rat ** 0.2 * 0.1
			hole.modulate = Color(lifetime_ratmod, lifetime_ratmod, lifetime_ratmod, 1)
			hole.scale = lifetime_rat ** 0.5 * Vector3.ONE
