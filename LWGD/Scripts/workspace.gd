extends Panel

export var zoomSensitivity: float = 0.1

var zoomlevel = 1
var pan = Vector2(0,0)
var objects = []
var electricalNodes = []
var wirePrefab = preload("res://wireNode.tscn")

enum STATE {DEFAULT, WIRE, DELETE}
var currentMode = STATE.DEFAULT

func _ready():
	self.connect("gui_input", self, "workspace_gui_input")

func _input(event):
			#draw_line(Vect		#draw_line(Vector2((linked[0].get("coords")[0] * zoomlevel) + pan[0],(linked[1].get("coords")[1] * zoomlevel) + pan[1]), Vector2((linked[1].get("coords")[0] * zoomlevel) + pan[0],(linked[1].get("coords")[1] * zoomlevel) + pan[1]), Color(255, 0, 0), 1)or2((linked[0].get("coords")[0] * zoomlevel) + pan[0],(linked[1].get("coords")[1] * zoomlevel) + pan[1]), Vector2((linked[1].get("coords")[0] * zoomlevel) + pan[0],(linked[1].get("coords")[1] * zoomlevel) + pan[1]), Color(255, 0, 0), 1)
	if event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_UP:
		zoomlevel += zoomSensitivity
		updateWorkspace()
	elif event is InputEventMouseButton and event.button_index == BUTTON_WHEEL_DOWN:
		zoomlevel = max(zoomlevel - zoomSensitivity, 0.5)
		updateWorkspace()

func updateWorkspace():
	# Sets all objects to the correct position, with pan and zoom.
	for obj in objects:
		obj.rect_scale = Vector2(zoomlevel,zoomlevel)
		obj.rect_position = (obj.get("coords") * zoomlevel) + pan 
	for linked in electricalNodes:
		linked.update()
			
func focusWorkspace():
	var centroid = Vector2(0,0)
	for obj in objects:
		centroid += obj.coords
		centroid /= 2
	print(pan)
	print(centroid)
	pan = (self.rect_size/2) - (centroid*zoomlevel)
	updateWorkspace()

func setMode(mode):
	if mode == "Delete":
		currentMode = STATE.DELETE
	elif mode == "Wire":
		currentMode = STATE.WIRE
		firstlink = null
	elif mode == "Select":
		currentMode = STATE.DEFAULT
	pass

func can_drop_data(_pos, _data):
	# Tells engine if a certain entity can be dropped on workspace
	# TODO acctual checking
	return true#typeof(data) == TYPE_COLOR


func drop_data(pos, _data):
	# Runs when an object is dropped into the workspace window
	# Places the object on the screen in correct position
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var newObject = load("res://GateObj.tscn").instance()
	#newObject.texture = load("res://icon.png")
	#newObject.set_script(load("res://Scripts/object.gd"))
	newObject.coords = (pos-pan)/zoomlevel
	objects.append(newObject)
	newObject.setType(_data)
	updateWorkspace()
	self.add_child(newObject)
	newObject.connect("gui_input", self, "nodeEvent",[newObject])

func nodeEvent(event, node):
	if currentMode == STATE.DELETE and event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		deleteNode(node)
	if currentMode == STATE.DEFAULT and event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		selectNode(node)
	elif currentMode == STATE.WIRE and event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed == true:
		wireNode(node)
	accept_event()

func deleteNode(node):
	node.delete()

var selected
func selectNode(node):
	if selected:
		selected.modulate = Color(1,1,1,1)
	if node != selected:
		node.modulate = Color(1,0,0,1)
		selected = node
	else:
		selected = null
	#node.modulate(Color(255,255,0))

var firstlink
var firstlinkid
func wireNode(node):
	if firstlink == null:
		firstlink = node
		firstlinkid = firstlink.recentClickedConnector
	elif node == firstlink:
		firstlink = null
	else:
		var wiring = wirePrefab.instance()
		electricalNodes.append(wiring)
		wiring.linkedNodes.append(firstlink)
		wiring.linkedNodes.append(node)
		wiring.nodePortIDs.append(firstlinkid)
		wiring.nodePortIDs.append(node.recentClickedConnector)
		firstlink.addWire(wiring)
		node.addWire(wiring)
		firstlink = null
		self.add_child(wiring)
		updateWorkspace()

var panning = false
var mouseOrigin: Vector2
var oldpan: Vector2
func workspace_gui_input(event):  
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		panning = !panning
		mouseOrigin = get_viewport().get_mouse_position()
		oldpan = pan
	if panning:
		pan = (get_viewport().get_mouse_position()-mouseOrigin) + oldpan
		updateWorkspace()
