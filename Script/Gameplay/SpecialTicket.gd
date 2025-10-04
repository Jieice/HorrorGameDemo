extends "res://Script/Gameplay/SecondaryInspectable.gd"

## 特殊票据 - 支持二次检查
## 初次检查看到模糊的票据内容
## 二次检查发现票据背面的隐藏信息
## 作者：AI Assistant
## 日期：2025-10-04

func _ready():
	super._ready() # 调用父类ready

	# 配置特殊票据的参数
	first_inspect_text = "这张票据...目的地被水晕开了，看不清楚...但日期似乎是今天。"
	second_inspect_text = "等等！票据背面有东西...用手指轻轻一抹...隐约能看到几行字：'记住，戴上面具才能生存。面具完整度：0%'"
	final_inspect_text = ""

	heart_rate_increase = 15.0
	play_sound = "heartbeat"
	trigger_darkness = true

	max_stages = 2

	print("[SpecialTicket] 特殊票据已准备好，支持二次检查")
