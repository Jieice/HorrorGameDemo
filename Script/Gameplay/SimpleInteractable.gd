extends StaticBody3D
class_name SimpleInteractable

## 简单互动物品基类
## 适用于一次性互动的环境物品
## 作者：AI Assistant
## 日期：2025-10-04

# 导出变量（在编辑器中可配置）
@export var interact_hint := "按 [E] 调查"
@export_multiline var dialogue_text := "这是一个可互动的物品。"
@export var heart_rate_increase := 5.0
@export var trigger_env_progress := false
@export var play_sfx := ""
@export var trigger_light_event := "" # "flicker", "dim", etc.
@export var one_time_only := true

var has_interacted := false
var interactable := true

func _ready():
	add_to_group("Interactable")

func interact():
	if one_time_only and has_interacted:
		return
	
	if not interactable:
		return
	
	has_interacted = true
	
	print("[SimpleInteractable] 玩家互动：", name)
	
	# 显示独白/对话
	if dialogue_text:
		var dialogue_mgr = get_node_or_null("/root/DialogueManager")
		if dialogue_mgr:
			dialogue_mgr.show_text(dialogue_text)
	
	# 心率增加
	if heart_rate_increase > 0:
		var heart_rate_sys = get_node_or_null("/root/HeartRateSystem")
		if heart_rate_sys:
			heart_rate_sys.increase_heart_rate(heart_rate_increase)
	
	# 环境进度
	if trigger_env_progress:
		var env_sys = get_node_or_null("/root/EnvironmentProgressSystem")
		if env_sys:
			env_sys.on_item_investigated()
	
	# 音效
	if play_sfx:
		var audio_mgr = get_node_or_null("/root/AudioManager")
		if audio_mgr:
			audio_mgr.play_sfx(play_sfx, -5.0)
	
	# 灯光事件
	if trigger_light_event:
		var lighting = get_node_or_null("/root/LightingController")
		if lighting:
			lighting.trigger_event(trigger_light_event, 0.3)
	
	# 调用自定义效果（子类可重写）
	_on_interacted()

# 子类可重写此方法添加自定义效果
func _on_interacted():
	pass
