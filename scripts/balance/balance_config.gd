extends Resource
class_name BalanceConfig

@export_group("Speed")
@export var default_scroll_speed: float = 220.0
@export var mid_scroll_speed: float = 235.0
@export var transition_scroll_speed: float = 255.0
@export var late_scroll_speed: float = 270.0
@export var mid_score_threshold: int = 8000
@export var speed_up_threshold: int = 3
@export var speed_up_boost_duration: float = 8.0
@export var speed_up_timer_multiplier: float = 1.25
@export var speed_up_multipliers: Array[float] = [1.0, 1.35, 1.6]
@export var speed_down_threshold: int = 3
@export var speed_down_multipliers: Array[float] = [1.0, 0.85, 0.7]

@export_group("Scoring")
@export var base_score_per_meter: float = 10.0
@export var score_distance_divisor: float = 10.0

@export_group("Scenario")
@export var transition_score: int = 20000
@export var late_score_threshold: int = 32000
