extends Node

const GAME_SCENE_PATH := "res://scenes/game/game.tscn"
const PILL_SCENE_PATH := "res://scenes/game/collectables/pill_collectable.tscn"
const FRAME_DELTA := 1.0 / 60.0
const MAX_SIM_SECONDS := 180.0
const BENCHMARK_SAMPLES := 7
const BENCHMARK_SIGNAL_EMITS := 20000
const BENCHMARK_FRAME_TICKS := 6000

var _run_signals: Node = null


func _ready() -> void:
	_run_signals = get_node_or_null("/root/RunSignals")
	call_deferred("_run")


func _run() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	var mode := String(options.get("mode", "impact"))
	var output_path := String(options.get("output", ""))
	var label := String(options.get("label", ""))
	var payload := {
		"label": label,
		"mode": mode,
		"status": "ok",
		"result": {}
	}

	match mode:
		"impact":
			payload["result"] = await _collect_impact_metrics()
		"benchmark":
			payload["result"] = await _collect_benchmark_metrics()
		_:
			payload["status"] = "error"
			payload["error"] = "Unsupported mode: %s" % mode

	if output_path.is_empty():
		print(JSON.stringify(payload, "\t"))
	else:
		_write_json(output_path, payload)

	get_tree().quit(0 if payload["status"] == "ok" else 1)


func _collect_impact_metrics() -> Dictionary:
	var thresholds := _resolve_thresholds()
	var result := {
		"thresholds": thresholds,
		"pacing_response": await _measure_pacing_response(thresholds),
		"progression": await _measure_progression(thresholds),
		"pill_bonus": await _measure_pill_bonus(),
		"speed_up": await _measure_speed_up(),
		"speed_down": await _measure_speed_down()
	}
	return result


func _collect_benchmark_metrics() -> Dictionary:
	var thresholds := _resolve_thresholds()
	var result := {
		"thresholds": thresholds,
		"score_signal_burst": await _measure_score_signal_burst(thresholds),
		"score_tick_loop": await _measure_score_tick_loop()
	}
	return result


func _measure_pacing_response(thresholds: Dictionary) -> Dictionary:
	var game := await _spawn_game()
	_start_run(game)

	var chunks := game.get_node("World/Chunks")
	var observed := {
		"opening_scroll_speed": _round_float(float(chunks.get("scroll_speed")))
	}

	_emit_run_signal("score_changed", [thresholds["mid"]])
	observed["mid_scroll_speed"] = _round_float(float(chunks.get("scroll_speed")))

	_emit_run_signal("score_changed", [thresholds["transition"]])
	observed["transition_scroll_speed"] = _round_float(float(chunks.get("scroll_speed")))
	observed["scenario_after_transition"] = String(chunks.get("active_scenario_id"))

	_emit_run_signal("score_changed", [thresholds["late"]])
	observed["late_scroll_speed"] = _round_float(float(chunks.get("scroll_speed")))

	await _despawn_game(game)
	return observed


func _measure_progression(thresholds: Dictionary) -> Dictionary:
	var game := await _spawn_game()
	_start_run(game)

	var chunks := game.get_node("World/Chunks")
	var score_controller := game.get_node("Controllers/RunScoreController")
	var targets := [
		{"name": "mid", "score": int(thresholds["mid"])},
		{"name": "transition", "score": int(thresholds["transition"])},
		{"name": "late", "score": int(thresholds["late"])}
	]
	var target_index := 0
	var elapsed := 0.0
	var result := {}

	while elapsed < MAX_SIM_SECONDS and target_index < targets.size():
		score_controller.call("tick", FRAME_DELTA)
		elapsed += FRAME_DELTA

		var score := int(score_controller.get("score"))
		while target_index < targets.size() and score >= targets[target_index]["score"]:
			var label := String(targets[target_index]["name"])
			result["seconds_to_%s" % label] = _round_float(elapsed)
			result["score_at_%s" % label] = score
			result["scroll_speed_at_%s" % label] = _round_float(float(chunks.get("scroll_speed")))
			result["scenario_at_%s" % label] = String(chunks.get("active_scenario_id"))
			target_index += 1

	result["final_score"] = int(score_controller.get("score"))
	result["final_distance"] = _round_float(float(score_controller.get("distance")))

	await _despawn_game(game)
	return result


func _measure_pill_bonus() -> Dictionary:
	var game := await _spawn_game()
	_start_run(game)

	var score_controller := game.get_node("Controllers/RunScoreController")
	var player := game.get_node("World/Player")
	var baseline_score := int(score_controller.get("score"))
	var pill_value := _resolve_pill_score_value()

	_emit_run_signal("collectable_collected", [null, player, pill_value])

	var updated_score := int(score_controller.get("score"))
	var result := {
		"score_value": pill_value,
		"score_delta": updated_score - baseline_score
	}

	await _despawn_game(game)
	return result


func _measure_speed_up() -> Dictionary:
	var game := await _spawn_game()
	_start_run(game)

	var chunks := game.get_node("World/Chunks")
	var speed_up_controller := game.get_node("Controllers/SpeedUpBoostController")
	var session_controller := game.get_node("Controllers/RunSessionController")

	for _step in range(3):
		_emit_run_signal("speed_up_collected")

	var tier_one_speed := _round_float(float(chunks.get("scroll_speed")))
	var tier_one_timer := _round_float(float(speed_up_controller.get("_boost_timer")))

	for _step in range(3):
		_emit_run_signal("speed_up_collected")

	var base_speed := _round_float(float(session_controller.get("default_scroll_speed")))
	var result := {
		"base_scroll_speed": base_speed,
		"tier_one_speed": tier_one_speed,
		"tier_one_multiplier": _safe_ratio(tier_one_speed, base_speed),
		"tier_one_timer": tier_one_timer,
		"tier_two_speed": _round_float(float(chunks.get("scroll_speed"))),
		"tier_two_multiplier": _safe_ratio(float(chunks.get("scroll_speed")), base_speed),
		"tier_two_timer": _round_float(float(speed_up_controller.get("_boost_timer")))
	}

	await _despawn_game(game)
	return result


func _measure_speed_down() -> Dictionary:
	var game := await _spawn_game()
	_start_run(game)

	var chunks := game.get_node("World/Chunks")
	var session_controller := game.get_node("Controllers/RunSessionController")
	var base_speed := _round_float(float(session_controller.get("default_scroll_speed")))

	for _step in range(3):
		_emit_run_signal("speed_down_collected")
	var tier_one_speed := _round_float(float(chunks.get("scroll_speed")))

	for _step in range(3):
		_emit_run_signal("speed_down_collected")
	var tier_two_speed := _round_float(float(chunks.get("scroll_speed")))

	for _step in range(3):
		_emit_run_signal("speed_down_collected")

	var result := {
		"base_scroll_speed": base_speed,
		"tier_one_speed": tier_one_speed,
		"tier_one_multiplier": _safe_ratio(tier_one_speed, base_speed),
		"tier_two_speed": tier_two_speed,
		"tier_two_multiplier": _safe_ratio(tier_two_speed, base_speed),
		"game_over_after_third_stack": bool(session_controller.call("is_game_over"))
	}

	await _despawn_game(game)
	return result


func _measure_score_signal_burst(thresholds: Dictionary) -> Dictionary:
	var game := await _spawn_game()
	var session_controller := game.get_node("Controllers/RunSessionController")
	var samples: Array[float] = []
	var cycle_size: int = maxi(int(thresholds["late"]) + 1000, 33000)

	for _warmup in range(2):
		_reset_run(session_controller)
		for emit_index in range(500):
			_emit_run_signal("score_changed", [emit_index % cycle_size])

	for _sample_index in range(BENCHMARK_SAMPLES):
		_reset_run(session_controller)
		var started_at := Time.get_ticks_usec()
		for emit_index in range(BENCHMARK_SIGNAL_EMITS):
			_emit_run_signal("score_changed", [emit_index % cycle_size])
		var elapsed := Time.get_ticks_usec() - started_at
		samples.append(_round_float(float(elapsed) / float(BENCHMARK_SIGNAL_EMITS)))

	await _despawn_game(game)
	return {
		"iterations": BENCHMARK_SIGNAL_EMITS,
		"median_us_per_emit": _median(samples),
		"samples_us_per_emit": samples
	}


func _measure_score_tick_loop() -> Dictionary:
	var game := await _spawn_game()
	var session_controller := game.get_node("Controllers/RunSessionController")
	var score_controller := game.get_node("Controllers/RunScoreController")
	var samples: Array[float] = []

	for _warmup in range(2):
		_reset_run(session_controller)
		for _frame_index in range(300):
			score_controller.call("tick", FRAME_DELTA)

	for _sample_index in range(BENCHMARK_SAMPLES):
		_reset_run(session_controller)
		var started_at := Time.get_ticks_usec()
		for _frame_index in range(BENCHMARK_FRAME_TICKS):
			score_controller.call("tick", FRAME_DELTA)
		var elapsed := Time.get_ticks_usec() - started_at
		samples.append(_round_float(float(elapsed) / float(BENCHMARK_FRAME_TICKS)))

	await _despawn_game(game)
	return {
		"iterations": BENCHMARK_FRAME_TICKS,
		"median_us_per_frame": _median(samples),
		"samples_us_per_frame": samples
	}


func _spawn_game() -> Node:
	var packed_scene := load(GAME_SCENE_PATH) as PackedScene
	var game := packed_scene.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	return game


func _despawn_game(game: Node) -> void:
	if game == null or not is_instance_valid(game):
		return
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _start_run(game: Node) -> void:
	game.call("_start_run")


func _reset_run(session_controller: Node) -> void:
	session_controller.call("boot")
	session_controller.call("start_run")


func _resolve_thresholds() -> Dictionary:
	return {
		"mid": _get_balance_int("mid_score_threshold", 8000),
		"transition": _get_balance_int("transition_score", 20000),
		"late": _get_balance_int("late_score_threshold", 32000)
	}


func _resolve_pill_score_value() -> int:
	var pill_scene := load(PILL_SCENE_PATH) as PackedScene
	if pill_scene == null:
		return 100

	var pill := pill_scene.instantiate()
	var score_value := int(pill.get("score_value"))
	if pill is Node:
		(pill as Node).queue_free()
	return score_value


func _get_balance_int(field_name: String, fallback: int) -> int:
	var balance := get_node_or_null("/root/Balance")
	if balance == null:
		return fallback

	var config = balance.get("config")
	if config == null:
		return fallback

	var value = config.get(field_name)
	if value == null:
		return fallback

	return int(value)


func _emit_run_signal(signal_name: String, args: Array = []) -> void:
	if _run_signals == null:
		return

	match args.size():
		0:
			_run_signals.emit_signal(signal_name)
		1:
			_run_signals.emit_signal(signal_name, args[0])
		2:
			_run_signals.emit_signal(signal_name, args[0], args[1])
		3:
			_run_signals.emit_signal(signal_name, args[0], args[1], args[2])
		_:
			push_warning("Signal helper only supports up to three arguments.")


func _parse_args(args: PackedStringArray) -> Dictionary:
	var parsed := {}
	var index := 0
	while index < args.size():
		var token := args[index]
		if not token.begins_with("--"):
			index += 1
			continue

		var key := token.trim_prefix("--")
		var value := "true"
		if index + 1 < args.size() and not args[index + 1].begins_with("--"):
			value = args[index + 1]
			index += 1
		parsed[key] = value
		index += 1

	return parsed


func _write_json(output_path: String, payload: Dictionary) -> void:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open output path: %s" % output_path)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


func _median(samples: Array[float]) -> float:
	if samples.is_empty():
		return 0.0

	var ordered: Array[float] = samples.duplicate()
	ordered.sort()
	var middle := ordered.size() / 2
	if ordered.size() % 2 == 1:
		return _round_float(float(ordered[middle]))
	return _round_float((float(ordered[middle - 1]) + float(ordered[middle])) / 2.0)


func _safe_ratio(value: float, denominator: float) -> float:
	if is_zero_approx(denominator):
		return 0.0
	return _round_float(value / denominator)


func _round_float(value: float) -> float:
	return snappedf(value, 0.001)
