extends RefCounted

const OUTPUT_DIR = "res://screenshots/new_ui/"

static func prepare() -> bool:
	# Some capture fixtures call campaign methods that save automatically.
	# The launcher gives Godot a private user-data directory for each run.
	if OS.get_environment("ELEMENTAL_CAPTURE_ISOLATED") != "1":
		printerr("[Capture] Run scripts/run_capture.ps1 so campaign saves stay isolated.")
		return false
	var absolute_dir = ProjectSettings.globalize_path(OUTPUT_DIR)
	var error = DirAccess.make_dir_recursive_absolute(absolute_dir)
	if error != OK:
		printerr("[Capture] Cannot create output directory: ", absolute_dir, " (", error, ")")
		return false
	# Explicit viewport size prevents desktop window chrome from cropping 30 px.
	var tree = Engine.get_main_loop() as SceneTree
	tree.root.size = Vector2i(1920, 1080)
	return true

static func save(viewport: Window, file_name: String) -> bool:
	if file_name != file_name.get_file() or not file_name.ends_with(".png"):
		printerr("[Capture] Invalid screenshot name: ", file_name)
		return false
	var image = viewport.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("[Capture] Could not read viewport for ", file_name)
		return false
	var destination = ProjectSettings.globalize_path(OUTPUT_DIR + file_name)
	var error = image.save_png(destination)
	if error != OK:
		printerr("[Capture] Could not save ", destination, " (", error, ")")
		return false
	print("[Capture] Saved ", destination)
	return true
