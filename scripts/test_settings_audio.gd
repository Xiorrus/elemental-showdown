extends SceneTree

var failures := 0

func _init():
	_run.call_deferred()

func check(condition: bool, description: String):
	if condition:
		print("[PASS] " + description)
	else:
		failures += 1
		printerr("[FAIL] " + description)

func _run():
	if not OS.get_user_data_dir().replace("\\", "/").contains(".godot/audit"):
		printerr("Use scripts/run_tests.ps1 to isolate settings and save files.")
		quit(1)
		return
	var settings = root.get_node("SettingsManager")
	var config := ConfigFile.new()
	config.set_value("Audio", "master_volume", "broken")
	config.set_value("Audio", "music_volume", -2.0)
	config.set_value("Audio", "sfx_volume", 3.0)
	config.set_value("Display", "window_mode", [])
	config.set_value("Display", "vsync_enabled", "false")
	check(config.save(settings.SETTINGS_FILE_PATH) == OK, "Malformed settings fixture saved")
	settings.load_settings()
	check(is_equal_approx(settings.master_volume, 0.8), "Invalid volume type falls back safely")
	check(settings.music_volume == 0.0 and settings.sfx_volume == 1.0, "Volumes stay in range")
	check(settings.window_mode == 0 and settings.vsync_enabled, "Invalid display types fall back safely")
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Zero volume mutes music")
	settings.music_volume = 0.4
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "Raising volume unmutes music")
	config.set_value("Audio", "master_volume", NAN)
	check(is_equal_approx(settings._read_volume(config, "master_volume", 0.8), 0.8), "Non-finite volume falls back safely")
	settings.save_settings()
	settings.music_volume = 0.1
	settings.load_settings()
	check(is_equal_approx(settings.music_volume, 0.4), "Valid settings survive save and reload")

	# Identical combat seeds must produce identical next rolls regardless of
	# whether a sound was first synthesized or played between those rolls.
	var sound = root.get_node("SoundFX")
	seed(92713)
	var expected_roll := randf()
	seed(92713)
	sound._synthesize_waveform("fire")
	sound.play_sfx("hit")
	check(randf() == expected_roll, "Sound generation and playback preserve gameplay RNG")
	for effect in ["hit", "fire", "water", "earth", "air", "plasma", "space", "time", "crit", "block", "heal", "click"]:
		var stream = sound.get_stream(effect)
		check(stream != null and stream.data.size() > 0 and stream.mix_rate == 22050,
			"Valid audio stream: " + effect)
	print("Settings/audio failures: %d" % failures)
	quit(0 if failures == 0 else 1)
