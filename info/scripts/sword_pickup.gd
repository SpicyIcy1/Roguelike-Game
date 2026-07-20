extends Area2D

# Am Boden liegendes Schwert, das der Spieler durch Berühren aufsammelt.
# Das konkrete Schwert wird beim Spawnen von außen gesetzt (siehe NPC-Drop).
var sword: Sword = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Schwert am Boden in seiner Rarität-Farbe einfärben
	if sword != null:
		$Sprite2D.modulate = sword.color

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if sword != null and body.has_method("equip_weapon_stats"):
		body.equip_weapon_stats(sword)
	queue_free()
