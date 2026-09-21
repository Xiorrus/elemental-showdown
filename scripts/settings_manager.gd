# settings_manager.gd
# Central configuration and settings manager for Elemental Showdown.
# Adheres to strict OOP principles: encapsulates all persistent user preferences,
# applies audio bus gains, manages window display modes, and syncs to user://settings.cfg.
extends Node

signal settings_changed(setting_name: String, new_value)

const SETTINGS_FILE_PATH = "user://settings.cfg"

# Audio Settings (0.0 to 1.0)
var master_volume: float = 0.8:
	set(v):
		master_volume = clamp(v, 0.0, 1.0)
		_apply_audio_volume("Master", master_volume)
		settings_changed.emit("master_volume", master_volume)

var music_volume: float = 0.7:
	set(v):
		music_volume = clamp(v, 0.0, 1.0)
		_apply_audio_volume("Music", music_volume)
		settings_changed.emit("music_volume", music_volume)

var sfx_volume: float = 0.9:
	set(v):
		sfx_volume = clamp(v, 0.0, 1.0)
		_apply_audio_volume("SFX", sfx_volume)
		settings_changed.emit("sfx_volume", sfx_volume)

# Display Settings
# 0 = Windowed, 1 = Exclusive Fullscreen
var window_mode: int = 0:
	set(v):
		window_mode = clampi(v, 0, 1)
		_apply_window_mode(window_mode)
		settings_changed.emit("window_mode", window_mode)

var vsync_enabled: bool = true:
	set(v):
		vsync_enabled = v
		_apply_vsync(vsync_enabled)
		settings_changed.emit("vsync_enabled", vsync_enabled)

func _ready():
	_ensure_audio_buses()
	load_settings()
	apply_all_settings()

func _ensure_audio_buses():
	# Ensure Music and SFX buses exist in AudioServer
	if AudioServer.get_bus_index("Music") == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

func apply_all_settings():
	_apply_audio_volume("Master", master_volume)
	_apply_audio_volume("Music", music_volume)
	_apply_audio_volume("SFX", sfx_volume)
	_apply_window_mode(window_mode)
	_apply_vsync(vsync_enabled)

func _apply_audio_volume(bus_name: String, linear_vol: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		if linear_vol <= 0.005:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_vol))

func _apply_window_mode(mode: int):
	match mode:
		0: # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		1: # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _apply_vsync(enabled: bool):
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("Audio", "master_volume", master_volume)
	config.set_value("Audio", "music_volume", music_volume)
	config.set_value("Audio", "sfx_volume", sfx_volume)
	config.set_value("Display", "window_mode", window_mode)
	config.set_value("Display", "vsync_enabled", vsync_enabled)

	var err = config.save(SETTINGS_FILE_PATH)
	if err == OK:
		print("[SettingsManager] Settings saved to ", SETTINGS_FILE_PATH)
	else:
		printerr("[SettingsManager] Failed to save settings. Error code: ", err)

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE_PATH)
	if err == OK:
		master_volume = config.get_value("Audio", "master_volume", 0.8)
		music_volume = config.get_value("Audio", "music_volume", 0.7)
		sfx_volume = config.get_value("Audio", "sfx_volume", 0.9)
		window_mode = config.get_value("Display", "window_mode", 0)
		vsync_enabled = config.get_value("Display", "vsync_enabled", true)
		print("[SettingsManager] Settings loaded successfully.")
	else:
		print("[SettingsManager] No existing settings file. Using clean defaults.")

func reset_to_defaults():
	master_volume = 0.8
	music_volume = 0.7
	sfx_volume = 0.9
	window_mode = 0
	vsync_enabled = true
	save_settings()
