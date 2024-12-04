extends Node2D

signal game_state_changed

var grid_size = Vector2(7, 6)
var cell_size = Vector2(64, 64)
var tokens = []

func _ready():
    _create_grid()
    connect("game_state_changed", self, "_on_game_state_changed")

func _create_grid():
    for y in range(grid_size.y):
        var row = []
        for x in range(grid_size.x):
            var token = TextureRect.new()
            token.rect_min_size = cell_size
            token.rect_position = Vector2(x, y) * cell_size
            add_child(token)
            row.append(token)
        tokens.append(row)

func _on_game_state_changed(grid_state):
    for y in range(grid_size.y):
        for x in range(grid_size.x):
            var token = tokens[y][x]
            var state = grid_state[y * grid_size.x + x]
            if state == 0:
                token.texture = null
            elif state == 1:
                token.texture = preload("res://assets/red_token.png")
            elif state == 2:
                token.texture = preload("res://assets/yellow_token.png")
