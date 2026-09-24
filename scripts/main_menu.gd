# main_menu.gd
# Primary entry controller for Elemental Showdown.
# Adheres to strict OOP principles: coordinates menu navigation and connects to SettingsManager & CampaignManager.
extends Control

const FONT_CINZEL = preload("res://assets/fonts/Cinzel-Bold.ttf")

# Navigation Buttons
@onready var btn_new: Button = $MainLayout/NavDeck/BtnNewCampaign
@onready var btn_load: Button = $MainLayout/NavDeck/BtnContinue
@onready var btn_archives: Button = $MainLayout/NavDeck/BtnSelectCampaign
@onready var btn_settings: Button = $MainLayout/NavDeck/BtnSettings
@onready var btn_exit: Button = $MainLayout/NavDeck/BtnExit

# Settings Modal
@onready var settings_modal: Control = $SettingsModal
@onready var btn_tab_audio: Button = $SettingsModal/DialogPanel/Margin/VBox/TabSelect/BtnTabAudio
@onready var btn_tab_display: Button = $SettingsModal/DialogPanel/Margin/VBox/TabSelect/BtnTabDisplay
@onready var audio_section: VBoxContainer = $SettingsModal/DialogPanel/Margin/VBox/AudioSection
@onready var display_section: VBoxContainer = $SettingsModal/DialogPanel/Margin/VBox/DisplaySection

# Audio Sliders & Labels
@onready var slider_master: HSlider = $SettingsModal/DialogPanel/Margin/VBox/AudioSection/MasterRow/SliderMaster
@onready var lbl_val_master: Label = $SettingsModal/DialogPanel/Margin/VBox/AudioSection/MasterRow/ValMaster
@onready var slider_music: HSlider = $SettingsModal/DialogPanel/Margin/VBox/AudioSection/MusicRow/SliderMusic
@onready var lbl_val_music: Label = $SettingsModal/DialogPanel/Margin/VBox/AudioSection/MusicRow/ValMusic
@onready var slider_sfx: HSlider = $SettingsModal/DialogPanel/Margin/VBox/AudioSection/SfxRow/SliderSfx
@onready var lbl_val_sfx: Label = $SettingsModal/DialogPanel/Margin/VBox/AudioSection/SfxRow/ValSfx

# Display & Action Buttons
@onready var btn_window_mode: Button = $SettingsModal/DialogPanel/Margin/VBox/DisplaySection/DisplayModeRow/BtnWindowMode
@onready var btn_reset_defaults: Button = $SettingsModal/DialogPanel/Margin/VBox/ButtonRow/BtnResetDefaults
@onready var btn_close_settings: Button = $SettingsModal/DialogPanel/Margin/VBox/ButtonRow/BtnCloseSettings

# Campaigns Archive Modal
@onready var campaigns_modal: Control = $CampaignsModal
@onready var cards_container: VBoxContainer = $CampaignsModal/DialogPanel/Margin/VBox/ScrollContainer/CardsContainer
@onready var empty_label: Label = $CampaignsModal/DialogPanel/Margin/VBox/ScrollContainer/CardsContainer/EmptyLabel
@onready var btn_modal_new: Button = $CampaignsModal/DialogPanel/Margin/VBox/BottomRow/BtnModalNew
@onready var btn_modal_close: Button = $CampaignsModal/DialogPanel/Margin/VBox/BottomRow/BtnModalClose

func _ready():
	_setup_navigation_buttons()
	_setup_settings_modal()
	_setup_campaigns_modal()
	_update_continue_button_state()

func _get_settings_manager() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("SettingsManager")
	return null

func _get_campaign_manager() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("CampaignManager")
	return null

func _setup_navigation_buttons():
	btn_new.pressed.connect(_on_new_campaign)
	btn_load.pressed.connect(_on_continue_campaign)
	btn_archives.pressed.connect(_on_open_campaigns_modal)
	btn_settings.pressed.connect(_on_open_settings)
	btn_exit.pressed.connect(_on_exit_pressed)

func _update_continue_button_state():
	var cm = _get_campaign_manager()
	if not cm:
		btn_load.text = "No Saved Campaign"
		btn_load.disabled = true
		return

	var latest_path = cm.get_latest_save_path()
	if not latest_path.is_empty() and FileAccess.file_exists(latest_path):
		var header = cm._read_campaign_header(latest_path)
		if not header.is_empty():
			var p_name = header.get("player_name", "Brawler")
			var p_lvl = header.get("player_level", 1)
			var p_elem = header.get("player_element", "fire").capitalize()
			btn_load.text = "Continue: %s (Lv. %d %s)" % [p_name.capitalize(), p_lvl, p_elem]
			btn_load.disabled = false
			return
		btn_load.text = "Saved Campaign Unavailable"
		btn_load.tooltip_text = "The save file could not be read. Your existing file has been preserved."
		btn_load.disabled = true
	else:
		btn_load.text = "No Saved Campaign"
		btn_load.disabled = true

func _setup_campaigns_modal():
	btn_modal_new.pressed.connect(_on_new_campaign)
	btn_modal_close.pressed.connect(_on_close_campaigns_modal)

func _on_open_campaigns_modal():
	_refresh_campaign_list()
	campaigns_modal.visible = true

func _on_close_campaigns_modal():
	campaigns_modal.visible = false
	_update_continue_button_state()

func _refresh_campaign_list():
	for child in cards_container.get_children():
		if child != empty_label:
			child.queue_free()

	var cm = _get_campaign_manager()
	if not cm:
		empty_label.visible = true
		return

	var saves: Array[Dictionary] = cm.get_saved_campaigns()
	if saves.is_empty():
		empty_label.visible = true
		return

	empty_label.visible = false

	for save in saves:
		var card = _create_campaign_card(save)
		cards_container.add_child(card)

func _create_campaign_card(save: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.07, 0.09, 0.14, 0.95)
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.25, 0.33, 0.46, 0.8)
	card_style.corner_radius_top_left = 6
	card_style.corner_radius_top_right = 6
	card_style.corner_radius_bottom_right = 6
	card_style.corner_radius_bottom_left = 6
	card_style.content_margin_left = 16
	card_style.content_margin_top = 12
	card_style.content_margin_right = 16
	card_style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	card.add_child(hbox)

	# Left Column: Info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	# Top row: Name, Element Pill, Level & Archetype
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	info_vbox.add_child(title_row)

	var name_lbl = Label.new()
	name_lbl.text = save.get("player_name", "Brawler").capitalize()
	name_lbl.add_theme_font_override("font", FONT_CINZEL)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title_row.add_child(name_lbl)

	# Element Badge
	var elem = str(save.get("player_element", "fire")).to_lower()
	var badge = PanelContainer.new()
	var b_style = StyleBoxFlat.new()
	b_style.corner_radius_top_left = 3
	b_style.corner_radius_top_right = 3
	b_style.corner_radius_bottom_right = 3
	b_style.corner_radius_bottom_left = 3
	b_style.content_margin_left = 6
	b_style.content_margin_top = 2
	b_style.content_margin_right = 6
	b_style.content_margin_bottom = 2
	b_style.border_width_left = 1
	b_style.border_width_top = 1
	b_style.border_width_right = 1
	b_style.border_width_bottom = 1

	var elem_color = Color(0.9, 0.4, 0.2)
	match elem:
		"water":
			b_style.bg_color = Color(0.08, 0.18, 0.32, 0.9)
			b_style.border_color = Color(0.2, 0.6, 0.9, 0.9)
			elem_color = Color(0.6, 0.85, 1.0)
		"earth":
			b_style.bg_color = Color(0.14, 0.22, 0.10, 0.9)
			b_style.border_color = Color(0.4, 0.75, 0.3, 0.9)
			elem_color = Color(0.75, 0.95, 0.6)
		"air":
			b_style.bg_color = Color(0.10, 0.22, 0.28, 0.9)
			b_style.border_color = Color(0.4, 0.85, 0.85, 0.9)
			elem_color = Color(0.7, 0.95, 0.95)
		_:
			b_style.bg_color = Color(0.32, 0.10, 0.08, 0.9)
			b_style.border_color = Color(0.9, 0.4, 0.2, 0.9)
			elem_color = Color(1.0, 0.75, 0.5)

	badge.add_theme_stylebox_override("panel", b_style)
	var badge_lbl = Label.new()
	badge_lbl.text = elem.to_upper()
	badge_lbl.add_theme_font_override("font", FONT_CINZEL)
	badge_lbl.add_theme_font_size_override("font_size", 10)
	badge_lbl.add_theme_color_override("font_color", elem_color)
	badge.add_child(badge_lbl)
	title_row.add_child(badge)

	var class_lbl = Label.new()
	class_lbl.text = "Lv. %d  •  %s" % [save.get("player_level", 1), save.get("archetype", "Striker")]
	class_lbl.add_theme_font_size_override("font_size", 12)
	class_lbl.add_theme_color_override("font_color", Color(0.85, 0.90, 0.96, 0.9))
	title_row.add_child(class_lbl)

	if save.get("is_legacy", false):
		var leg_lbl = Label.new()
		leg_lbl.text = "[LEGACY SAVE]"
		leg_lbl.add_theme_font_size_override("font_size", 10)
		leg_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4, 0.8))
		title_row.add_child(leg_lbl)

	# Subtitle row: Team, League Tier, Campaign Day
	var sub_lbl = Label.new()
	var team_txt = save.get("team_name", "Solo")
	if team_txt.is_empty() or team_txt.to_lower() == "solo":
		team_txt = "Street Circuit (Solo)"
	var tier_num = save.get("league_tier", 1)
	var day_num = save.get("campaign_day", 1)
	var s_num = save.get("season_number", 1)
	var w_num = save.get("season_week", 0)
	sub_lbl.text = "Team: %s  •  Tier %d  •  Day %d (Season %d, Wk %d)" % [team_txt, tier_num, day_num, s_num, w_num]
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.85, 0.85))
	info_vbox.add_child(sub_lbl)

	# Detail row: Win/Loss, Gold, Shards, Last Saved
	var det_lbl = Label.new()
	var wins = save.get("total_wins", 0)
	var losses = save.get("total_losses", 0)
	var gold = save.get("gold", 0)
	var shards = save.get("shards", 0)
	var mod_str = save.get("modified_str", "")
	det_lbl.text = "Record: %dW - %dL  •  Gold: %d  •  Shards: %d  •  Saved: %s" % [wins, losses, gold, shards, mod_str]
	det_lbl.add_theme_font_size_override("font_size", 11)
	det_lbl.add_theme_color_override("font_color", Color(0.52, 0.60, 0.72, 0.8))
	info_vbox.add_child(det_lbl)

	# Right Column: Actions
	var action_vbox = VBoxContainer.new()
	action_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(action_vbox)

	var btn_resume = Button.new()
	btn_resume.custom_minimum_size = Vector2(110, 32)
	btn_resume.text = "Resume"
	btn_resume.add_theme_font_override("font", FONT_CINZEL)
	btn_resume.add_theme_font_size_override("font_size", 11)
	var res_normal = StyleBoxFlat.new()
	res_normal.bg_color = Color(0.85, 0.68, 0.22, 1)
	res_normal.border_width_left = 1
	res_normal.border_width_top = 1
	res_normal.border_width_right = 1
	res_normal.border_width_bottom = 1
	res_normal.border_color = Color(1, 0.88, 0.45, 0.9)
	res_normal.corner_radius_top_left = 4
	res_normal.corner_radius_top_right = 4
	res_normal.corner_radius_bottom_right = 4
	res_normal.corner_radius_bottom_left = 4
	btn_resume.add_theme_stylebox_override("normal", res_normal)
	btn_resume.add_theme_color_override("font_color", Color(0.08, 0.07, 0.05, 1))
	btn_resume.add_theme_color_override("font_hover_color", Color(0.08, 0.07, 0.05, 1))

	var save_path = save.get("path", "")
	btn_resume.pressed.connect(func():
		var cm = _get_campaign_manager()
		if cm and cm.load_campaign(save_path):
			get_tree().change_scene_to_file("res://scenes/CampaignHub.tscn")
	)
	action_vbox.add_child(btn_resume)

	# Delete Row (with confirmation state)
	var del_row = HBoxContainer.new()
	del_row.add_theme_constant_override("separation", 4)
	del_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_vbox.add_child(del_row)

	var btn_del = Button.new()
	btn_del.custom_minimum_size = Vector2(110, 24)
	btn_del.text = "Delete"
	btn_del.add_theme_font_override("font", FONT_CINZEL)
	btn_del.add_theme_font_size_override("font_size", 10)
	var del_normal = StyleBoxFlat.new()
	del_normal.bg_color = Color(0.12, 0.08, 0.08, 0.6)
	del_normal.border_width_left = 1
	del_normal.border_width_top = 1
	del_normal.border_width_right = 1
	del_normal.border_width_bottom = 1
	del_normal.border_color = Color(0.50, 0.22, 0.22, 0.6)
	del_normal.corner_radius_top_left = 3
	del_normal.corner_radius_top_right = 3
	del_normal.corner_radius_bottom_right = 3
	del_normal.corner_radius_bottom_left = 3
	btn_del.add_theme_stylebox_override("normal", del_normal)
	btn_del.add_theme_color_override("font_color", Color(0.85, 0.50, 0.50, 0.9))
	btn_del.add_theme_color_override("font_hover_color", Color(1.0, 0.35, 0.35, 1.0))
	del_row.add_child(btn_del)

	var btn_confirm = Button.new()
	btn_confirm.visible = false
	btn_confirm.custom_minimum_size = Vector2(65, 24)
	btn_confirm.text = "Confirm"
	btn_confirm.add_theme_font_override("font", FONT_CINZEL)
	btn_confirm.add_theme_font_size_override("font_size", 10)
	var conf_style = StyleBoxFlat.new()
	conf_style.bg_color = Color(0.65, 0.15, 0.15, 0.95)
	conf_style.corner_radius_top_left = 3
	conf_style.corner_radius_top_right = 3
	conf_style.corner_radius_bottom_right = 3
	conf_style.corner_radius_bottom_left = 3
	btn_confirm.add_theme_stylebox_override("normal", conf_style)
	btn_confirm.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	del_row.add_child(btn_confirm)

	var btn_cancel = Button.new()
	btn_cancel.visible = false
	btn_cancel.custom_minimum_size = Vector2(42, 24)
	btn_cancel.text = "No"
	btn_cancel.add_theme_font_override("font", FONT_CINZEL)
	btn_cancel.add_theme_font_size_override("font_size", 10)
	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = Color(0.15, 0.18, 0.24, 0.8)
	cancel_style.corner_radius_top_left = 3
	cancel_style.corner_radius_top_right = 3
	cancel_style.corner_radius_bottom_right = 3
	cancel_style.corner_radius_bottom_left = 3
	btn_cancel.add_theme_stylebox_override("normal", cancel_style)
	btn_cancel.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.9))
	del_row.add_child(btn_cancel)

	btn_del.pressed.connect(func():
		btn_del.visible = false
		btn_confirm.visible = true
		btn_cancel.visible = true
	)

	btn_cancel.pressed.connect(func():
		btn_del.visible = true
		btn_confirm.visible = false
		btn_cancel.visible = false
	)

	btn_confirm.pressed.connect(func():
		var cm = _get_campaign_manager()
		if cm:
			cm.delete_saved_campaign(save_path)
			_refresh_campaign_list()
			_update_continue_button_state()
	)

	return card

func _setup_settings_modal():
	# Tab switching
	btn_tab_audio.pressed.connect(func(): _switch_settings_tab(true))
	btn_tab_display.pressed.connect(func(): _switch_settings_tab(false))

	# Audio Sliders
	slider_master.value_changed.connect(_on_master_slider_changed)
	slider_music.value_changed.connect(_on_music_slider_changed)
	slider_sfx.value_changed.connect(_on_sfx_slider_changed)

	# Display & Buttons
	btn_window_mode.pressed.connect(_on_window_mode_toggle)
	btn_reset_defaults.pressed.connect(_on_reset_defaults)
	btn_close_settings.pressed.connect(_on_close_settings)

	_sync_settings_from_manager()

func _sync_settings_from_manager():
	var sm = _get_settings_manager()
	if sm:
		slider_master.value = sm.master_volume * 100.0
		lbl_val_master.text = "%d%%" % int(slider_master.value)

		slider_music.value = sm.music_volume * 100.0
		lbl_val_music.text = "%d%%" % int(slider_music.value)

		slider_sfx.value = sm.sfx_volume * 100.0
		lbl_val_sfx.text = "%d%%" % int(slider_sfx.value)

		_update_window_mode_button_text(sm.window_mode)

func _update_window_mode_button_text(mode: int):
	if mode == 1:
		btn_window_mode.text = "Fullscreen"
	else:
		btn_window_mode.text = "Windowed"

func _switch_settings_tab(show_audio: bool):
	audio_section.visible = show_audio
	display_section.visible = !show_audio
	if show_audio:
		btn_tab_audio.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
		btn_tab_display.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	else:
		btn_tab_audio.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
		btn_tab_display.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))

func _on_master_slider_changed(val: float):
	lbl_val_master.text = "%d%%" % int(val)
	var sm = _get_settings_manager()
	if sm:
		sm.master_volume = val / 100.0

func _on_music_slider_changed(val: float):
	lbl_val_music.text = "%d%%" % int(val)
	var sm = _get_settings_manager()
	if sm:
		sm.music_volume = val / 100.0

func _on_sfx_slider_changed(val: float):
	lbl_val_sfx.text = "%d%%" % int(val)
	var sm = _get_settings_manager()
	if sm:
		sm.sfx_volume = val / 100.0

func _on_window_mode_toggle():
	var sm = _get_settings_manager()
	if sm:
		var next_mode = 1 if sm.window_mode == 0 else 0
		sm.window_mode = next_mode
		_update_window_mode_button_text(next_mode)

func _on_reset_defaults():
	var sm = _get_settings_manager()
	if sm:
		sm.reset_to_defaults()
		_sync_settings_from_manager()

func _on_open_settings():
	_sync_settings_from_manager()
	_switch_settings_tab(true)
	settings_modal.visible = true

func _on_close_settings():
	var sm = _get_settings_manager()
	if sm:
		sm.save_settings()
	settings_modal.visible = false

func _on_new_campaign():
	get_tree().change_scene_to_file("res://scenes/CharacterCustomization.tscn")

func _on_continue_campaign():
	var cm = _get_campaign_manager()
	if not cm:
		_on_new_campaign()
		return

	var latest_path = cm.get_latest_save_path()
	if not latest_path.is_empty() and cm.load_campaign(latest_path):
		get_tree().change_scene_to_file("res://scenes/CampaignHub.tscn")
	elif cm.load_campaign():
		get_tree().change_scene_to_file("res://scenes/CampaignHub.tscn")
	else:
		_on_new_campaign()

func _on_exit_pressed():
	get_tree().quit()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if campaigns_modal.visible:
				_on_close_campaigns_modal()
				get_viewport().set_input_as_handled()
			elif settings_modal.visible:
				_on_close_settings()
				get_viewport().set_input_as_handled()

