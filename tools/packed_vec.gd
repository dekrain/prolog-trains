@tool extends EditorScript

func _run():
	var packed_vec2: PackedVector2Array = [Vector2(12.34, 56.78), Vector2(22, 44), Vector2(33, 99)]
	var packed_vec3: PackedVector3Array = [Vector3(12.34, 56.78, 90.01), Vector3(22, 33, 44), Vector3(33, 66, 99)]
	var packed_vec4: PackedVector4Array = [Vector4(1.2, 3.4, 5.6, 7.8), Vector4(11, 22, 33, 44), Vector4(55, 66, 77, 88)]
	print(', '.join(packed_vec2 as Array))
	print(packed_vec2.to_byte_array().to_float32_array())
	print(', '.join(packed_vec3 as Array))
	print(packed_vec3.to_byte_array().to_float32_array())
	print(', '.join(packed_vec4 as Array))
	print(packed_vec4.to_byte_array().to_float32_array())
	print(packed_vec4.to_byte_array().to_vector2_array())
