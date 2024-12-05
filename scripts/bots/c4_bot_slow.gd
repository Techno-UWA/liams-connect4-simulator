extends Node

func c4_bot_slow(game_data: C4GameData):
	await get_tree().create_timer(1).timeout
	return [2, "Sorry it took so long"]
