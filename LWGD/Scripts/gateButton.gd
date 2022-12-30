extends TextureRect

var dragging = false
export(NodePath) var workspacePath # set in the inspector once
onready var workspace = get_node(workspacePath)#$"/root/Control/VBoxContainer/Main Area/HSplitContainer/VBoxContainer/Workspace"
export var dragTexture: Texture
enum gateTypes {AND, HIGH, LOW}
export(gateTypes) var gateType

func get_drag_data(_pos):
	var cpb = TextureRect.new()
	cpb.texture = dragTexture
	var zl = workspace.get("zoomlevel")
	cpb.rect_scale = Vector2(zl,zl)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	dragging = true
	set_drag_preview(cpb)
	return gateType

func _input(event):
	if dragging && event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and !event.pressed:
			dragging = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
