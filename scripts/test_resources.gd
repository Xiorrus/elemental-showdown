extends SceneTree

var failures := 0

func _init():
	_run.call_deferred()

func check(condition: bool, label: String):
	if condition:
		print("[PASS] " + label)
	else:
		failures += 1
		printerr("[FAIL] " + label)

func _run():
	for file in DirAccess.get_files_at("res://scenes"):
		if file.ends_with(".tscn"):
			check(load("res://scenes/" + file) is PackedScene, "Scene and dependencies load: " + file)
	for file in DirAccess.get_files_at("res://scripts"):
		if file.ends_with(".gd") and not file.begins_with("test_"):
			var script = load("res://scripts/" + file)
			check(script is GDScript and script.can_instantiate(), "Script parses: " + file)
	for fighter in ["player", "enemy", "fire", "water", "earth", "air", "zero"]:
		for animation in ["walk", "attack"]:
			var path = "res://assets/%s_%s.png" % [fighter, animation]
			var sheet: Texture2D = load(path)
			var valid = sheet != null and sheet.get_width() == 512 and sheet.get_height() == 512
			if valid:
				var pixels = sheet.get_image()
				for row in range(4):
					for column in range(4):
						var frame = pixels.get_region(Rect2i(column * 128, row * 128, 128, 128))
						var used = frame.get_used_rect()
						# Transparent margins prevent bleed from neighbouring frames.
						valid = valid and used.has_area() and used.position.x > 0 and used.position.y > 0 and used.end.x < 128 and used.end.y < 128
			check(valid, "Complete 4-direction sprite sheet with safe frame margins: %s/%s" % [fighter, animation])
	quit(0 if failures == 0 else 1)
