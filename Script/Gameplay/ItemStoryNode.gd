extends Interactable

@export var story_node_id: String = ""

func _ready():
	add_to_group("Interactable")

func interact():
	if not interactable:
		return
	var story_manager = get_node_or_null("/root/StoryManager")
	if story_manager and story_manager.current_node and story_manager.current_node["id"] == story_node_id:
		story_manager.on_item_interact(story_node_id)
