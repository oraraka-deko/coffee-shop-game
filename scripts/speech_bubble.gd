class_name SpeechBubble3D extends Node3D

@onready var sprite: Sprite3D = $Sprite3D
@onready var viewport: SubViewport = $SubViewport
@onready var card_panel: PanelContainer = $SubViewport/BubbleCard
@onready var title_label: Label = $SubViewport/BubbleCard/Margin/VBox/Header/TitleLabel
@onready var icon_label: Label = $SubViewport/BubbleCard/Margin/VBox/Header/IconLabel
@onready var recipe_label: Label = $SubViewport/BubbleCard/Margin/VBox/RecipeLabel
@onready var patience_bar: ProgressBar = $SubViewport/BubbleCard/Margin/VBox/PatienceBar
@onready var reaction_label: Label = $SubViewport/BubbleCard/Margin/VBox/ReactionLabel

var is_active: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	# Ensure SubViewport is transparent and updates texture
	viewport.transparent_bg = true
	card_panel.modulate.a = 0.0
	reaction_label.visible = false
	_setup_bubble_style()

func _setup_bubble_style() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.97, 0.95, 0.96)
	style.border_color = Color(0.18, 0.14, 0.12, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 5
	card_panel.add_theme_stylebox_override("panel", style)

func _process(delta: float) -> void:
	if not is_active:
		return

	pulse_time += delta * 6.0
	# Urgent pulse when patience is critical (< 30%)
	if patience_bar.value < 30.0:
		var s = 1.0 + sin(pulse_time) * 0.03
		card_panel.scale = Vector2(s, s)
	else:
		card_panel.scale = Vector2.ONE

func show_order(drink_name: String, drink_id: String, recipe_dict: Dictionary, max_time: float) -> void:
	is_active = true
	reaction_label.visible = false
	title_label.visible = true
	recipe_label.visible = true
	patience_bar.visible = true

	# Set Icon
	var icon = "☕"
	var lower = drink_name.to_lower()
	if lower.contains("latte") or lower.contains("milk"):
		icon = "🥛"
	elif lower.contains("caramel") or lower.contains("vanilla") or lower.contains("syrup"):
		icon = "🍯"
	elif lower.contains("cappuccino"):
		icon = "☕"
	elif lower.contains("espresso"):
		icon = "⚡"
	icon_label.text = icon
	title_label.text = drink_name

	# Format recipe hint string
	var hints: Array[String] = []
	for ing_id in recipe_dict:
		var pct = round(recipe_dict[ing_id])
		var ing_name = ing_id.capitalize()
		hints.append("%s %d%%" % [ing_name, pct])
	recipe_label.text = " • ".join(hints)

	# Patience bar init
	patience_bar.max_value = 100.0
	patience_bar.value = 100.0
	_update_bar_color(100.0)

	# Smooth fade-in
	var tween = create_tween()
	tween.tween_property(card_panel, "modulate:a", 1.0, 0.25)

func update_patience(current_patience: float, max_patience: float) -> void:
	if max_patience <= 0:
		return
	var pct = clamp((current_patience / max_patience) * 100.0, 0.0, 100.0)
	patience_bar.value = pct
	_update_bar_color(pct)

func _update_bar_color(pct: float) -> void:
	var color: Color
	if pct > 60.0:
		color = Color(0.22, 0.82, 0.38) # Green
	elif pct > 30.0:
		color = Color(0.95, 0.72, 0.18) # Yellow
	else:
		color = Color(0.92, 0.25, 0.25) # Urgent Red

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.set_corner_radius_all(6)
	patience_bar.add_theme_stylebox_override("fill", fill_style)

func show_reaction(text: String, is_happy: bool, amount_text: String = "") -> void:
	reaction_label.visible = true
	recipe_label.visible = false
	patience_bar.visible = false

	if is_happy:
		reaction_label.text = "🎉 " + text + ("\n" + amount_text if amount_text != "" else "")
		reaction_label.modulate = Color(0.12, 0.65, 0.25)
	else:
		reaction_label.text = "😠 " + text
		reaction_label.modulate = Color(0.85, 0.18, 0.18)

	var tween = create_tween()
	tween.tween_property(card_panel, "scale", Vector2(1.1, 1.1), 0.15)
	tween.tween_property(card_panel, "scale", Vector2(1.0, 1.0), 0.15)

func show_booster_reaction(text: String = "Mmm, tasty treat! (+Patience)") -> void:
	var prev_recipe = recipe_label.text
	recipe_label.text = "❤️ " + text
	recipe_label.modulate = Color(0.92, 0.32, 0.45)
	
	var tween = create_tween()
	tween.tween_property(card_panel, "scale", Vector2(1.12, 1.12), 0.15)
	tween.tween_property(card_panel, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_interval(2.0)
	tween.tween_callback(func():
		recipe_label.text = prev_recipe
		recipe_label.modulate = Color(0.35, 0.3, 0.28)
	)

func hide_bubble() -> void:
	is_active = false
	var tween = create_tween()
	tween.tween_property(card_panel, "modulate:a", 0.0, 0.25)

