extends Control

@onready var _icon: Label = $HBox/IconLabel
@onready var _count_label: Label = $HBox/CountLabel


func _ready() -> void:
	visible = false
	CowWrangleQuest.quest_accepted.connect(_on_quest_accepted)
	CowWrangleQuest.wrangle_count_changed.connect(_on_wrangle_count_changed)
	CowWrangleQuest.quest_completed.connect(_on_quest_completed)


func _on_quest_accepted() -> void:
	visible = true
	_update_count(0, CowWrangleQuest.REQUIRED_COWS)


func _on_wrangle_count_changed(wrangled: int, total: int) -> void:
	if CowWrangleQuest.accepted:
		visible = true
	_update_count(wrangled, total)


func _on_quest_completed() -> void:
	_update_count(CowWrangleQuest.REQUIRED_COWS, CowWrangleQuest.REQUIRED_COWS)


func _update_count(wrangled: int, total: int) -> void:
	_count_label.text = "%d/%d" % [wrangled, total]
