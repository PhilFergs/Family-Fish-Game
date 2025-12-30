class_name HUD
extends CanvasLayer

@onready var status_label: Label = $StatusLabel

func update_status(tier: int, bites: int, bites_needed: int, health: int, max_health: int) -> void:
	status_label.text = "Tier %d  Bites %d/%d  Health %d/%d" % [tier, bites, bites_needed, health, max_health]
