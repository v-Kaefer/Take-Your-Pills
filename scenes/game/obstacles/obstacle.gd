extends Area2D
class_name Obstacle

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _triggered:
		return

	if body is Player:
		_triggered = true
		RunSignals.player_hit_obstacle.emit(self, body)
