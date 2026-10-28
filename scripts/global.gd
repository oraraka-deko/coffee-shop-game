extends Node

var total_cash: float = 0.0
var orders_served_count: int = 0

signal cash_changed(new_amount: float, gained: float)
signal order_completed(total_count: int)

func add_cash(amount: float) -> void:
	total_cash += amount
	cash_changed.emit(total_cash, amount)

func record_order_served() -> void:
	orders_served_count += 1
	order_completed.emit(orders_served_count)

var DRINKS = {
	# Drink ID
	"ESPRESSO": {
		'name': 'Espresso',
		# Ingredient ID to volume %
		'ingredients': {
			'coffee': 100,
		}
	},
	"ESPRESSO_MACCHIATO": {
		'name': 'Espresso Macchiato',
		'ingredients': {
			'coffee': 75,
			'milk': 25,
		}
	},
	"FLAT_WHITE": {
		'name': 'Flat White',
		'ingredients': {
			'coffee': 33.3,
			'milk': 66.6,
		}
	},
	"CAPPUCCINO": {
		'name': 'Cappuccino',
		'ingredients': {
			'coffee': 20,
			'milk': 80,
		}
	},
	"LATTE": {
		'name': 'Latte',
		'ingredients': {
			'coffee': 14.3,
			'milk': 85.3,
		}
	},
	"CARAMEL_MACCHIATO": {
		'name': 'Caramel Macchiato',
		'ingredients': {
			'coffee': 30,
			'milk': 60,
			'caramel': 10,
		}
	},
	"VANILLA_LATTE": {
		'name': 'Vanilla Latte',
		'ingredients': {
			'coffee': 15,
			'milk': 75,
			'vanilla': 10,
		}
	},
	"SWEET_CAPPUCCINO": {
		'name': 'Sweet Cappuccino',
		'ingredients': {
			'coffee': 20,
			'milk': 75,
			'sugar': 5,
		}
	},
}
