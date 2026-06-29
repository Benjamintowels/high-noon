extends Node

enum GameMode { OVERWORLD, DUEL, TARGET }

const STAGE1_PATH := "res://stages/stage1/stage1.tscn"
const INTRO_CUTSCENE_PATH := "res://ui/scenes/intro_cutscene.tscn"
const LOADING_SCENE_PATH := "res://ui/scenes/loading_screen.tscn"
const ROUNDS_TO_WIN := 3

var selected_character_id: String = ""
var selected_game_mode: GameMode = GameMode.OVERWORLD
var pending_stage_path: String = STAGE1_PATH
## When true, stage1 keeps the practice fence active and skips the duel loop.
var practice_tutorial_mode: bool = false
## Overworld scenario loaded on stage entry. Empty string uses the normal town setup.
var overworld_scenario_id: String = "bandit_standoff"
