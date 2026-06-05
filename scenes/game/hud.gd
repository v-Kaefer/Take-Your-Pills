extends CanvasLayer
class_name GameHUD

const COLOR_STRIPE_FILLED := Color(0.25, 0.55, 1.0, 1.0)
const COLOR_STRIPE_SLOW := Color(1.0, 0.42, 0.2, 1.0)
const COLOR_STRIPE_BOOST := Color(1.0, 0.25, 0.2, 1.0)
const COLOR_STRIPE_EMPTY := Color(0.25, 0.25, 0.3, 0.5)

@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var distance_label: Label = $MarginContainer/VBoxContainer/DistanceLabel
@onready var speed_icon: TextureRect = $MarginContainer/VBoxContainer/SpeedContainer/SpeedIcon
@onready var speed_stripes: HBoxContainer = $MarginContainer/VBoxContainer/SpeedContainer/Stripes
@onready var main_menu: Control = $MainMenu
@onready var pause_menu: Control = $PauseMenu
@onready var game_over_menu: Control = $GameOverMenu
@onready var start_button: Button = $MainMenu/Panel/VBoxContainer/StartButton
@onready var resume_button: Button = $PauseMenu/Panel/VBoxContainer/ResumeButton
@onready var pause_restart_button: Button = $PauseMenu/Panel/VBoxContainer/RestartButton
@onready var final_score_label: Label = $GameOverMenu/Panel/VBoxContainer/FinalScoreLabel
@onready var game_over_restart_button: Button = $GameOverMenu/Panel/VBoxContainer/RestartButton

var _speed_up_icon: Texture2D = null
var _speed_down_icon: Texture2D = null
var _speed_level: int = 0
var _speed_threshold: int = 3
var _boost_active: bool = false

func _ready() -> void:
	_speed_up_icon = load("res://assets/icon/asset_speed_up.png") as Texture2D
	_speed_down_icon = load("res://assets/icon/asset_speed_down.png") as Texture2D
	RunSignals.speed_state_changed.connect(_on_speed_state_changed)
	hide_menus()
	_refresh_speed_display()

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


func _on_speed_state_changed(level: int, threshold: int, boost_active: bool) -> void:
	_speed_level = level
	_speed_threshold = threshold
	_boost_active = boost_active
	_refresh_speed_display()


func _refresh_speed_display() -> void:
	var icon := _speed_down_icon
	var filled_color := COLOR_STRIPE_EMPTY
	var filled_count := 0

	if _boost_active:
		icon = _speed_up_icon
		filled_color = COLOR_STRIPE_BOOST
		filled_count = speed_stripes.get_child_count()
	elif _speed_level > 0:
		icon = _speed_up_icon
		filled_color = COLOR_STRIPE_FILLED
		filled_count = min(min(_speed_level, _speed_threshold), speed_stripes.get_child_count())
	elif _speed_level < 0:
		filled_color = COLOR_STRIPE_SLOW
		filled_count = min(min(abs(_speed_level), _speed_threshold), speed_stripes.get_child_count())

	if icon != null:
		speed_icon.texture = icon

	var stripes := speed_stripes.get_children()
	for i in stripes.size():
		var rect := stripes[i] as ColorRect
		if rect == null:
			continue
		if i < filled_count:
			rect.color = filled_color
		else:
			rect.color = COLOR_STRIPE_EMPTY
