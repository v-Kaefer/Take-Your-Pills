extends CanvasLayer
class_name GameHUD

@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var restart_button: Button = $MarginContainer/VBoxContainer/RestartButton

func _ready() -> void:
	restart_button.hide()

func update_state(state_text: String, control_note: String, extra_note: String = "") -> void:
	if extra_note.is_empty():
		state_label.text = "State: %s\nControls: %s" % [state_text, control_note]
	else:
		state_label.text = "State: %s\nNote: %s\nControls: %s" % [state_text, extra_note, control_note]

func update_score(score: int) -> void:
	score_label.text = "Score: %06d" % score

func show_game_over() -> void:
	restart_button.show()

func hide_game_over() -> void:
	restart_button.hide()

func connect_restart(callable: Callable) -> void:
	restart_button.pressed.connect(callable)
