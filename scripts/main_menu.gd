# main_menu.gd
# Primary entry controller for Elemental Showdown.
# Adheres to strict OOP principles: coordinates menu navigation and connects to SettingsManager.
extends Control

# Navigation Buttons
@onready var btn_new: Button = $MainLayout/NavDeck/BtnNewCampaign
@onready var btn_load: Button = $MainLayout/NavDeck/BtnContinue
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

func _ready():
	_setup_navigation_buttons()
	_setup_settings_modal()
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
	btn_settings.pressed.connect(_on_open_settings)
	btn_exit.pressed.connect(_on_exit_pressed)

func _update_continue_button_state():
	var cm = _get_campaign_manager()
	if cm and cm.has_saved_campaign():
		var file = FileAccess.open(cm.SAVE_PATH, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_str) == OK and json.data is Dictionary and cm._is_save_data_valid(json.data):
				var d = json.data
				var p_name = d.get("player_name", "Brawler")
				var p_lvl = d.get("player_level", 1)
				var p_elem = d.get("player_element", "fire").capitalize()
				btn_load.text = "Continue: %s (Lv. %d %s)" % [p_name.capitalize(), p_lvl, p_elem]
				btn_load.disabled = false
				return
		btn_load.text = "Saved Campaign Unavailable"
		btn_load.tooltip_text = "The save file could not be read. Your existing file has been preserved."
		btn_load.disabled = true
	else:
		btn_load.text = "No Saved Campaign"
		btn_load.disabled = true

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
	if cm and cm.load_campaign():
		get_tree().change_scene_to_file("res://scenes/CampaignHub.tscn")
	else:
		_on_new_campaign()

func _on_exit_pressed():
	get_tree().quit()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and settings_modal.visible:
			_on_close_settings()
			get_viewport().set_input_as_handled()
