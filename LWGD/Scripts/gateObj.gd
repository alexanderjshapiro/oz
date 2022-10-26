extends TextureRect
var coords: Vector2 #the position of the object in a virtual 'project' plane
onready var workspace = get_parent()
var attachedWires = []

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

