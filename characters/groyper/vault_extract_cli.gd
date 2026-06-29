extends SceneTree

const VaultExtractScript := preload("res://characters/groyper/vault_extract.gd")

func _init() -> void:
	var err := VaultExtractScript.extract_to_res()
	quit(0 if err == OK else 1)
