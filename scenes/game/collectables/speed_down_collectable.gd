extends CollectableBase


func _on_body_entered(body: Node) -> void:
	if _collected:
		return

	if body is Player:
		RunSignals.speed_down_collected.emit()

	super._on_body_entered(body)
