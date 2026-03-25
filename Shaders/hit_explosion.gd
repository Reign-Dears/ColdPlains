extends Node3D

@export var smoke_timer : Timer
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



func _process(delta: float) -> void:
	if smoke_timer:
		var lifetime_rat = smoke_timer.time_left / smoke_timer.wait_time
		smoke.amount_ratio = (lifetime_rat ** 4) * 0.9 + lifetime_rat ** 0.2 * 0.1
		
