extends Node

func c4_bot_too_slow(game_data: C4GameData):
	await get_tree().create_timer(3).timeout
	return [2, "Decisions are hard"]
