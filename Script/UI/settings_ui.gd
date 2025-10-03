extends Control

func _on_save_button_pressed():
	print("保存设置")
	hide() # 或 queue_free()，根据你的需求

func _on_cancel_button_pressed():
	print("取消设置")
	hide() # 或 queue_free()，根据你的需求
