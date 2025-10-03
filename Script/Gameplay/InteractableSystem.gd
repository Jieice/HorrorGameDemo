extends Node

# 简化的全局互动系统
# 使用全局组管理所有可互动对象

class_name InteractableSystem

# 全局互动组名称
const INTERACTABLE_GROUP = "interactable"

# 信号：当玩家可以互动时
signal can_interact(object: Node, prompt: String)
signal cannot_interact()

var current_interactable: Node = null
var interaction_prompt: String = ""

func _ready():
	# 添加到全局组
	add_to_group("InteractableSystem")

# 注册可互动对象
func register_interactable(object: Node, prompt: String = "按E键互动") -> void:
	object.add_to_group(INTERACTABLE_GROUP)
	object.set_meta("interaction_prompt", prompt)
	print("已注册可互动对象: ", object.name, " - 提示: ", prompt)

# 取消注册可互动对象
func unregister_interactable(object: Node) -> void:
	if object.is_in_group(INTERACTABLE_GROUP):
		object.remove_from_group(INTERACTABLE_GROUP)
		if object.has_meta("interaction_prompt"):
			object.remove_meta("interaction_prompt")

# 检查射线碰撞并更新互动状态
func check_interaction(ray: RayCast3D) -> void:
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider and collider.is_in_group(INTERACTABLE_GROUP):
			current_interactable = collider
			interaction_prompt = collider.get_meta("interaction_prompt", "按E键互动")
			can_interact.emit(collider, interaction_prompt)
		else:
			current_interactable = null
			cannot_interact.emit()
	else:
		current_interactable = null
		cannot_interact.emit()

# 执行互动
func perform_interaction() -> void:
	if current_interactable and current_interactable.has_method("interact"):
		current_interactable.interact()
		print("执行互动: ", current_interactable.name)

# 获取当前可互动对象
func get_current_interactable() -> Node:
	return current_interactable

# 获取互动提示
func get_interaction_prompt() -> String:
	return interaction_prompt

# 检查是否可以互动
func can_interact_now() -> bool:
	return current_interactable != null