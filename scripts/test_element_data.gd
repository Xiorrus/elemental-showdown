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
	var data = root.get_node("ElementData")
	var campaign = root.get_node("CampaignManager")
	for element in campaign.DEFAULT_ELEMENT_SKILLS:
		var tree_nodes = data.get_skill_tree_nodes(element)
		for starter in campaign.DEFAULT_ELEMENT_SKILLS[element]:
			var matching = tree_nodes.filter(func(node): return node.get("key") == starter)
			check(matching.size() == 1, "%s starter appears once in its skill tree" % starter)
			if matching.size() == 1:
				var node = matching[0]
				check(node.get("tier") == "basic" and node.get("level_req") == 1 and node.get("prerequisites", []).is_empty(),
					"%s starter has no skill-tree unlock gate" % starter)
	for element in ["fire", "water", "earth", "air"]:
		for tier in data.SKILL_LEVEL_REQUIREMENTS:
			var required_level = data.get_skill_level_req(tier)
			var before = data.get_skills_for_level(element, required_level - 1)
			var after = data.get_skills_for_level(element, required_level)
			for key in data.ELEMENTS[element]["skill_pool"]:
				if data.ABILITIES[key]["tier"] == tier:
					check(not before.has(key) and after.has(key), "%s unlocks at configured level %d" % [key, required_level])
	check(data.get_fusion_info("fire", "fire").is_empty(), "Repeated element cannot create a binary fusion")
	check(data.get_triple_fusion("fire", "fire", "water").is_empty(), "Repeated element cannot create a triple fusion")
	for key in data.FUSIONS:
		var fusion = data.FUSIONS[key]
		var elements = fusion["elements"]
		if fusion["tier"] == "double":
			check(data.get_fusion_info(elements[1], elements[0]) == fusion, "Binary fusion order is independent: " + key)
		elif fusion["tier"] == "triple":
			check(data.get_triple_fusion(elements[2], elements[0], elements[1]) == fusion, "Triple fusion order is independent: " + key)
	quit(0 if failures == 0 else 1)
