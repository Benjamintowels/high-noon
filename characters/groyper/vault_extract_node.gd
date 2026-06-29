@tool
extends Node

const VaultExtractScript := preload("res://characters/groyper/vault_extract.gd")

## Attach to groyper_body.tscn. Toggle extract_vaults in the Inspector to refresh vault.tres.

@export var extract_vaults: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := VaultExtractScript.extract_to_res()
		if err != OK:
			push_error("VaultExtractNode: extraction failed (%s)." % err)
		extract_vaults = false
