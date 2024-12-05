extends Node2D

signal game_state_changed

func _ready():
	randomize()  # Initialize random number generator
	var bot_function_1 = Callable(self, "c4_bot_random")
	var bot_function_2 = Callable(self, "c4_bot_random")
	play_full_game(bot_function_1, bot_function_2)

func play_full_game(bot_function_1: Callable, bot_function_2: Callable):
	var empty_grid: Array[int] = []
	empty_grid.resize(7 * 6)
	empty_grid.fill(0)
	var grid_state: Array[int] = empty_grid.duplicate()
	var active_player = 0
	var bot_functions = [bot_function_1, bot_function_2]
	var player_names = ["Bot 1", "Bot 2"]

	var game_data = C4GameData.new(player_names, grid_state)
	while true:
		var bot_function = bot_functions[active_player]
		game_data.my_player_index = active_player
		game_data.my_grid = C4GameData._change_slot_state_perspective(grid_state, active_player)
		var turn_result = bot_function.call(game_data)
		if turn_result:
			var selected_column = turn_result[0]
			var message = turn_result[1]
			var row = _get_next_available_row(grid_state, selected_column)
			if row != -1:
				grid_state[row * 7 + selected_column] = active_player + 1
				game_data.grid = grid_state.duplicate()
				game_data.game_history.append(C4Turn.new(active_player, selected_column, message, game_data))
				emit_signal("game_state_changed", grid_state)

				if check_win_condition(grid_state, active_player + 1):
					print("Player %d (%s) wins!" % [active_player + 1, player_names[active_player]])
					break

				if check_draw_condition(grid_state):
					print("The game is a draw!")
					break

				active_player = 1 - active_player
			else:
				print("Column %d is full. Player %d (%s) loses." % [selected_column + 1, active_player + 1, player_names[active_player]])
				break
		else:
			print("Player %d (%s) did not return a valid move." % [active_player + 1, player_names[active_player]])
			break

func _get_next_available_row(grid_state: Array[int], column: int) -> int:
	for row in range(5, -1, -1):
		if grid_state[row * 7 + column] == 0:
			return row
	return -1

func check_win_condition(grid_state: Array[int], player_token: int) -> bool:
	var directions = [
		Vector2.RIGHT,        # Horizontal
		Vector2.DOWN,         # Vertical
		Vector2(1, 1),        # Diagonal /
		Vector2(1, -1)        # Diagonal \
	]

	for y in range(6):
		for x in range(7):
			if grid_state[y * 7 + x] == player_token:
				for direction in directions:
					var count = 1
					for i in range(1, 4):
						var new_x = x + int(direction.x) * i
						var new_y = y + int(direction.y) * i
						if new_x >= 0 and new_x < 7 and new_y >= 0 and new_y < 6:
							if grid_state[new_y * 7 + new_x] == player_token:
								count += 1
							else:
								break
						else:
							break
					if count >= 4:
						return true
	return false

func check_draw_condition(grid_state: Array[int]) -> bool:
	for slot in grid_state:
		if slot == 0:
			return false
	return true

class C4GameData:
	var player_names: Array[String]
	var columns: int = 7
	var rows: int = 6
	var required_connections: int = 4
	var allowed_time_ms: int = 10000

	var my_player_index: int
	var my_remaining_time_ms: int = 2000
	var grid: Array[int]
	var my_grid: Array[int]
	var game_history: Array[C4Turn] = []

	func _init(player_names: Array[String], grid_state: Array[int]):
		self.player_names = player_names
		self.grid = grid_state.duplicate()
		self.my_grid = []
		self.my_player_index = 0

	static func _change_slot_state_perspective(grid_state: Array[int], player_index: int) -> Array[int]:
		var grid: Array[int] = []
		for slot in grid_state:
			if slot == 0:
				grid.append(0)
			elif slot == player_index + 1:
				grid.append(1)
			else:
				grid.append(2)
		return grid

class C4Turn:
	var player: int
	var selection: int
	var message: String
	var provided_data: C4GameData

	func _init(player_index: int, selected_column: int, chat_message: String, game_data: C4GameData):
		player = player_index
		selection = selected_column
		message = chat_message
		provided_data = game_data.duplicate()

	func duplicate():
		var new_turn = C4Turn.new(player, selection, message, provided_data)
		return new_turn

func c4_bot_random(game_data: C4GameData):
	var valid_columns = []
	for col in range(game_data.columns):
		if _get_next_available_row(game_data.grid, col) != -1:
			valid_columns.append(col)
	if valid_columns.size() == 0:
		return null  # No valid moves
	var slot_picked = valid_columns[randi() % valid_columns.size()]
	var message = 'Random choice: Column %s' % (slot_picked + 1)
	return [slot_picked, message]

func c4_bot_bad_response(game_data:C4GameData):
	return 'No'

func c4_bot_invalid_column(game_data:C4GameData):
	return [-1, "Idk what I'm doing"]

func c4_bot_bad_message(game_data:C4GameData):
	return [3, 4]
	
func c4_bot_too_slow(game_data:C4GameData):
	await get_tree().create_timer(3).timeout
	return [2, "Decisions are hard"]

func c4_bot_slow(game_data:C4GameData):
	await get_tree().create_timer(1).timeout
	return [2, "Sorry it took so long"]
