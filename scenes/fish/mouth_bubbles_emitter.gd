class_name MoutBubblesEmitter
extends GPUParticles2D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not emitting:
		await Util.wait(lifetime)
		queue_free()
