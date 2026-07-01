@tool extends EditorScript

func _run():
	print(conv_term(123))
	print(conv_term('asdf'))
	print(conv_term('Asgf'))

static func conv_term(term: Variant) -> String:
	if term is String:
		if not term.is_empty() and is_lower(term[0]) and term.split('').all(is_atom_char):
			return term
		return "'" + term.c_escape() + "'"
	return '???'

static func is_lower(ch: String) -> bool:
	var code := ch.unicode_at(0)
	return code >= 0x61 and code <= 0x7A

static func is_atom_char(ch: String) -> bool:
	var code := ch.unicode_at(0) | 0x20
	return code >= 0x61 and code <= 0x7A
