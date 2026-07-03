extends Node2D

var opened = false

func open():
	$Sprite2D.region_rect = Rect2(Vector2(20,0), Vector2(20,27))

func close():
	$Sprite2D.region_rect = Rect2(Vector2(0,0), Vector2(20,27))
