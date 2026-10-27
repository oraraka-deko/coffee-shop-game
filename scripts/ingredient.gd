class_name Ingredient extends Item

@onready var id:String = get_meta('id') if has_meta('id') else "ingredient"
@onready var volume:float = get_meta('volume') if has_meta('volume') else 0.0

func get_display_name() -> String:
	var item_id = id
	match item_id:
		"milk":
			return "Milk Carton"
		"coffee":
			return "Coffee Canister"
		"caramel":
			return "Caramel Syrup"
		"vanilla":
			return "Vanilla Syrup"
		"sugar":
			return "Sugar Shaker"
		_:
			return item_id.capitalize()

func get_status_text() -> String:
	var current_vol = get_meta("volume") if has_meta("volume") else volume
	if current_vol > 0:
		return "%d ml" % round(current_vol)
	return "Empty"

