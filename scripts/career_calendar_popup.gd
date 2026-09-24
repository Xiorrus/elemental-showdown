extends PopupPanel
class_name CareerCalendarPopup

signal state_changed(message: String)
signal play_requested
signal friendly_requested(match_data: Dictionary)

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

var campaign_manager: Node
var _scroll: ScrollContainer
var _rows: VBoxContainer
var _status: Label
var _detail: Label
var _feedback: Label
var _skip_button: Button
var _play_button: Button
var _day_nodes: Dictionary = {}
var _selected_day := 1
var _skip_armed := false

func open_for(manager: Node) -> void:
	campaign_manager = manager
	if _rows == null: _build()
	_selected_day = manager.get_season_day()
	_skip_armed = false
	_refresh()
	popup_centered(Vector2i(925, 495))
	call_deferred("_fit_popup")
	call_deferred("_scroll_to_day", _selected_day)

func _fit_popup() -> void:
	# PopupPanel may size itself from the scroll content on its first frame.
	# Once container minimums settle, constrain it to the viewport.
	var view_size: Vector2i = Vector2i(get_tree().root.get_visible_rect().size)
	size = Vector2i(mini(925, view_size.x - 24), mini(495, view_size.y - 24))
	position = (view_size - size) / 2

var cinzel_font: Font = null

func _get_cinzel() -> Font:
	if cinzel_font == null and ResourceLoader.exists("res://assets/fonts/Cinzel-Bold.ttf"):
		cinzel_font = load("res://assets/fonts/Cinzel-Bold.ttf")
	return cinzel_font

func _build() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.035, 0.05, 0.08, 0.99)
	panel.border_color = Color(0.82, 0.65, 0.24, 0.85)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 14)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "Career Calendar"
	if _get_cinzel():
		title.add_theme_font_override("font", _get_cinzel())
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", UITheme.GOLD_PRIMARY)
	layout.add_child(title)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 10)
	_status.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	layout.add_child(_status)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	layout.add_child(actions)
	_add_action(actions, "Today", func(): _select_day(campaign_manager.get_season_day()))
	_add_action(actions, "Jump to Match", _jump_to_match_day)
	_add_action(actions, "+1 Day", func(): _advance(1))
	_add_action(actions, "Rest 1d", func(): _rest(1))
	_add_action(actions, "Rest 3d", func(): _rest(3))
	_add_action(actions, "Rest 7d", func(): _rest(7))
	_skip_button = _add_action(actions, "Skip Match", _confirm_skip)
	_play_button = _add_action(actions, "Play Match", _play_selected, true)
	_add_action(actions, "Close", func(): hide())
	_detail = Label.new()
	_detail.custom_minimum_size = Vector2(0, 32)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 10)
	_detail.add_theme_color_override("font_color", Color(0.94, 0.9, 0.78))
	layout.add_child(_detail)
	_feedback = Label.new()
	_feedback.add_theme_font_size_override("font_size", 10)
	_feedback.add_theme_color_override("font_color", Color(0.55, 0.85, 0.96))
	layout.add_child(_feedback)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, 270)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(_scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 18)
	_scroll.add_child(_rows)

func _add_action(parent: HBoxContainer, label: String, callback: Callable, is_primary: bool = false) -> Button:
	var button := Button.new()
	button.text = label
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 10)
	if is_primary:
		button.add_theme_stylebox_override("normal", UITheme.make_btn_primary(false, false))
		button.add_theme_stylebox_override("hover", UITheme.make_btn_primary(true, false))
		button.add_theme_stylebox_override("pressed", UITheme.make_btn_primary(false, true))
		button.add_theme_color_override("font_color", UITheme.TEXT_DARK)
		button.add_theme_color_override("font_hover_color", Color(0.02, 0.04, 0.06))
	else:
		button.add_theme_stylebox_override("normal", UITheme.make_btn_secondary(false, false))
		button.add_theme_stylebox_override("hover", UITheme.make_btn_secondary(true, false))
		button.add_theme_stylebox_override("pressed", UITheme.make_btn_secondary(false, true))
		button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
		button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _entry_text(entry: Dictionary) -> String:
	var labels: Array[String] = []
	for event in entry.get("events", []):
		match str(event.get("type", "")):
			"club_match": labels.append("Club match vs %s (%s)" % [event.get("opponent", "Rival"), "played" if event.get("played", false) else "scheduled"])
			"championship_semifinals": labels.append("Club championship semifinal, if qualified")
			"championship_final": labels.append("Club championship final, if qualified")
			"national_window": labels.append("National team %s window" % str(event.get("competition", "friendly")).replace("_", " ").capitalize())
			"club_friendly": labels.append("Optional club friendly")
	if entry.get("transfer_window", false): labels.append("Transfer window")
	if labels.is_empty(): labels.append("Open day: rest, train, or street brawl")
	return " • ".join(labels)

func _day_marker(entry: Dictionary, next_match: Dictionary) -> String:
	if int(entry["season_day"]) == int(next_match.get("season_day", -1)):
		return "MATCH\nvs %s" % str(next_match.get("enemy_team", "Rival"))
	for event in entry.get("events", []):
		match str(event.get("type", "")):
			"club_match": return "MATCH\nvs %s" % str(event.get("opponent", "Rival"))
			"championship_semifinals": return "SEMIFINAL"
			"championship_final": return "FINAL"
			"national_window": return "NATIONAL"
			"club_friendly": return "FRIENDLY"
	if entry.get("transfer_window", false): return "TRANSFER"
	return ""

func _cell_style(day: int, marker: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(4)
	style.set_border_width_all(1)
	style.bg_color = Color(0.10, 0.14, 0.20)
	style.border_color = Color(0.22, 0.29, 0.39)
	if marker.begins_with("MATCH") or marker in ["SEMIFINAL", "FINAL"]:
		style.bg_color = Color(0.24, 0.16, 0.08)
		style.border_color = Color(0.67, 0.42, 0.17)
	elif marker == "NATIONAL": style.bg_color = Color(0.18, 0.12, 0.27)
	elif marker == "FRIENDLY": style.bg_color = Color(0.08, 0.22, 0.23)
	if day < campaign_manager.get_season_day(): style.bg_color = style.bg_color.darkened(0.45)
	if day == campaign_manager.get_season_day():
		style.border_color = Color(0.95, 0.82, 0.38)
		style.set_border_width_all(2)
	if day == _selected_day:
		style.border_color = Color(0.95, 0.95, 0.97)
		style.set_border_width_all(2)
	return style

func _refresh() -> void:
	if campaign_manager == null or _rows == null: return
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_day_nodes.clear()
	var next_match: Dictionary = campaign_manager.get_next_scheduled_match()
	var countdown: int = campaign_manager.get_days_until_next_match()
	_status.text = "Today: day %d/224 • Energy %d/100 • %s" % [campaign_manager.get_season_day(), campaign_manager.energy,
		"Next match in %d day(s)" % countdown if countdown >= 0 else "No upcoming club match"]
	var days: Array = campaign_manager.get_calendar_days()
	var month_key := ""
	var grid: GridContainer
	for entry in days:
		var key = "%d-%02d" % [int(entry["year"]), int(entry["month_number"])]
		if key != month_key:
			month_key = key
			var section := VBoxContainer.new()
			section.add_theme_constant_override("separation", 5)
			_rows.add_child(section)
			var heading := Label.new()
			heading.text = "%s %d" % [MONTHS[int(entry["month_number"]) - 1], int(entry["year"])]
			if _get_cinzel():
				heading.add_theme_font_override("font", _get_cinzel())
			heading.add_theme_font_size_override("font_size", 15)
			heading.add_theme_color_override("font_color", UITheme.GOLD_PRIMARY)
			section.add_child(heading)
			grid = GridContainer.new()
			grid.columns = 7
			grid.add_theme_constant_override("h_separation", 5)
			grid.add_theme_constant_override("v_separation", 5)
			section.add_child(grid)
			for weekday in WEEKDAYS:
				var column := Label.new()
				column.text = weekday
				column.custom_minimum_size = Vector2(112, 20)
				column.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				column.add_theme_font_size_override("font_size", 10)
				grid.add_child(column)
			# Godot numbers weekdays Sunday=0; display Monday first.
			for _blank in range((int(entry["weekday"]) + 6) % 7):
				var spacer := Control.new()
				spacer.custom_minimum_size = Vector2(112, 60)
				grid.add_child(spacer)
		var day: int = int(entry["season_day"])
		var marker := _day_marker(entry, next_match)
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(112, 60)
		cell.text = "%d\n%s" % [int(entry["day_of_month"]), marker]
		cell.tooltip_text = "%s • %s" % [entry["date_label"], _entry_text(entry)]
		cell.clip_text = true
		cell.alignment = HORIZONTAL_ALIGNMENT_LEFT
		cell.add_theme_font_size_override("font_size", 10)
		cell.add_theme_stylebox_override("normal", _cell_style(day, marker))
		cell.pressed.connect(_select_day.bind(day))
		grid.add_child(cell)
		_day_nodes[day] = cell
	_update_selection(days, next_match)

func _update_selection(days: Array, next_match: Dictionary) -> void:
	var index = _selected_day - 1
	if index < 0 or index >= days.size(): return
	var entry: Dictionary = days[index]
	var friendly: Dictionary = campaign_manager.get_optional_friendly_on_day(_selected_day)
	var detail_text = _entry_text(entry)
	if _selected_day == int(next_match.get("season_day", -1)):
		detail_text = "%s vs %s" % ["National Cup" if campaign_manager.league_tier == 3 and campaign_manager.season_phase == "club_final" else "Club match", next_match.get("enemy_team", "Rival")]
	elif not friendly.is_empty(): detail_text = "Optional club friendly vs %s" % friendly["enemy_team"]
	_detail.text = "%s • %s" % [entry["date_label"], detail_text]
	_play_button.visible = _selected_day == campaign_manager.get_season_day() and (campaign_manager.can_play_next_match() or not friendly.is_empty())
	_play_button.text = "Play Match" if campaign_manager.can_play_next_match() else "Play Friendly"
	_skip_button.disabled = next_match.is_empty() or not next_match.has("season_day")
	_skip_button.text = "Confirm Skip" if _skip_armed else "Skip Match"
	if _skip_armed:
		_skip_button.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
		_skip_button.add_theme_color_override("font_hover_color", Color(1.0, 0.65, 0.6))
	else:
		_skip_button.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
		_skip_button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))

func _scroll_to_day(day: int) -> void:
	if _scroll and _day_nodes.has(day): _scroll.ensure_control_visible(_day_nodes[day])

func _select_day(day: int) -> void:
	_selected_day = day
	_skip_armed = false
	_refresh()
	call_deferred("_scroll_to_day", day)

func _report(message: String) -> void:
	_feedback.text = message
	state_changed.emit(message)

func _advance(days: int) -> void:
	_skip_armed = false
	var result: Dictionary = campaign_manager.advance_days(days)
	_report("Advanced %d day(s)." % days if result.get("success", false) else result.get("reason", "Could not advance."))
	_selected_day = campaign_manager.get_season_day()
	_refresh()
	call_deferred("_scroll_to_day", _selected_day)

func _rest(days: int) -> void:
	_skip_armed = false
	var result: Dictionary = campaign_manager.rest_for_days(days)
	_report("Rested %d day(s); Energy %d/100." % [days, campaign_manager.energy] if result.get("success", false) else result.get("reason", "Could not rest."))
	_selected_day = campaign_manager.get_season_day()
	_refresh()
	call_deferred("_scroll_to_day", _selected_day)

func _jump_to_match_day() -> void:
	_skip_armed = false
	var next_match: Dictionary = campaign_manager.get_next_scheduled_match()
	if next_match.is_empty() or not next_match.has("season_day"):
		_report("No scheduled club match to jump to.")
		return
	var days_until: int = campaign_manager.get_days_until_next_match()
	if days_until > 0:
		var result: Dictionary = campaign_manager.advance_days(days_until)
		_report("Advanced to match day against %s." % next_match.get("enemy_team", "Rival") if result.get("success", false) else result.get("reason", "Could not jump to match day."))
	_selected_day = int(next_match["season_day"])
	_refresh()
	call_deferred("_scroll_to_day", _selected_day)

func _confirm_skip() -> void:
	if not _skip_armed:
		_skip_armed = true
		_skip_button.text = "Confirm Skip"
		_report("Press Confirm Skip to simulate the next match without XP or rewards.")
		return
	_skip_armed = false
	var result: Dictionary = campaign_manager.skip_next_match()
	_report("Skipped vs %s • Simulated %s." % [result.get("opponent", "Rival"), "win" if result.get("won", false) else "loss"] if result.get("success", false) else result.get("reason", "Could not skip."))
	_selected_day = campaign_manager.get_season_day()
	_refresh()
	call_deferred("_scroll_to_day", _selected_day)

func _play_selected() -> void:
	if _selected_day != campaign_manager.get_season_day(): return
	var friendly: Dictionary = campaign_manager.get_optional_friendly_on_day(_selected_day)
	hide()
	if campaign_manager.can_play_next_match(): play_requested.emit()
	elif not friendly.is_empty(): friendly_requested.emit(friendly)
