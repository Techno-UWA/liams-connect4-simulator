extends Node2D

var response_received := false
var times_up := false
var player_timer: SceneTreeTimer
signal turn_completed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var bot_function = Callable(self, "c4_bot_random")
	test_bot(bot_function, "Tester")
	pass # Replace with function body.


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
	
	var game_data_first_turn = C4GameData.new(your_bot_name, grid_state, null)
	var first_turn = C4Turn.new(0, 38, "Let's Go!", game_data_first_turn)
	var game_data = C4GameData.new(your_bot_name, grid_state, first_turn)

	player_timer = get_tree().create_timer(game_data.my_remaining_time_ms / 1000)
	player_timer.timeout.connect(_turn_time_exceeded)
	_get_bots_response(bot_function, game_data)
	
	
	
func _get_bots_response(bot_function, game_data:C4GameData):
	var turn_start_time = Time.get_ticks_msec()
	var response = await bot_function.call(game_data)
	var response_time_ms = Time.get_ticks_msec() - turn_start_time
	turn_completed.emit(false, response, response_time_ms)

func _turn_time_exceeded():
	turn_completed.emit(true,'Times Up',2000)

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
		
		
		print('Your bot sucessfully selected column %s and said "%s"'%[selected_column, response[1]])
		return true

class C4Turn:
	func _init(player_index, selected_slot:int, chat_message: String, game_data: C4GameData):
		var player: int = player_index
		var selection:int = selected_slot #-1 if turn was skipped
		var message:String = chat_message #Empty string if no or invalid message
		var provided_data:C4GameData = game_data.duplicate()

class C4GameData:
	#The actual class constructor sets these from the tournament UI.
	var player_names:Array[String] = ['Player 1']
	var columns:int = 7
	var rows: int = 6
	var required_connections: int = 4
	var allowed_time_ms:int = 10000
	
	var my_player_index:int = 1 #0 if first, 1 if second player
	var my_remaining_time_ms: int = 2000
	var grid:Array[int]
	var my_grid: Array[int] #grid changed to 0 empty, 1 your token, 2 your opponents token
	var game_history: Array[C4Turn]
	
		
	func _init(bot_name, grid_state, first_turn):
		player_names.append(bot_name)
		grid = grid_state
		my_grid = _change_slot_state_perspective(grid_state, my_player_index)
		game_history = [first_turn]
		
	
	func duplicate():
		#This is a hack for the benefits of this test code
		return C4GameData.new(player_names[1], grid, game_history[0])

	func _change_slot_state_perspective(grid_state:Array[int], player_index:int):
		var grid:Array[int] = []
		for slot in grid_state:
			if player_index==0 or slot == 0:
				grid.append(slot)
			elif slot==1:
				grid.append(2)
			else:
				grid.append(1)
		return grid


# Test Bots
func c4_bot_random(game_data:C4GameData):
	var slot_picked = randi_range(0, game_data.columns - 1)
	var message = 'Randy picks: Column %s'%(slot_picked + 1)
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
