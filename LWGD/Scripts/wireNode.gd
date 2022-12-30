extends Control
onready var workspace = get_parent()
export var col: NodePath

var linkedNodes = []
var nodePortIDs = []

func _ready():
	pass
func delete():
	for n in range(linkedNodes.size()-1,-1,-1):
		var conn = linkedNodes[n]
		conn.attachedWires.remove(conn.attachedWires.find(self))
	
func _draw():
	if linkedNodes.size() >= 2:
		draw_line(((linkedNodes[0].get("coords")+linkedNodes[0].get("wire_connector_pos")[nodePortIDs[0]])
		 * workspace.zoomlevel) + workspace.pan, ((linkedNodes[1].get("coords")+linkedNodes[1].get("wire_connector_pos")[nodePortIDs[1]]) * workspace.zoomlevel) + workspace.pan,
		 Color(255, 0, 0), 10*workspace.zoomlevel)
