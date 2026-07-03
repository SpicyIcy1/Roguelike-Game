extends Entity

var opened = false

func take_damage(amount: float) -> void:
	if not opened:
		open()
		opened = true


func open():
	$Sprite2D.region_rect = Rect2(Vector2(20,0), Vector2(20,27))
	PlayerData.add_morality(5)

func close():
	$Sprite2D.region_rect = Rect2(Vector2(0,0), Vector2(20,27))
