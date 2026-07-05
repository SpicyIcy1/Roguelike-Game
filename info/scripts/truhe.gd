extends Entity

var opened = false

func take_damage(amount: float) -> void:
	if not opened:
		open()
		opened = true


func open():
	$Sprite2D.region_rect = Rect2(Vector2(20,0), Vector2(20,27))
	PlayerData.add_morality(5)
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("equip_item"):
		player.equip_item(ThrowingSpearItem.new())

func close():
	$Sprite2D.region_rect = Rect2(Vector2(0,0), Vector2(20,27))
