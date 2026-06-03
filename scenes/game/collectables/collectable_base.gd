extends Area2D
class_name CollectableBase

@export var score_value: int = 100
@export var collectable_type: StringName = &"collectable"

var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _collected:
		return

	if body is Player:
		_collected = true
		RunSignals.collectable_collected.emit(self, body, score_value)
		queue_free()
