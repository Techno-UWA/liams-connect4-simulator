extends Node

class_name C4Data

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
    var game_history: Array[C4Turn]

    func _init(player_names: Array, grid_state: Array, first_turn):
        self.player_names = player_names
        self.grid = grid_state.duplicate()
        self.my_grid = []
        self.game_history = []
        if first_turn != null:
            self.game_history.append(first_turn)

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

    static func _change_slot_state_perspective(grid_state: Array[int], player_index: int) -> Array[int]:
        var grid: Array[int] = []
        for slot in grid_state:
            if player_index == 0 or slot == 0:
                grid.append(slot)
            elif slot == 1:
                grid.append(2)
            else:
                grid.append(1)
        return grid