@icon('res://resources/map_object.dpitex')
@abstract
class_name MapObject extends Area2D

const STATE_HOVERED := 1
const STATE_SELECTED := 2
const STATE_HOVERED_REMOVE := 4
const STATE_HOVERED_ALL := 5
const ALL_STATES := 7

signal changed

var _state := 0

func _ready():
	input_pickable = true

func gen_name():
	while true:
		var nm := ''.join(range(6).map(func(i): return String.chr(randi_range(0x61, 0x7A))))
		name = nm
		if name == nm:
			break

func set_state(state: int, on: bool):
	if on:
		_state |= state
	else:
		_state &= ~state
	_apply_state()

@abstract
func save_to_db_all(writer)

@abstract
func load_from_db(pl: Prologot)

@abstract
func remove_from_db(pl: Prologot) -> bool

@abstract
func _apply_state()
