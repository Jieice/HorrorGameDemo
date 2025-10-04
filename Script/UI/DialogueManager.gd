extends Node

## 对话管理器
## 统一管理对话系统的显示和隐藏
## 作者：AI Assistant
## 日期：2025-10-04

var dialogue_box_scene = preload("res://Scene/DialogueBox.tscn")
var current_dialogue_box: CanvasLayer = null

func _ready():
	print("[DialogueManager] 对话管理器已初始化")

## 显示文本（心理独白或一般文字显示）
func show_text(text: String, is_monologue: bool = true):
	# 如果已有对话框，先关闭
	if current_dialogue_box:
		current_dialogue_box.queue_free()

	# 创建新的对话框
	current_dialogue_box = dialogue_box_scene.instantiate()
	get_tree().current_scene.add_child(current_dialogue_box)

	# 根据类型显示内容
	if is_monologue:
		if current_dialogue_box.has_method("show_monologue"):
			current_dialogue_box.show_monologue(text)
	else:
		# 如果是普通文本，也可以显示为独白形式
		if current_dialogue_box.has_method("show_monologue"):
			current_dialogue_box.show_monologue(text)

	# 连接关闭信号
	if current_dialogue_box.has_signal("dialogue_closed"):
		current_dialogue_box.dialogue_closed.connect(_on_dialogue_closed)

## 显示心理独白（别名方法）
func show_monologue(text: String):
	show_text(text, true)

## 显示NPC对话
func show_dialogue(npc_name: String, text: String, choices: Array = []):
	# 如果已有对话框，先关闭
	if current_dialogue_box:
		current_dialogue_box.queue_free()

	# 创建新的对话框
	current_dialogue_box = dialogue_box_scene.instantiate()
	get_tree().current_scene.add_child(current_dialogue_box)

	# 显示对话
	if current_dialogue_box.has_method("show_dialogue"):
		current_dialogue_box.show_dialogue(npc_name, text, choices)

	# 连接关闭信号
	if current_dialogue_box.has_signal("dialogue_closed"):
		current_dialogue_box.dialogue_closed.connect(_on_dialogue_closed)

## 关闭当前对话
func close_dialogue():
	if current_dialogue_box:
		current_dialogue_box.queue_free()
		current_dialogue_box = null

## 对话关闭回调
func _on_dialogue_closed():
	current_dialogue_box = null

## 检查是否有对话正在显示
func is_dialogue_active() -> bool:
	return current_dialogue_box != null
