extends Resource
class_name BalanceConfig

@export_group("Speed")
@export var default_scroll_speed: float = 240.0
@export var speed_up_threshold: int = 3
@export var speed_up_boost_duration: float = 6.0
@export var speed_up_timer_multiplier: float = 1.25
@export var speed_up_multipliers: Array[float] = [1.0, 1.4, 1.8]
@export var speed_down_threshold: int = 3
@export var speed_down_multipliers: Array[float] = [1.0, 0.8, 0.6]

@export_group("Scoring")
@export var base_score_per_meter: float = 10.0
@export var score_distance_divisor: float = 10.0
@export var score_box: int = 250
@export var score_pill: int = 120
@export var score_speed_up: int = 50
@export var score_speed_down: int = 0

@export_group("Scenario")
@export var transition_score: int = 20000

@export_group("Chunks")
@export var spawn_buffer_px: float = 320.0
@export var recycle_buffer_px: float = 128.0
@export var chunk_overlap_px: float = 32.0
