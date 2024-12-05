extends Node

const INF = 1e20  # A large number to represent infinity

func c4_bot_alpha_beta(game_data: C4Data.C4GameData):
	var depth = 5  # Adjust the depth for difficulty
	var player = game_data.my_player_index + 1  # Player token (1 or 2)

	var valid_columns = []
	for col in range(game_data.columns):
		if _get_next_available_row(game_data.grid, col) != -1:
			valid_columns.append(col)
	if valid_columns.size() == 0:
		return null  # No valid moves

	var result = _alpha_beta_search(game_data.grid, depth, -INF, INF, true, player)
	var score = result[0]
	var column = result[1]

	if column == null:
		column = valid_columns[0]  # Fallback if no column was selected

	var message = 'Alpha-Beta chooses: Column %s' % (column + 1)
	return [column, message]

func _alpha_beta_search(grid, depth, alpha, beta, maximizing_player, player):
	var valid_columns = []
	for col in range(7):
		if _get_next_available_row(grid, col) != -1:
			valid_columns.append(col)
	var is_terminal = _is_terminal_node(grid)

	if depth == 0 or is_terminal:
		if is_terminal:
			if _winning_move(grid, player):
				return [100000000000000, null]
			elif _winning_move(grid, 3 - player):
				return [-100000000000000, null]
			else:
				return [0, null]
		else:
			return [_score_position(grid, player), null]

	if maximizing_player:
		var value = -INF
		var column = null
		for col in valid_columns:
			var row = _get_next_available_row(grid, col)
			var temp_grid = grid.duplicate()
			temp_grid[row * 7 + col] = player
			var new_score = _alpha_beta_search(temp_grid, depth - 1, alpha, beta, false, player)[0]
			if new_score > value:
				value = new_score
				column = col
			alpha = max(alpha, value)
			if alpha >= beta:
				break
		return [value, column]
	else:
		var value = INF
		var column = null
		for col in valid_columns:
			var row = _get_next_available_row(grid, col)
			var temp_grid = grid.duplicate()
			temp_grid[row * 7 + col] = 3 - player  # Opponent's token
			var new_score = _alpha_beta_search(temp_grid, depth - 1, alpha, beta, true, player)[0]
			if new_score < value:
				value = new_score
				column = col
			beta = min(beta, value)
			if alpha >= beta:
				break
		return [value, column]

func _is_terminal_node(grid) -> bool:
	return _winning_move(grid, 1) or _winning_move(grid, 2) or _get_valid_locations(grid).size() == 0

func _get_valid_locations(grid) -> Array:
	var valid_locations = []
	for col in range(7):
		if _get_next_available_row(grid, col) != -1:
			valid_locations.append(col)
	return valid_locations

func _winning_move(grid, piece) -> bool:
	# Check horizontal locations
	for r in range(6):
		for c in range(4):
			if grid[r * 7 + c] == piece and grid[r * 7 + c + 1] == piece and grid[r * 7 + c + 2] == piece and grid[r * 7 + c + 3] == piece:
				return true
	# Check vertical locations
	for c in range(7):
		for r in range(3):
			if grid[r * 7 + c] == piece and grid[(r + 1) * 7 + c] == piece and grid[(r + 2) * 7 + c] == piece and grid[(r + 3) * 7 + c] == piece:
				return true
	# Check positively sloped diagonals
	for r in range(3):
		for c in range(4):
			if grid[r * 7 + c] == piece and grid[(r + 1) * 7 + c + 1] == piece and grid[(r + 2) * 7 + c + 2] == piece and grid[(r + 3) * 7 + c + 3] == piece:
				return true
	# Check negatively sloped diagonals
	for r in range(3, 6):
		for c in range(4):
			if grid[r * 7 + c] == piece and grid[(r - 1) * 7 + c + 1] == piece and grid[(r - 2) * 7 + c + 2] == piece and grid[(r - 3) * 7 + c + 3] == piece:
				return true
	return false

func _score_position(grid, piece) -> int:
	var score = 0
	# Center column preference
	var center_array = []
	for r in range(6):
		center_array.append(grid[r * 7 + 3])
	var center_count = center_array.count(piece)
	score += center_count * 3

	# Horizontal scoring
	for r in range(6):
		var row_array = []
		for c in range(7):
			row_array.append(grid[r * 7 + c])
		for c in range(4):
			var window = row_array.slice(c, c + 4)
			score += _evaluate_window(window, piece)
	# Vertical scoring
	for c in range(7):
		var col_array = []
		for r in range(6):
			col_array.append(grid[r * 7 + c])
		for r in range(3):
			var window = col_array.slice(r, r + 4)
			score += _evaluate_window(window, piece)
	# Positive sloped diagonal scoring
	for r in range(3):
		for c in range(4):
			var window = []
			for i in range(4):
				window.append(grid[(r + i) * 7 + c + i])
			score += _evaluate_window(window, piece)
	# Negative sloped diagonal scoring
	for r in range(3, 6):
		for c in range(4):
			var window = []
			for i in range(4):
				window.append(grid[(r - i) * 7 + c + i])
			score += _evaluate_window(window, piece)
	return score

func _evaluate_window(window: Array, piece) -> int:
	var score = 0
	var opp_piece = 3 - piece

	var count_piece = window.count(piece)
	var count_opp = window.count(opp_piece)
	var count_empty = window.count(0)

	if count_piece == 4:
		score += 100
	elif count_piece == 3 and count_empty == 1:
		score += 5
	elif count_piece == 2 and count_empty == 2:
		score += 2

	if count_opp == 3 and count_empty == 1:
		score -= 4
	return score

func _get_next_available_row(grid_state: Array[int], column: int) -> int:
	# Start from bottom (row 0) and go up
	for row in range(5, -1, -1):
		if grid_state[row * 7 + column] == 0:
			return row
	return -1
