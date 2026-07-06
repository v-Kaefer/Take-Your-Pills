extends Node
class_name BalanceManager

const DEFAULT_CONFIG_PATH := "res://scripts/balance/default_balance.tres"

var config: BalanceConfig


func _ready() -> void:
	config = load(DEFAULT_CONFIG_PATH) as BalanceConfig
