class_name ObstacleBehaviorTestSuite
extends GdUnitTestSuite

const PLAYER_SCENE := "res://scenes/player/player.tscn"
const OBSTACLE_SCENE := "res://scenes/game/obstacles/obstacle.tscn"


class HitCounter:
	var count: int = 0

	func record(_obstacle: Node, _body: Node) -> void:
		count += 1


func test_obstacle_emits_player_hit_only_once_for_player_bodies() -> void:
	var obstacle := preload(OBSTACLE_SCENE).instantiate() as Obstacle
	var player := preload(PLAYER_SCENE).instantiate() as Player
	var non_player := Node2D.new()
	var counter := HitCounter.new()
	var on_hit := Callable(counter, "record")

	RunSignals.player_hit_obstacle.connect(on_hit)

	obstacle._on_body_entered(non_player)
	obstacle._on_body_entered(player)
	obstacle._on_body_entered(player)

	RunSignals.player_hit_obstacle.disconnect(on_hit)

	assert_int(counter.count).is_equal(1)

	obstacle.free()
	player.free()
	non_player.free()
