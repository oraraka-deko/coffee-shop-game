class_name Cup extends Item

var VOLUME_CAP = 250

var volume = 0
var ingredients = {} # Ingredient ID to volume

# EVENTS

signal updated
signal overflow

func _on_updated() -> void:
	print(get_desc())
	
	var similarities = get_top_similarities()
	
	for drink_id in similarities:
		print(str(similarities[drink_id]) + '% ' + Global.DRINKS[drink_id]['name'])

func _on_overflow() -> void:
	print('Overflow!')
	kill()

# HELPERS

func get_similarity(drink_id) -> float:
	if not Global.DRINKS.has(drink_id):
		return -1
	
	var drink:Dictionary = Global.DRINKS[drink_id]
	var recipe:Dictionary = drink['ingredients']
	
	var similarity = 0
	
	for ingr_id in recipe:
		if not ingr_id in ingredients:
			continue
		
		var ing_percent = ingredients[ingr_id] / volume * 100
		var ing_percent_goal = recipe[ingr_id]
		
		similarity += 100 - abs(ing_percent - ing_percent_goal)
	
	similarity /= recipe.size()
	
	return round(similarity)

func get_similarities() -> Dictionary:
	'''Returns a dict of type Drink ID to Similarity % as float'''
	var similarities = {}
	
	for drink_id in Global.DRINKS:
		similarities[drink_id] = get_similarity(drink_id)
	
	return similarities

func get_top_similarities(how_many: int = 3, min_value = 0) -> Dictionary:
	'''Returns a sorted dict from get_similarities clipped by min value'''
	# I know its horrible
	var similarities = get_similarities()
	var out = {}
	
	min_value = clamp(min_value, 0, 100)
	
	for i in how_many:
		var biggest_value = -1
		var biggest_id = ''
		
		for drink_id in similarities:
			if( similarities[drink_id] <= biggest_value
				or similarities[drink_id] < min_value):
				continue
			
			biggest_value = similarities[drink_id]
			biggest_id = drink_id
		
		if biggest_value == -1:
			break
		
		out[biggest_id] = biggest_value
		similarities[biggest_id] = -1
	
	return out

func get_display_name() -> String:
	return "Coffee Cup"

func get_status_text() -> String:
	if volume <= 0:
		return "Empty (0 / %d ml)" % VOLUME_CAP
	
	var top = get_top_similarities(1)
	var recipe_str = ""
	if top.size() > 0:
		var best_id = top.keys()[0]
		var match_pct = top[best_id]
		if match_pct > 0:
			var drink_name = best_id.capitalize()
			if is_inside_tree() and get_node_or_null("/root/Global"):
				var g = get_node("/root/Global")
				if g.DRINKS.has(best_id):
					drink_name = g.DRINKS[best_id]['name']
			recipe_str = " • %d%% %s" % [match_pct, drink_name]
	
	return "%d / %d ml%s" % [round(volume), VOLUME_CAP, recipe_str]

func get_desc() -> String:
	var out = ''
	
	for ingr_id in ingredients:
		out += ' - ' + str(ingredients[ingr_id]) + ' ml ' + ingr_id + '\n'
	
	out += '   ' + str(volume) + '/' + str(VOLUME_CAP) + '\n'
	
	return out

# ACTIONS

func add_ingredient_data(id:String, ingr_volume:float):
	if not id in ingredients:
		ingredients[id] = 0
	
	ingredients[id] += ingr_volume
	volume += ingr_volume
	
	print('\nAdded ' + id + ', ' + str(ingr_volume) + ' ml')
	
	if volume > VOLUME_CAP:
		overflow.emit()
	
	updated.emit()

func add_ingredient(ingr):
	if not ingr is Ingredient:
		return
	
	add_ingredient_data(ingr.id, ingr.volume)
	
	ingr.kill()

# DETECTION

func _on_detector_body_entered(body: Node3D):
	add_ingredient(body)
