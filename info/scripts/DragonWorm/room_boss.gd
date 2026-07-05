extends Node2D



@onready var boss : = $DragonWorm

func _ready():
	print("FIGHT!")
	boss.tree_exited.connect(_on_boss_disappeared)

func _on_boss_disappeared():
	$Wall.queue_free()
	print("Killed")
