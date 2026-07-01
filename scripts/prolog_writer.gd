extends RefCounted

var _pl: Prologot

const FactsWriter := preload('res://scripts/facts_writer.gd')

func _init(pl: Prologot):
	_pl = pl

func term(functor: String, ...args):
	var clause := functor + '(' + ', '.join(args.map(FactsWriter.conv_term)) + ')'
	_pl.add_fact(clause)
