extends RefCounted

var _stream: FileAccess

func open(path: String):
	_stream = FileAccess.open(path, FileAccess.WRITE)

func blank_line():
	_stream.store_line("")

func term(functor: String, ...args):
	var clause := functor + '(' + ', '.join(args.map(conv_term)) + ').'
	_stream.store_line(clause)

func comment(comment: String):
	if comment.contains('\n'):
		_stream.store_line('/* ' + comment + ' */')
	else:
		_stream.store_line('% ' + comment)

func directive(dir: String):
	_stream.store_line(':- ' + dir + '.')

static func conv_term(term: Variant) -> String:
	if term is String or term is StringName:
		if not term.is_empty() and is_lower(term.unicode_at(0)) and all_unicode(term, is_atom_char):
			return term
		return "'" + term.c_escape() + "'"
	if term is int:
		return String.num_int64(term)
	if term is float:
		return String.num(term, 3)
	if term is Array:
		return '[' + ', '.join(term.map(conv_term)) + ']'
	if term is PackedInt32Array or term is PackedInt64Array or term is PackedFloat32Array or term is PackedFloat64Array or term is PackedByteArray:
		return '[' + ', '.join(packed_array_to_strings(term)) + ']'
	if term is PackedVector2Array or term is PackedVector3Array or term is PackedVector4Array:
		return '[' + ', '.join(packed_array_to_strings(term.to_byte_array().to_float32_array())) + ']'
	if term is PackedStringArray:
		return '[' + ', '.join(sanitize_packed_strings(term)) + ']'
	if term is Dictionary:
		if 'functor' in term:
			return conv_term(term['functor']) + '(' + ', '.join(term['args'].map(conv_term)) + ')'
	push_error('Invalid converted variant: '+type_string(typeof(term)))
	return '???'

static func packed_array_to_strings(array: Variant) -> PackedStringArray:
	if array is PackedInt32Array or array is PackedInt64Array or array is PackedByteArray:
		return PackedStringArray(Array(array).map(str))
	if array is PackedFloat32Array or array is PackedFloat64Array:
		return PackedStringArray(Array(array).map(func(n): return String.num(n, 3)))
	push_error('Invalid packed array: '+type_string(typeof(array)))
	return []

static func sanitize_packed_strings(array: PackedStringArray) -> PackedStringArray:
	var result := array
	for idx in range(array.size()):
		var str := array[idx]
		if not str.is_empty() and is_lower(str.unicode_at(0)) and all_unicode(str, is_atom_char):
			continue
		# Duplicate the array on demand
		if is_same(result, array):
			result = array.duplicate()
		result[idx] = "'" + str.c_escape() + "'"
	return result

static func all_unicode(str: String, pred: Callable) -> bool:
	for idx in range(str.length()):
		if not pred.call(str.unicode_at(idx)):
			return false
	return true

static func is_lower(code: int) -> bool:
	return code >= 0x61 and code <= 0x7A

static func is_atom_char(code: int) -> bool:
	code |= 0x20
	return code >= 0x61 and code <= 0x7A
