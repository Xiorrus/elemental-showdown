# tactical_workbench_card.gd
# Interactive roster squad card for the battle deployment tab.
# Supports dragging to the 6x6 arena grid, dropping to bench, and selection.
extends PanelContainer

signal card_clicked(ally_name: String)
signal bench_dropped(ally_name: String)

var ally_name: String = ""

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(ally_name)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if ally_name == "":
		return null
	var preview_panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.16, 0.24, 0.95)
	sb.border_color = Color(1.2, 1.0, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	preview_panel.add_theme_stylebox_override("panel", sb)

	var preview_lbl = Label.new()
	preview_lbl.text = " %s " % ally_name.capitalize()
	preview_lbl.add_theme_font_override("font", load("res://assets/fonts/Cinzel-Bold.ttf"))
	preview_lbl.add_theme_font_size_override("font_size", 10)
	preview_lbl.modulate = Color(1.2, 1.0, 0.4)
	preview_panel.add_child(preview_lbl)

	set_drag_preview(preview_panel)
	return {
		"type": "squadmate",
		"name": ally_name,
		"from_roster": true
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (data is Dictionary) and data.get("type") == "squadmate" and data.has("from_tile")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if (data is Dictionary) and data.get("type") == "squadmate":
		bench_dropped.emit(str(data.get("name", "")))
