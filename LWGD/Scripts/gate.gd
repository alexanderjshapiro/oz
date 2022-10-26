extends TextureRect

var dragging = false
export(NodePath) var workspacePath # set in the inspector once
onready var workspace = get_node(workspacePath)#$"/root/Control/VBoxContainer/Main Area/HSplitContainer/VBoxContainer/Workspace"

func _ready():
	pass


func get_drag_data(_pos):
	# Use another colorpicker as drag preview.

	var cpb = TextureRect.new()
	cpb.texture = self.texture
	var zl = workspace.get("zoomlevel")
	cpb.rect_scale = Vector2(zl,zl)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	dragging = true
	#cpb.texture = self.texture
	set_drag_preview(cpb)
	# Return color as drag data.
	return "OR"

func _input(event):
	if dragging && event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and !event.pressed:
			dragging = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
