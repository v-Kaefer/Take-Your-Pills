extends CanvasLayer
class_name GameHUD

@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var distance_label: Label = $MarginContainer/VBoxContainer/DistanceLabel
@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var start_button: Button = $MainMenu/Panel/VBoxContainer/StartButton
@onready var resume_button: Button = $PauseMenu/Panel/VBoxContainer/ResumeButton
@onready var pause_restart_button: Button = $PauseMenu/Panel/VBoxContainer/RestartButton
@onready var final_score_label: Label = $GameOverMenu/Panel/VBoxContainer/FinalScoreLabel
@onready var game_over_restart_button: Button = $GameOverMenu/Panel/VBoxContainer/RestartButton

var _score: int = 0
var _distance: float = 0.0


func _ready() -> void:
	RunSignals.run_booted.connect(_on_run_booted)
	RunSignals.run_running.connect(_on_run_running)
	RunSignals.run_paused.connect(_on_run_paused)
	RunSignals.run_game_over.connect(_on_run_game_over)
	RunSignals.score_changed.connect(_on_score_changed)
	RunSignals.distance_changed.connect(_on_distance_changed)
	_on_run_booted()


func update_state(state_text: String, control_note: String, extra_note: String = "") -> void:
	if extra_note.is_empty():
		state_label.text = "State: %s\nControls: %s" % [state_text, control_note]
	else:
		state_label.text = "State: %s\nNote: %s\nControls: %s" % [state_text, extra_note, control_note]


func update_score(score: int) -> void:
	score_label.text = "Score: %06d" % score


func update_distance(distance: float) -> void:
	distance_label.text = "Distance: %d m" % int(distance)


func show_main_menu() -> void:
	hide_menus()
	main_menu.show()
	update_state("MENU", "Start: button / Space")


func show_running_state() -> void:
	hide_menus()
	update_state("RUNNING", "Jump: Space | Esc: pause | Backspace: game over")


func show_pause_menu() -> void:
	hide_menus()
	pause_menu.show()
	update_state("PAUSED", "Resume: button / Esc | Restart: button")


func show_game_over(score: int) -> void:
	hide_menus()
	final_score_label.text = "Final score: %06d" % score
	game_over_menu.show()
	update_state("GAME OVER", "Jump: restart | Restart: button")


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


func _on_run_booted() -> void:
	_score = 0
	_distance = 0.0
	update_score(_score)
	update_distance(_distance)
	show_main_menu()


func _on_run_running() -> void:
	show_running_state()


func _on_run_paused() -> void:
	show_pause_menu()


func _on_run_game_over() -> void:
	show_game_over(_score)


func _on_score_changed(score: int) -> void:
	_score = score
	update_score(score)


func _on_distance_changed(distance: float) -> void:
	_distance = distance
	update_distance(distance)
