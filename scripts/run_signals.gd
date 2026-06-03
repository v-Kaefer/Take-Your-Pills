extends Node

@warning_ignore_start("unused_signal")
signal request_next_chunk(chunk: Node)
signal chunk_exited_screen(chunk: Node)
signal player_hit_obstacle(obstacle: Node, body: Node)
signal collectable_collected(collectable: Node, body: Node, score_value: int)
