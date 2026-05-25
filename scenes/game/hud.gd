extends CanvasLayer
class_name GameHUD

@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var start_button: Button = $MainMenu/Panel/VBoxContainer/StartButton
@onready var resume_button: Button = $PauseMenu/Panel/VBoxContainer/ResumeButton
@onready var pause_restart_button: Button = $PauseMenu/Panel/VBoxContainer/RestartButton
@onready var final_score_label: Label = $GameOverMenu/Panel/VBoxContainer/FinalScoreLabel
@onready var game_over_restart_button: Button = $GameOverMenu/Panel/VBoxContainer/RestartButton

func _ready() -> void:
	hide_menus()

func update_state(state_text: String, control_note: String, extra_note: String = "") -> void:
	if extra_note.is_empty():
		state_label.text = "State: %s\nControls: %s" % [state_text, control_note]
	else:
		state_label.text = "State: %s\nNote: %s\nControls: %s" % [state_text, extra_note, control_note]

func update_score(score: int) -> void:
	score_label.text = "Score: %06d" % score

func show_main_menu() -> void:
	hide_menus()
	main_menu.show()

func show_pause_menu() -> void:
	hide_menus()
	pause_menu.show()

func show_game_over(score: int) -> void:
	hide_menus()
	final_score_label.text = "Final score: %06d" % score
	game_over_menu.show()

func hide_menus() -> void:
	main_menu.hide()
	pause_menu.hide()
	game_over_menu.hide()

func connect_start(callable: Callable) -> void:
	start_button.pressed.connect(callable)

func connect_resume(callable: Callable) -> void:
	resume_button.pressed.connect(callable)

func connect_restart(callable: Callable) -> void:
	pause_restart_button.pressed.connect(callable)
	game_over_restart_button.pressed.connect(callable)
