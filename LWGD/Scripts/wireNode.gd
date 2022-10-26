extends Control
onready var workspace = get_parent()
export var col: NodePath

var connections = []

func _ready():

	#$Area2D.connect("input_event", self, "line_input")
	#var ln = AntialiasedLine2D.new()
	#ln.points = [(connections[0].get("coords") * workspace.zoomlevel) + workspace.pan,(connections[1].get("coords") * workspace.zoomlevel) + workspace.pan]
	#self.add_child(ln)
	pass
func delete():
	for n in range(connections.size()-1,-1,-1):
		var conn = connections[n]
		conn.attachedWires.remove(conn.attachedWires.find(self))
	
func _draw():
	if connections.size() >= 2:
		draw_line((connections[0].get("coords") * workspace.zoomlevel) + workspace.pan, (connections[1].get("coords") * workspace.zoomlevel) + workspace.pan, Color(255, 0, 0), 10*workspace.zoomlevel)

func line_input(viewport, event, shape_idx):
	print("i")
