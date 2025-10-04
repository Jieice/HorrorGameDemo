extends Node3D
class_name Interactable
@export var interactable: bool = true
@export var interact_hint: String = "按E互动"

func interact():
	print("被互动对象：", self.name)
