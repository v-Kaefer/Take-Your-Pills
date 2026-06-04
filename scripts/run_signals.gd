extends Node

@warning_ignore_start("unused_signal")
signal request_next_chunk(chunk: Node)
signal chunk_exited_screen(chunk: Node)
signal player_hit_obstacle(obstacle: Node, body: Node)
signal collectable_collected(collectable: Node, body: Node, score_value: int)
signal run_booted
signal run_running
signal run_paused
signal run_game_over
signal score_changed(score: int)
signal distance_changed(distance: float)
signal speed_up_collected
signal speed_down_collected
signal speed_state_changed(level: int, threshold: int, boost_active: bool)
signal speed_too_slow
