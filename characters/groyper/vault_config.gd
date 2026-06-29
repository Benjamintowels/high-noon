class_name VaultConfig
extends RefCounted

## Authored parkour vault clips for overworld fence vaulting.

const LIBRARY_NAME := &"vault"
const WALK_VAULT := &"walk_vault"
const RUN_VAULT := &"run_vault"

const OUT_PATH := "res://characters/groyper/vault.tres"
const RUN_VAULT_OUT_PATH := "res://characters/groyper/run_vault.tres"

const WALK_VAULT_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Parkour_Vault_frame_rate_60.fbx"
)
const RUN_VAULT_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Parkour_Vault_with_Roll_frame_rate_60.fbx"
)

const SOURCE_SCENES := {
	WALK_VAULT: WALK_VAULT_SCENE,
	RUN_VAULT: RUN_VAULT_SCENE,
}
