extends Node

var audio_player: AudioStreamPlayer = null


func _ready() -> void:
	RunSignals.collectable_collected.connect(_on_collectable_collected)


func _on_collectable_collected(_collectable: Node, _body: Node, _score_value: int) -> void:
	if audio_player == null:
		return

	audio_player.play()
