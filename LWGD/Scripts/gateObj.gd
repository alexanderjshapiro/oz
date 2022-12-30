extends TextureRect
var coords: Vector2 #the position of the object in a virtual 'project' plane
onready var workspace = get_parent()
var attachedWires = []

export (Array, Vector2) var wire_connector_pos = []

enum gateTypes {AND, HIGH, LOW}
export(gateTypes) var gateType

func setType(type):
	gateType = type
	
func _ready():
	match gateType:
		gateTypes.AND:
			wire_connector_pos = [Vector2(23,14),Vector2(23,48),Vector2(190,32)]
			self.texture = load("res://logic_gate_svg/and.svg")
		gateTypes.HIGH:
			self.texture = load("icon.png")
			wire_connector_pos = [Vector2(10,10)]
var recentClickedConnector: int
func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.is_pressed():
		var mouse_pos = get_viewport().get_mouse_position()-self.rect_global_position
		var closest_conn
		var closest_conn_dist = INF
		for conn in len(wire_connector_pos):
			if mouse_pos.distance_squared_to(wire_connector_pos[conn]) < closest_conn_dist:
				closest_conn_dist = mouse_pos.distance_squared_to(wire_connector_pos[conn])
				closest_conn = conn
		recentClickedConnector = closest_conn

func addWire(wire):
	attachedWires.append(wire)

func delete():
	print("dell")
	for n in range(attachedWires.size()-1,-1,-1):
		var wire = attachedWires[n]
		workspace.electricalNodes.remove(workspace.electricalNodes.find(wire))
		wire.delete()
		wire.queue_free()
	workspace.objects.remove(workspace.objects.find(self))
	queue_free()

func update():
	
	pass
