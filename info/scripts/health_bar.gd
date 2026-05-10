class_name HealthBar
extends PanelContainer

func setup(character: Character) -> void:
	%Label.text = character.name
	%ProgressBar.max_value = character.max_health
	%ProgressBar.value = character.current_health

func update(character: Character) -> void:
	%ProgressBar.value = character.current_health
