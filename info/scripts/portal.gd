extends Area2D

@export var destination_path: String
@export var spawn_point_name: String  #der String muss GENAUSO heißen wie der Node in der Szene bei dem der Spieler spawnen soll. Warum nicht nur Ankunftsszene bei der der Spieler an die richtige Position gesetzt wird? Weil wir dann 2x amin Szene brauchen würden einmal wirklicher start und einmal wenn der Spieler wieder reinläuft
@export var required_morality: int = 0  # Portal bleibt zu, bis der Spieler so viel Moral hat (0 = immer offen)
var _transitioning := false

func _on_body_entered(body: Node2D) -> void:
	if _transitioning:
		return
	# Bossraum & Co. öffnen erst ab der geforderten Moral
	if PlayerData.moral_score < required_morality:
		print("Verschlossen: benötigt ", required_morality, " Moral (aktuell ", PlayerData.moral_score, ")")
		return
	_transitioning = true
	PlayerData.spawn_point = spawn_point_name
	get_tree().change_scene_to_file.call_deferred(destination_path) #fancy way zu verzögern wann die szene gewechselt wird damit der debugger nicht mit Fehlermeldungen überquillt
