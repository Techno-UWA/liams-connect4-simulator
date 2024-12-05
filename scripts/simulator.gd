extends Node2D

const INF = 1e20  # A large number to represent infinity

var response_received := false
var times_up := false
var player_timer: SceneTreeTimer
signal turn_completed
signal game_state_changed

# Import bot scripts
const C4BotRandom = preload("res://scripts/bots/c4_bot_random.gd")
const C4BotBadResponse = preload("res://scripts/bots/c4_bot_bad_response.gd")
const C4BotInvalidColumn = preload("res://scripts/bots/c4_bot_invalid_column.gd")
const C4BotBadMessage = preload("res://scripts/bots/c4_bot_bad_message.gd")
const C4BotTooSlow = preload("res://scripts/bots/c4_bot_too_slow.gd")
const C4BotSlow = preload("res://scripts/bots/c4_bot_slow.gd")
const C4BotAlphaBeta = preload("res://scripts/bots/c4_bot_alpha_beta.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()  # Initialize the random number generator
	var bot_function_1 = Callable(C4BotAlphaBeta, "c4_bot_alpha_beta")  # Alpha-beta bot
	var bot_function_2 = Callable(C4BotRandom, "c4_bot_random")      # Random bot
	play_full_game(bot_function_1, bot_function_2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func test_bot(bot_function: Callable, your_bot_name: String): #Simulates calling the bot after the other player has taken a turn.
	print('_______________________________')
	print('Testing Bot "%s"'%your_bot_name)
	times_up = false
	response_received = false
	turn_completed.connect(_process_turn_results)
	var empty_grid:Array[int] = []
	empty_grid.resize(7*6)
	empty_grid.fill(0)
	var grid_state: Array[int] = empty_grid.duplicate()
	grid_state[38] = 1

	var player_names = [your_bot_name]
	var game_data_first_turn = C4GameData.new(player_names, grid_state, null)
	var first_turn = C4Turn.new(0, 38, "Let's Go!", game_data_first_turn)
	var game_data = C4GameData.new(player_names, grid_state, first_turn)

	player_timer = get_tree().create_timer(game_data.my_remaining_time_ms / 1000)
	player_timer.timeout.connect(_turn_time_exceeded)
	_get_bots_response(bot_function, game_data)

func _get_bots_response(bot_function, game_data: C4GameData):
	var turn_start_time = Time.get_ticks_msec()
	var response = await bot_function.call(game_data)
	var response_time_ms = Time.get_ticks_msec() - turn_start_time
	turn_completed.emit(false, response, response_time_ms)

func _turn_time_exceeded():
	turn_completed.emit(true, 'Times Up', 2000)

func _process_turn_results(timer_finish, response, response_time_ms):
	if timer_finish and not response_received:
		times_up = true
		print('You ran out of time, your turn would be skipped')

	elif not timer_finish and not times_up:
		response_received = true
		print('You gave us:')
		print(response)
		print('It took %sms'%response_time_ms)

		if not response is Array:
			print('You need to give back an array')
			print('The game will skip your turn')
			return false

		if not response[0] is int:
			print('The first element in your response array must be an integer')
			print('The game will skip your turn')
			return false

		if not (response[0] >= 0 and response[0] < 7):
			print('The first element in your response array should be between 0 and 6 inclusive')
			print('The game will skip your turn')
			return false

		var selected_column = response[0] + 1

		if not response[1] is String:
			print('The second element in your response array should be a string')
			print('The game will keep your selection of column %s and leave your chat message blank'%selected_column)
			return true


		print('Your bot successfully selected column %s and said "%s"'%[selected_column, response[1]])
		return true

func play_full_game(bot_function_1: Callable, bot_function_2: Callable):
	var empty_grid: Array[int] = []
	empty_grid.resize(7 * 6)
	empty_grid.fill(0)
	var grid_state: Array[int] = empty_grid.duplicate()
	var active_player = 0
	var bot_functions = [bot_function_1, bot_function_2]
	var player_names = ["Player 1", "Player 2"]

	var game_data = C4GameData.new(player_names, grid_state, null)
	print_board(grid_state)  # Print initial empty board
	
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

				print("Player %d (%s) selects column %d and says: \"%s\"" %
					[active_player + 1, player_names[active_player], selected_column + 1, message])
				print_board(grid_state)  # Print board after each move

				if check_win_condition(grid_state, active_player + 1):
					print("Player %d (%s) wins!" % [active_player + 1, player_names[active_player]])
					break

				if check_draw_condition(grid_state):
					print("The game is a draw!")
					break

				active_player = 1 - active_player
			else:
				print("Column %d is full. Player %d (%s) loses." %
					[selected_column + 1, active_player + 1, player_names[active_player]])
				break
		else:
			print("Player %d (%s) did not return a valid move." % [active_player + 1, player_names[active_player]])
			break

func check_win_condition(grid_state: Array[int], player_token: int) -> bool:
	var directions = [
		Vector2(1, 0),  # Horizontal
		Vector2(0, 1),  # Vertical
		Vector2(1, 1),  # Diagonal /
		Vector2(1, -1)  # Diagonal \
	]

	for y in range(6):
		for x in range(7):
			if grid_state[y * 7 + x] == player_token:
				for direction in directions:
					var count = 1
					for i in range(1, 4):
						var new_x = x + direction.x * i
						var new_y = y + direction.y * i
						if new_x >= 0 and new_x < 7 and new_y >= 0 and new_y < 6:
							if grid_state[int(new_y) * 7 + int(new_x)] == player_token:
								count += 1
							else:
								break
						else:
							break
					if count == 4:
						return true
	return false

func check_draw_condition(grid_state: Array[int]) -> bool:
	for slot in grid_state:
		if slot == 0:
			return false
	return true

func _get_next_available_row(grid_state: Array[int], column: int) -> int:
	# Start from bottom (row 0) and go up
	for row in range(5, -1, -1):
		if grid_state[row * 7 + column] == 0:
			return row
	return -1

class C4Turn:
	var number: int #First player's first turn is 1, 2nd player's first turn is 2 etc.
	var player_index: int #0 = first player, 1 = second player
	var selection:int #The selected grid slot => -1 if an invalid slot was selected, -2 if they ran out of time otherwise 0 to 41(in normal 6x7 grid)
	var message:String #The message given by the player, empty string if no response
	var game_data:C4GameData #the data given to the player as part of their turn
	var time_used_ms: int #the thinking time used by the turn

	func _init(player_index: int, selected_column: int, chat_message: String, game_data: C4GameData):
		player = player_index
		selection = selected_column
		message = chat_message
		provided_data = game_data.duplicate()

	# Add this duplicate method
	func duplicate():
		var new_turn = C4Turn.new(player, selection, message, provided_data.duplicate())
		return new_turn

class C4GameData:
	var columns:int #The number of columns of the grid
	var rows: int #The number of rows of the grid
	var required_connections: int #The number of connected tokens required to win (normally 4)
	var allowed_time_ms: int #The total allowed thinking time for each player
	
	var grid:Array[int] #Current game grid 0 = Empty, 1 = Player 1 token, 2 = Player 2 token. 0 is top left slot, goes left-right, top-bottom
	var game_history: Array[C4Turn] #Array holding all the previous turns
	var my_remaining_time_s:float #Your total remaining thinking time in s
	var my_player_index:int #0 if first player, 1 if second player
	var my_opponent_name: String #Your opponent's display name
	var my_name: String #Your display name
	var my_remaining_time_ms: int #Your total remaining thinking time in ms

	var my_grid: Array[int] #Current game grid but changed to 0= empty, 1= your token, 2= your opponents tokken
	var my_color:Color #Colour of your tokens
	var my_opponent_color:Color #Colour of your opponents tokens

	func _init(player_names: Array, grid_state: Array, first_turn):
		self.player_names = player_names
		self.grid = grid_state.duplicate()
		self.my_grid = []
		self.game_history = []
		if first_turn != null:
			self.game_history.append(first_turn)

	# Add this duplicate method
	func duplicate():
		var new_instance = C4GameData.new(player_names.duplicate(), grid.duplicate(), null)
		new_instance.columns = columns
		new_instance.rows = rows
		new_instance.required_connections = required_connections
		new_instance.allowed_time_ms = allowed_time_ms
		new_instance.my_player_index = my_player_index
		new_instance.my_remaining_time_ms = my_remaining_time_ms
		new_instance.my_grid = my_grid.duplicate()
		new_instance.game_history = []
		for turn in game_history:
			new_instance.game_history.append(turn.duplicate())
		return new_instance

	static func _change_slot_state_perspective(grid_state:Array[int], player_index:int):
		var grid:Array[int] = []
		for slot in grid_state:
			if player_index==0 or slot == 0:
				grid.append(slot)
			elif slot==1:
				grid.append(2)
			else:
				grid.append(1)
		return grid

func print_board(grid_state: Array) -> void:
	print("\n Current Board State:")
	print("--------------------")
	for row in range(5, -1, -1):  # Print from top to bottom
		var row_str = "|"
		for col in range(7):
			var cell = grid_state[row * 7 + col]
			var symbol = " "
			if cell == 1:
				symbol = "X"  # Player 1
			elif cell == 2:
				symbol = "O"  # Player 2
			row_str += " " + symbol + " |"
		print(row_str)
	print("--------------------")
	print("  1   2   3   4   5   6   7")  # Aligned column numbers
	print()
