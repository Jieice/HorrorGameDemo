extends Interactable

## 可二次检查的互动对象
## 支持多次检查，每次检查发现不同内容
## 作者：AI Assistant
## 日期：2025-10-04

# 检查阶段
enum InspectStage {
	FIRST,     # 初次检查
	SECOND,    # 二次检查
	FINAL      # 最终检查（如果有的话）
}

# 当前检查阶段
var current_stage: InspectStage = InspectStage.FIRST
var max_stages: int = 2

# 检查内容配置
@export var first_inspect_text: String = "初次检查的内容"
@export var second_inspect_text: String = "二次检查发现的异常内容"
@export var final_inspect_text: String = ""

# 检查后效果
@export var heart_rate_increase: float = 10.0
@export var play_sound: String = ""
@export var trigger_darkness: bool = false

# 状态
var has_been_inspected: bool = false
var can_inspect_again: bool = false

func _ready():
	print("[SecondaryInspectable] %s 已准备好，支持多次检查" % name)

# 覆盖父类的互动方法
func interact():
	match current_stage:
		InspectStage.FIRST:
			_perform_first_inspect()
		InspectStage.SECOND:
			_perform_second_inspect()
		InspectStage.FINAL:
			_perform_final_inspect()

## 执行初次检查
func _perform_first_inspect():
	print("[SecondaryInspectable] 执行初次检查")

	# 显示初次检查内容
	if DialogueManager:
		DialogueManager.show_text(first_inspect_text)

	# 增加心率
	if HeartRateSystem:
		HeartRateSystem.increase_heart_rate(heart_rate_increase * 0.5)

	# 播放音效
	if play_sound and AudioManager:
		AudioManager.play_sfx(play_sound)

	# 标记已检查过，可以再次检查
	has_been_inspected = true
	can_inspect_again = true

	# 显示再次检查提示
	await get_tree().create_timer(2.0).timeout
	if TaskHintUI:
		TaskHintUI.show_hint("按 [E] 再次检查", 3.0)

## 执行二次检查
func _perform_second_inspect():
	print("[SecondaryInspectable] 执行二次检查")

	# 显示二次检查内容
	if DialogueManager:
		DialogueManager.show_text(second_inspect_text)

	# 大幅增加心率
	if HeartRateSystem:
		HeartRateSystem.increase_heart_rate(heart_rate_increase)

	# 播放音效
	if play_sound and AudioManager:
		AudioManager.play_sfx(play_sound)

	# 触发黑暗事件（如果配置了）
	if trigger_darkness:
		var darkness_mgr = get_node_or_null("/root/DarknessEventManager")
		if darkness_mgr:
			darkness_mgr.trigger_darkness()

	# 推进到下一阶段或结束
	if max_stages > 2:
		current_stage = InspectStage.FINAL
		can_inspect_again = true
		await get_tree().create_timer(2.0).timeout
		if TaskHintUI:
			TaskHintUI.show_hint("按 [E] 最终检查", 3.0)
	else:
		can_inspect_again = false

## 执行最终检查
func _perform_final_inspect():
	print("[SecondaryInspectable] 执行最终检查")

	# 显示最终检查内容
	if DialogueManager:
		DialogueManager.show_text(final_inspect_text)

	# 最大心率增加
	if HeartRateSystem:
		HeartRateSystem.increase_heart_rate(heart_rate_increase * 1.5)

	# 播放音效
	if play_sound and AudioManager:
		AudioManager.play_sfx(play_sound)

	# 结束检查
	can_inspect_again = false

## 重置检查状态（用于测试）
func reset_inspection():
	current_stage = InspectStage.FIRST
	has_been_inspected = false
	can_inspect_again = false
	print("[SecondaryInspectable] 检查状态已重置")
