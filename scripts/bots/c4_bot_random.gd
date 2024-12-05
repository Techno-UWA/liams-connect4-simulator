extends Node

func c4_bot_random(game_data: C4GameData):
	var slot_picked = randi_range(0, game_data.columns - 1)
	var message = 'Randy picks: Column %s'%(slot_picked + 1)
	return [slot_picked, message]
