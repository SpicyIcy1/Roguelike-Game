class_name Sword
extends Equipment

# Farbe zum Unterscheiden der Schwerter (Rarität): wird auf das Drop- und
# das ausgerüstete Waffen-Sprite gelegt (modulate).
var color: Color = Color.WHITE

func _init() -> void:
	equipment_name = "Eisenschwert"
	description = "Das Schwert der Goats."
	type = Type.WEAPON
	damage_bonus = 5.0
	attack_range_bonus = 0.0
	attack_cooldown_bonus = -0.05


# Droppbare Schwerter, sortiert von schwach nach stark.
# "weight" = relative Drop-Chance: je besser das Schwert, desto kleiner das Gewicht,
# also desto unwahrscheinlicher der Drop.
# "color" = Rarität-Farbe (grau -> grün -> blau -> lila -> gold).
static func _drop_table() -> Array:
	return [
		{"name": "Holzschwert",    "damage": 8.0,  "cooldown": 0.0,   "weight": 50.0, "color": Color(0.75, 0.75, 0.78)},
		{"name": "Eisenschwert",   "damage": 15.0, "cooldown": -0.05, "weight": 25.0, "color": Color(0.35, 0.9, 0.4)},
		{"name": "Stahlschwert",   "damage": 22.0, "cooldown": -0.08, "weight": 12.0, "color": Color(0.35, 0.55, 1.0)},
		{"name": "Silberschwert",  "damage": 30.0, "cooldown": -0.12, "weight": 5.0,  "color": Color(0.7, 0.35, 1.0)},
		{"name": "Drachentöter",   "damage": 45.0, "cooldown": -0.15, "weight": 2.0,  "color": Color(1.0, 0.62, 0.1)},
	]


# Baut ein Sword-Resource aus einem Katalog-Eintrag.
static func from_entry(entry: Dictionary) -> Sword:
	var s := Sword.new()
	s.equipment_name = entry["name"]
	s.description = "Ein erbeutetes Schwert."
	s.type = Type.WEAPON
	s.damage_bonus = entry["damage"]
	s.attack_cooldown_bonus = entry["cooldown"]
	s.color = entry["color"]
	return s


# Zufälliges Schwert nach Gewichten: bessere Schwerter fallen seltener.
static func random_drop() -> Sword:
	var table := _drop_table()
	var total := 0.0
	for entry in table:
		total += entry["weight"]
	var roll := randf() * total
	for entry in table:
		roll -= entry["weight"]
		if roll <= 0.0:
			return from_entry(entry)
	return from_entry(table[0])
