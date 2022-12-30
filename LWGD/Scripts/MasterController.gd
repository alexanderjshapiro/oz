extends Control

#onready var vw = $"VBoxContainer/Main Area/HSplitContainer/VBoxContainer/ColorRect/ViewportContainer/Viewport/ViewWindow"

func _ready():
	pass


#func _on_Tool_1_toggled(button_pressed):
	#vw.get_child(0)
	#vw.get_node("Cube").visib		print (closest_conn)le = !button_pressed


func _on_Save_pressed():
	$"SaveMenuPopup/SaveMenu".popup()


func _on_SaveMenu_file_selected(path):
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_string("Circuit Information Goes here")
	file.close()
