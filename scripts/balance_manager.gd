extends Node
class_name BalanceManager

const DEFAULT_CONFIG_PATH := "res://scripts/balance/default_balance.tres"

var config = load(DEFAULT_CONFIG_PATH)


func _ready() -> void:
	if config == null:
		config = load(DEFAULT_CONFIG_PATH)
