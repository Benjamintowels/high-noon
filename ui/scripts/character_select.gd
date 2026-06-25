extends Control

signal fight_requested(character_id: String)

@onready var _get_it_on_button: Button = $Layout/Footer/GetItOnButton
@onready var _cards: Array[Node] = [
	$Layout/CharacterRow/LockedCardA,
	$Layout/CharacterRow/GroyperCard,
	$Layout/CharacterRow/LockedCardB,
]

var _selected_id: String = ""


func _ready() -> void:
	modulate.a = 0.0
	_get_it_on_button.disabled = true
	_get_it_on_button.pressed.connect(_on_get_it_on_pressed)
	for card in _cards:
		card.card_selected.connect(_on_card_selected)


func reveal() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_card_selected(card: Node) -> void:
	if card.locked:
		return

	for entry in _cards:
		entry.set_selected(entry == card)

	_selected_id = card.character_id
	_get_it_on_button.disabled = false


func _on_get_it_on_pressed() -> void:
	if _selected_id.is_empty():
		return
	fight_requested.emit(_selected_id)
