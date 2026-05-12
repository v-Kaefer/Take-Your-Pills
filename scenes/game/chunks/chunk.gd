extends Node2D
class_name Chunk

@onready var trigger_next: Area2D = $TriggerNext
@onready var on_screen_notifier: VisibleOnScreenNotifier2D = $OnScreenNotifier

var _requested_next_chunk: bool = false


func _ready() -> void:
	trigger_next.body_entered.connect(_on_trigger_next_body_entered)
	on_screen_notifier.screen_exited.connect(_on_screen_exited)


func _on_trigger_next_body_entered(body: Node) -> void:
	if _requested_next_chunk:
		return

	if body is Player:
		_requested_next_chunk = true
		RunSignals.request_next_chunk.emit(self)


func _on_screen_exited() -> void:
	RunSignals.chunk_exited_screen.emit(self)
