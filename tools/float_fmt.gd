@tool
extends EditorScript

func _run():
	print('%.5f' % [12.345678])
	print(String.num(12.345))
	print(String.num(12.345, 2))
	# Force float32 conversion
	var num := Vector2(12.34, 0).x
	print(num)
	print(Vector2(num, num))
	print(String.num(num, 6))
